import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../utils/app_theme.dart';

class ArticleDetailScreen extends StatefulWidget {
  final NewsArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isVerified = false;
  bool _isVerifying = true;

  @override
  void initState() {
    super.initState();
    _verifyArticle();
  }

  Future<void> _verifyArticle() async {
    final newsService = NewsService();
    final verified = await newsService.crossVerifyArticle(widget.article);
    if (mounted) {
      setState(() {
        _isVerified = verified;
        _isVerifying = false;
      });
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.article.url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.bgDark,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _openInBrowser,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.open_in_new_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryDark,
                      AppTheme.bgCard,
                      AppTheme.bgDark,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVerificationBadge()
                      .animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.source_rounded,
                                color: AppTheme.primaryLight, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              widget.article.sourceName,
                              style: GoogleFonts.outfit(
                                color: AppTheme.primaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_rounded,
                          color: Colors.white.withValues(alpha: 0.3), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a')
                            .format(widget.article.publishedAt),
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                  const SizedBox(height: 24),

                  Text(
                    widget.article.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.1, duration: 400.ms),

                  const SizedBox(height: 24),

                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),

                  const SizedBox(height: 24),

                  if (widget.article.description.isNotEmpty)
                    Text(
                      widget.article.description,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.7,
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      label: Text(
                        'Read Full Article at ${widget.article.sourceName}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.white.withValues(alpha: 0.3), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This article is sourced from Google News and published by ${widget.article.sourceName}.',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge() {
    if (_isVerifying) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.warning.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                color: AppTheme.warning,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Verifying source...',
              style: GoogleFonts.outfit(
                color: AppTheme.warning,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isVerified
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isVerified
              ? AppTheme.success.withValues(alpha: 0.2)
              : AppTheme.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isVerified
                ? Icons.verified_rounded
                : Icons.info_outline_rounded,
            color: _isVerified ? AppTheme.success : AppTheme.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _isVerified
                ? 'Source verified via Google News ✓'
                : 'Source could not be verified',
            style: GoogleFonts.outfit(
              color: _isVerified ? AppTheme.success : AppTheme.warning,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
