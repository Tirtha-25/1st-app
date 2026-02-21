import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/news_model.dart';

class NewsService {
  static const String _googleRssBase = 'https://news.google.com/rss';
  static const String _corsProxy = 'https://corsproxy.io/?';

  // In-memory cache for speed
  final Map<String, _CachedResult> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  String _wrapUrl(String url) {
    if (kIsWeb) {
      return '$_corsProxy${Uri.encodeComponent(url)}';
    }
    return url;
  }

  /// Fetch top headlines from multiple sources in parallel
  Future<List<NewsArticle>> getTopHeadlines({
    NewsCategory category = NewsCategory.topStories,
  }) async {
    final cacheKey = 'headlines_${category.label}';

    // Return cached result if fresh
    if (_cache.containsKey(cacheKey) &&
        DateTime.now().difference(_cache[cacheKey]!.timestamp) < _cacheDuration) {
      return _cache[cacheKey]!.articles;
    }

    // Fetch from multiple sources in parallel for more content + speed
    final futures = <Future<List<NewsArticle>>>[];

    // Source 1: Google News RSS by category
    String googleUrl;
    if (category == NewsCategory.topStories) {
      googleUrl = '$_googleRssBase?hl=en-US&gl=US&ceid=US:en';
    } else {
      googleUrl = '$_googleRssBase/topics/${category.topicToken}?hl=en-US&gl=US&ceid=US:en';
    }
    futures.add(_fetchFromRss(googleUrl));

    // Source 2: Google News India edition for more variety
    if (category == NewsCategory.topStories) {
      futures.add(_fetchFromRss('$_googleRssBase?hl=en-IN&gl=IN&ceid=IN:en'));
    }

    // Source 3: Reddit news RSS (additional free source)
    final redditTopic = _getRedditTopic(category);
    if (redditTopic != null) {
      futures.add(_fetchRedditRss(redditTopic));
    }

    // Source 4: Yahoo News RSS
    String yahooUrl = 'https://news.yahoo.com/rss/topstories';
    if (category != NewsCategory.topStories) {
      if (category == NewsCategory.sports) {
        yahooUrl = 'https://sports.yahoo.com/rss';
      } else if (category == NewsCategory.technology) {
        yahooUrl = 'https://news.yahoo.com/rss/tech';
      } else {
        yahooUrl = 'https://news.yahoo.com/rss/${category.name}';
      }
    }
    futures.add(_fetchFromRss(yahooUrl));

    try {
      final results = await Future.wait(
        futures,
        eagerError: false,
      );

      // Merge and deduplicate
      final allArticles = <NewsArticle>[];
      final seenTitles = <String>{};

      for (final articles in results) {
        for (final article in articles) {
          // Deduplicate by checking similar titles
          final titleKey = article.title.toLowerCase().trim();
          if (!seenTitles.contains(titleKey) && titleKey.length > 10) {
            seenTitles.add(titleKey);
            allArticles.add(article);
          }
        }
      }

      // Sort by publish date and time (latest first / descending order)
      allArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      // Cache the result
      _cache[cacheKey] = _CachedResult(allArticles, DateTime.now());

      return allArticles;
    } catch (e) {
      // If parallel fetch fails, try Google News alone
      return _fetchFromRss(googleUrl);
    }
  }

  /// Search news from multiple sources
  Future<List<NewsArticle>> searchNews({required String query}) async {
    final cacheKey = 'search_$query';

    if (_cache.containsKey(cacheKey) &&
        DateTime.now().difference(_cache[cacheKey]!.timestamp) < _cacheDuration) {
      return _cache[cacheKey]!.articles;
    }

    final encodedQuery = Uri.encodeComponent(query);
    final futures = <Future<List<NewsArticle>>>[];

    // Google News search
    futures.add(_fetchFromRss(
        '$_googleRssBase/search?q=$encodedQuery&hl=en-US&gl=US&ceid=US:en'));

    // Reddit search
    futures.add(_fetchRedditRss('search?q=$encodedQuery&sort=new&restrict_sr=&t=week',
        subreddit: 'news'));

    try {
      final results = await Future.wait(futures, eagerError: false);

      final allArticles = <NewsArticle>[];
      final seenTitles = <String>{};

      for (final articles in results) {
        for (final article in articles) {
          final titleKey = article.title.toLowerCase().trim();
          if (!seenTitles.contains(titleKey) && titleKey.length > 10) {
            seenTitles.add(titleKey);
            allArticles.add(article);
          }
        }
      }

      allArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      _cache[cacheKey] = _CachedResult(allArticles, DateTime.now());
      return allArticles;
    } catch (e) {
      return _fetchFromRss(
          '$_googleRssBase/search?q=$encodedQuery&hl=en-US&gl=US&ceid=US:en');
    }
  }

