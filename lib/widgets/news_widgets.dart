import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/news_model.dart';
import '../services/thumbnail_service.dart';
import '../utils/app_theme.dart';

/// Google News style card with source, title, real thumbnail and time
class NewsCard extends StatefulWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  final int index;

  const NewsCard({
    super.key,
    required this.article,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _isHovered = false;
  String? _thumbnailUrl;
  String? _description;

  @override
  void initState() {
    super.initState();
    _description = widget.article.description.isNotEmpty ? widget.article.description : null;
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant NewsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article.url != widget.article.url) {
      _description = widget.article.description.isNotEmpty ? widget.article.description : null;
      _loadThumbnail();
    }
  }

  void _loadThumbnail() {
    if (widget.article.imageUrl.isNotEmpty && _description != null) {
      setState(() => _thumbnailUrl = widget.article.imageUrl);
      return;
    }

    final cachedImg = ThumbnailService.getCachedThumbnail(widget.article.url);
    final cachedDesc = ThumbnailService.getCachedDescription(widget.article.url);
    
    if (cachedImg != null) {
      setState(() {
         _thumbnailUrl = cachedImg;
         if (_description == null && cachedDesc != null) {
           _description = cachedDesc;
         }
      });
      if (_description != null) return; // If we have both, we can return
    }

    ThumbnailService.extractThumbnail(widget.article.url).then((url) {
      if (mounted) {
        setState(() {
          _thumbnailUrl = url;
          _description ??= ThumbnailService.getCachedDescription(widget.article.url);
        });
      }
    });
  }

  IconData _getSourceIcon(String source) {
    final lower = source.toLowerCase();
    if (lower.contains('bbc') || lower.contains('cnn') || lower.contains('nbc') ||
        lower.contains('fox') || lower.contains('abc') || lower.contains('ndtv')) {
      return Icons.tv_rounded;
    }
    if (lower.contains('times') || lower.contains('post') || lower.contains('journal') ||
        lower.contains('guardian') || lower.contains('tribune') || lower.contains('hindu')) {
      return Icons.newspaper_rounded;
    }
    if (lower.contains('tech') || lower.contains('verge') || lower.contains('wired') ||
        lower.contains('cnbc')) {
      return Icons.trending_up_rounded;
    }
    if (lower.contains('youtube')) return Icons.play_circle_rounded;
    if (lower.contains('reuters') || lower.contains('ap ') || lower.contains('associated')) {
      return Icons.public_rounded;
    }
    return Icons.article_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final sourceColor = AppTheme.getSourceColor(widget.article.sourceName);
    final hasThumbnail = _thumbnailUrl != null && _thumbnailUrl!.isNotEmpty;
    final faviconUrl = ThumbnailService.getFaviconUrl(
        widget.article.sourceUrl.isNotEmpty
            ? widget.article.sourceUrl
            : widget.article.sourceName);

    return MouseRegion(
      onEnter: (event) => setState(() => _isHovered = true),
      onExit: (event) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source row
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CachedNetworkImage(
                              imageUrl: faviconUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: sourceColor.withValues(alpha: 0.1),
                                child: Icon(_getSourceIcon(widget.article.sourceName),
                                    color: sourceColor, size: 8),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: sourceColor.withValues(alpha: 0.15),
                                child: Icon(_getSourceIcon(widget.article.sourceName),
                                    color: sourceColor, size: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.article.sourceName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      widget.article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: _isHovered ? AppTheme.primaryLight : Colors.white.withValues(alpha: 0.95),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _timeAgo(widget.article.publishedAt),
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.library_books_outlined,
                          color: _isHovered ? AppTheme.primaryLight : Colors.white.withValues(alpha: 0.4),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasThumbnail || _thumbnailUrl == null) ...[
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: hasThumbnail
                        ? CachedNetworkImage(
                            imageUrl: _thumbnailUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 152, // Optimization: only decode at 2x display size
                            memCacheHeight: 152,
                            placeholder: (context, url) => _buildPlaceholder(sourceColor),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholder(sourceColor),
                          )
                        : _buildLoadingPlaceholder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate(delay: (widget.index * 60).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.05, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildPlaceholder(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getSourceIcon(widget.article.sourceName),
          color: accentColor.withValues(alpha: 0.35),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppTheme.bgDark,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: AppTheme.primary.withValues(alpha: 0.3),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class CategoryChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.chipSelected
                : _isHovered
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.chipSelected
                  : _isHovered
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.outfit(
              color: widget.isSelected
                  ? Colors.white
                  : _isHovered
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: widget.isSelected || _isHovered
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return DateFormat('MMM d').format(dateTime);
  }
}
