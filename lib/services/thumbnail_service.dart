import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_model.dart';

/// Service to extract thumbnails from article URLs with persistent caching
class ThumbnailService {
  // In-memory cache for ultra-speed
  static final Map<String, String> _thumbnailCache = {};
  static final Map<String, String> _descriptionCache = {};
  
  static const String _corsProxy = 'https://corsproxy.io/?';
  static SharedPreferences? _prefs;

  /// Initialize the persistent storage
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load existing cache from storage
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith('thumb_')) {
        _thumbnailCache[key.replaceFirst('thumb_', '')] = _prefs!.getString(key) ?? '';
      } else if (key.startsWith('desc_')) {
        _descriptionCache[key.replaceFirst('desc_', '')] = _prefs!.getString(key) ?? '';
      }
    }
  }

  static String? getCachedThumbnail(String articleUrl) {
    return _thumbnailCache[articleUrl];
  }

  static String? getCachedDescription(String articleUrl) {
    return _descriptionCache[articleUrl];
  }

  /// Extract metadata with intelligent caching to save battery and data
  static Future<String> extractThumbnail(String articleUrl) async {
    // 1. Check in-memory
    if (_thumbnailCache.containsKey(articleUrl)) {
      return _thumbnailCache[articleUrl]!;
    }

    try {
      String fetchUrl = articleUrl;
      if (kIsWeb) {
        fetchUrl = '$_corsProxy${Uri.encodeComponent(articleUrl)}';
      }

      // 2. Perform lightweight HEAD request first to check if it's reachable
      // (Optional optimization: skip HEAD if we want to save one RTT)

      final response = await http.get(
        Uri.parse(fetchUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html',
        },
      ).timeout(const Duration(seconds: 4)); // Shorter timeout for better UX

      if (response.statusCode == 200) {
        final html = response.body;
        
        // Extract Description
        String? desc = _extractMetaContent(html, 'og:description');
        desc ??= _extractMetaContent(html, 'twitter:description');
        desc ??= _extractMetaContent(html, 'description');
        
        if (desc != null && desc.isNotEmpty) {
          final cleanDesc = _cleanHtmlEntities(desc);
          _descriptionCache[articleUrl] = cleanDesc;
          _prefs?.setString('desc_$articleUrl', cleanDesc);
        }

        String? imageUrl = _extractMetaContent(html, 'og:image');
        imageUrl ??= _extractMetaContent(html, 'twitter:image');
        imageUrl ??= _extractMetaContent(html, 'twitter:image:src');

        if (imageUrl != null && imageUrl.isNotEmpty) {
          if (imageUrl.startsWith('//')) imageUrl = 'https:$imageUrl';
          
          _thumbnailCache[articleUrl] = imageUrl;
          _prefs?.setString('thumb_$articleUrl', imageUrl);
          return imageUrl;
        }
      }
    } catch (_) {
      // Ignore errors for optional metadata
    }

    // Mark as checked but empty to avoid re-fetching
    _thumbnailCache[articleUrl] = '';
    _prefs?.setString('thumb_$articleUrl', '');
    return '';
  }

  static String _cleanHtmlEntities(String text) {
    return text.replaceAll('&quot;', '"')
               .replaceAll('&#39;', "'")
               .replaceAll('&amp;', '&')
               .replaceAll('&lt;', '<')
               .replaceAll('&gt;', '>')
               .replaceAll('&nbsp;', ' ')
               .replaceAll(RegExp(r'<[^>]*>'), '')
               .replaceAll(RegExp(r'\s+'), ' ')
               .trim();
  }

  static String? _extractMetaContent(String html, String property) {
    final patterns = [
      RegExp('meta[^>]*property=["\']$property["\'][^>]*content=["\'](.*?)["\']', caseSensitive: false),
      RegExp('meta[^>]*content=["\'](.*?)["\'][^>]*property=["\']$property["\']', caseSensitive: false),
      RegExp('meta[^>]*name=["\']$property["\'][^>]*content=["\'](.*?)["\']', caseSensitive: false),
      RegExp('meta[^>]*content=["\'](.*?)["\'][^>]*name=["\']$property["\']', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final content = match.group(1);
        if (content != null && content.isNotEmpty) {
          if (content.startsWith('http') || content.startsWith('//')) {
            return content;
          }
        }
      }
    }
    return null;
  }

  static String getFaviconUrl(String domain) {
    String cleanDomain = domain;
    if (cleanDomain.startsWith('http')) {
      try {
        cleanDomain = Uri.parse(cleanDomain).host;
      } catch (_) {}
    }
    return 'https://www.google.com/s2/favicons?domain=$cleanDomain&sz=128'; // High-res favicon
  }

  /// Refined batch processing: only process 2 at a time to prevent UI stutter
  static Future<void> batchExtractThumbnails(
    List<NewsArticle> articles, {
    Function()? onUpdate,
  }) async {
    // Only process articles that aren't already cached
    final pending = articles.where((a) => !_thumbnailCache.containsKey(a.url)).toList();
    if (pending.isEmpty) return;

    const batchSize = 2;
    for (int i = 0; i < pending.length; i += batchSize) {
      final batch = pending.skip(i).take(batchSize);
      await Future.wait(
        batch.map((article) => extractThumbnail(article.url)),
        eagerError: false,
      );
      if (i % 4 == 0) onUpdate?.call(); // Batch updates for smoother UI
    }
    onUpdate?.call();
  }
}