  /// Map NewsCategory to Reddit topic
  String? _getRedditTopic(NewsCategory category) {
    switch (category) {
      case NewsCategory.topStories:
        return '.json?limit=15';
      case NewsCategory.world:
        return '.json?limit=15';
      case NewsCategory.technology:
        return '.json?limit=15';
      case NewsCategory.business:
        return '.json?limit=15';
      case NewsCategory.science:
        return '.json?limit=15';
      case NewsCategory.sports:
        return '.json?limit=15';
      default:
        return null;
    }
  }

  String _getRedditSubreddit(NewsCategory category) {
    switch (category) {
      case NewsCategory.technology:
        return 'technology';
      case NewsCategory.business:
        return 'business';
      case NewsCategory.science:
        return 'science';
      case NewsCategory.sports:
        return 'sports';
      case NewsCategory.world:
        return 'worldnews';
      default:
        return 'news';
    }
  }

  /// Fetch from Reddit RSS as additional source
  Future<List<NewsArticle>> _fetchRedditRss(String path, {String? subreddit}) async {
    try {
      final sub = subreddit ?? _getRedditSubreddit(NewsCategory.topStories);
      final url = _wrapUrl('https://www.reddit.com/r/$sub/$path');

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        // Correctly decode as UTF-8 to prevent weird characters
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        return _parseRedditJson(body);
      }
      return [];
    } catch (_) {
      return []; // Silently fail - it's a bonus source
    }
  }

  /// Parse Reddit JSON response
  List<NewsArticle> _parseRedditJson(String jsonString) {
    try {
      // Reddit returns JSON, parse it
      final articles = <NewsArticle>[];
      // Simple regex extraction for titles and URLs from Reddit JSON
      final titlePattern = RegExp(r'"title"\s*:\s*"([^"]*)"');
      final urlPattern = RegExp(r'"url"\s*:\s*"(https?://[^"]*)"');
      final domainPattern = RegExp(r'"domain"\s*:\s*"([^"]*)"');
      final createdPattern = RegExp(r'"created_utc"\s*:\s*(\d+\.?\d*)');

      final thumbnailPattern = RegExp(r'"thumbnail"\s*:\s*"(https?://[^"]*)"');

      final titles = titlePattern.allMatches(jsonString).toList();
      final urls = urlPattern.allMatches(jsonString).toList();
      final domains = domainPattern.allMatches(jsonString).toList();
      final created = createdPattern.allMatches(jsonString).toList();
      final thumbnails = thumbnailPattern.allMatches(jsonString).toList();

      for (int i = 0; i < titles.length; i++) {
        final title = titles[i].group(1) ?? '';
        final url = i < urls.length ? (urls[i].group(1) ?? '') : '';
        final domain = i < domains.length ? (domains[i].group(1) ?? 'Reddit') : 'Reddit';
        String imageUrl = '';
        if (i < thumbnails.length) {
          imageUrl = thumbnails[i].group(1) ?? '';
          imageUrl = imageUrl.replaceAll('\\/', '/');
        }
        final timestamp = i < created.length
            ? DateTime.fromMillisecondsSinceEpoch(
                (double.tryParse(created[i].group(1) ?? '0')?.toInt() ?? 0) * 1000)
            : DateTime.now();

        // Skip Reddit self posts and non-article links
        if (title.isNotEmpty && url.isNotEmpty &&
            !url.contains('reddit.com') && !domain.contains('reddit.com') &&
            !title.startsWith('/r/') && title.length > 15) {
          articles.add(NewsArticle(
            title: _unescapeReddit(title),
            description: '',
            content: '',
            url: url,
            imageUrl: imageUrl,
            sourceName: domain,
            sourceUrl: 'https://$domain',
            publishedAt: timestamp,
          ));
        }
      }
      return articles;
    } catch (_) {
      return [];
    }
  }

  String _unescapeReddit(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('\\u2019', "'")
        .replaceAll('\\u2018', "'")
        .replaceAll('\\u201c', '"')
        .replaceAll('\\u201d', '"')
        .replaceAll('\\u2014', '—')
        .replaceAll('\\/', '/');
  }

  /// Fetch and parse Google News RSS feed
  Future<List<NewsArticle>> _fetchFromRss(String originalUrl) async {
    try {
      final url = _wrapUrl(originalUrl);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept': 'application/rss+xml, application/xml, text/xml, */*',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Forced UTF-8 decoding to fix encoding issues like "Vietnamâ"
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        
        // Offload heavy XML parsing to a background isolate for smooth scrolling
        return await compute(_parseRssStatic, body);
      }
      return [];
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('ClientException') || e.toString().contains('TimeoutException')) {
        throw Exception('No internet connection. Please check your network status.');
      }
      if (e is Exception) rethrow;
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Static version for compute()
  static List<NewsArticle> _parseRssStatic(String xmlString) {
    return NewsService()._parseRss(xmlString);
  }

  List<NewsArticle> _parseRss(String xmlString) {
    final document = xml.XmlDocument.parse(xmlString);
    final items = document.findAllElements('item');
    final articles = <NewsArticle>[];

    for (final item in items) {
      try {
        final title = _getElementText(item, 'title');
        final link = _getElementText(item, 'link');
        final pubDate = _getElementText(item, 'pubDate');
        final description = _getElementText(item, 'description');
        final source = item.findElements('source').isNotEmpty
            ? item.findElements('source').first.innerText
            : '';
        final sourceUrl = item.findElements('source').isNotEmpty
            ? item.findElements('source').first.getAttribute('url') ?? ''
            : '';

        String sourceName = source;
        String cleanTitle = title;
        if (sourceName.isEmpty && title.contains(' - ')) {
          final lastDash = title.lastIndexOf(' - ');
          sourceName = title.substring(lastDash + 3).trim();
          cleanTitle = title.substring(0, lastDash).trim();
        }

        String descriptionText = _cleanHtml(description);
        
        // If description is just the title duplicated (common for Google News RSS)
        if (descriptionText.startsWith(cleanTitle) || cleanTitle.startsWith(descriptionText)) {
          descriptionText = ''; // Fallback to empty so we can dynamically fetch og:description later
        }

        // Extract thumbnail from HTML image tags (e.g., Google News)
        String imageUrl = '';
        final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(description);
        if (imgMatch != null) {
          imageUrl = imgMatch.group(1) ?? '';
        }

        // Try extracting from media:content (e.g., Yahoo News)
        if (imageUrl.isEmpty) {
          final mediaContent = item.findElements('media:content');
          if (mediaContent.isNotEmpty) {
            imageUrl = mediaContent.first.getAttribute('url') ?? '';
          }
        }
        
        // Try extracting from media:thumbnail
        if (imageUrl.isEmpty) {
          final mediaThumbnail = item.findElements('media:thumbnail');
          if (mediaThumbnail.isNotEmpty) {
            imageUrl = mediaThumbnail.first.getAttribute('url') ?? '';
          }
        }

        DateTime publishedAt;
        try {
          publishedAt = _parseRssDate(pubDate);
        } catch (_) {
          publishedAt = DateTime.now();
        }

        if (cleanTitle.isNotEmpty && link.isNotEmpty && sourceName.isNotEmpty) {
          articles.add(NewsArticle(
            title: cleanTitle,
            description: descriptionText,
            content: '',
            url: link,
            imageUrl: imageUrl,
            sourceName: sourceName,
            sourceUrl: sourceUrl,
            publishedAt: publishedAt,
          ));
        }
      } catch (_) {
        continue;
      }
    }

    return articles;
  }

  String _getElementText(xml.XmlElement parent, String name) {
    final elements = parent.findElements(name);
    if (elements.isEmpty) return '';
    return elements.first.innerText.trim();
  }

  String _cleanHtml(String html) {
    final cleaned = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return cleaned
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime _parseRssDate(String dateStr) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };

    final parts = dateStr.split(' ');
    if (parts.length >= 5) {
      final day = int.parse(parts[1]);
      final month = months[parts[2]] ?? 1;
      final year = int.parse(parts[3]);
      final timeParts = parts[4].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
      return DateTime.utc(year, month, day, hour, minute, second);
    }
    return DateTime.now();
  }

  Future<bool> crossVerifyArticle(NewsArticle article) async {
    try {
      final url = kIsWeb ? _wrapUrl(article.url) : article.url;
      final response = await http.head(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}

class _CachedResult {
  final List<NewsArticle> articles;
  final DateTime timestamp;
  _CachedResult(this.articles, this.timestamp);
}
