import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../services/thumbnail_service.dart';
import '../utils/app_theme.dart';
import '../widgets/news_widgets.dart';
import 'article_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with AutomaticKeepAliveClientMixin {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  NewsCategory _selectedCategory = NewsCategory.topStories;
  bool _isSearchMode = false;
  String _searchQuery = '';

  // Background refresh timer
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(hours: 1);
  bool _hasNewContent = false;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    _loadNews();
    _startBackgroundRefresh();
  }

  /// Start the 1-hour background refresh timer
  void _startBackgroundRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _silentRefresh();
    });
  }

  /// Silently refresh news in the background without affecting the UI
  Future<void> _silentRefresh() async {
    try {
      List<NewsArticle> newArticles;

      if (_isSearchMode && _searchQuery.isNotEmpty) {
        newArticles = await _newsService.searchNews(query: _searchQuery);
      } else {
        newArticles = await _newsService.getTopHeadlines(
          category: _selectedCategory,
        );
      }

      if (!mounted) return;

      // Only update if we got new content
      if (newArticles.isNotEmpty) {
        // Check if content actually changed
        final hasChanged = newArticles.length != _articles.length ||
            (newArticles.isNotEmpty &&
                _articles.isNotEmpty &&
                newArticles.first.title != _articles.first.title);

        if (hasChanged) {
          // Save scroll position
          final scrollOffset = _scrollController.hasClients
              ? _scrollController.offset
              : 0.0;

          setState(() {
            _articles = newArticles;
            _hasNewContent = true;
          });

          // Restore scroll position silently
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && scrollOffset > 0) {
              _scrollController.jumpTo(scrollOffset);
            }
          });

          // Fill cache in background - cards will update themselves 
          // via their own internal state when the global service cache is ready
          ThumbnailService.batchExtractThumbnails(newArticles);
          
          // Auto-hide "new content" badge after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) setState(() => _hasNewContent = false);
          });
        }
      }
    } catch (_) {
      // Silently fail - don't interrupt the user
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final articles = await _newsService.getTopHeadlines(
        category: _selectedCategory,
      );
      setState(() {
        _articles = articles;
        _isLoading = false;
      });

      // Pre-fill cache in background to improve scrolling performance
      ThumbnailService.batchExtractThumbnails(articles);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _searchNews(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchQuery = query;
    });

    try {
      final articles = await _newsService.searchNews(query: query);
      setState(() {
        _articles = articles;
        _isLoading = false;
      });

      ThumbnailService.batchExtractThumbnails(articles);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onCategoryChanged(NewsCategory category) {
    setState(() {
      _selectedCategory = category;
      _isSearchMode = false;
      _searchController.clear();
      _searchQuery = '';
    });
    _loadNews();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    }
  }

  void _openArticle(NewsArticle article) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ArticleDetailScreen(article: article),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildCategoryChips(),
              // New content indicator
              if (_hasNewContent)
                _buildNewContentBanner(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage.isNotEmpty
                        ? _buildErrorState()
                        : _buildNewsGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewContentBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.update_rounded, color: Color(0xFF42A5F5), size: 16),
          const SizedBox(width: 8),
          Text(
            'News updated',
            style: GoogleFonts.outfit(
              color: const Color(0xFF42A5F5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.5, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Stories',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isSearchMode && _searchQuery.isNotEmpty
                      ? 'Results for "$_searchQuery"'
                      : 'From Google News, Reddit & more',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.source_rounded,
                    color: Colors.white.withValues(alpha: 0.5), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_articles.length}',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search news, topics, sources...',
            hintStyle: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.25), size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearchMode = false;
                        _searchQuery = '';
                      });
                      _loadNews();
                    },
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.3), size: 18),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) => setState(() {}),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() => _isSearchMode = true);
              _searchNews(value);
            }
          },
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        itemCount: NewsCategory.values.length,
        itemBuilder: (context, index) {
          final category = NewsCategory.values[index];
          return Padding(
            padding: EdgeInsets.only(
                right: index < NewsCategory.values.length - 1 ? 8 : 0),
            child: CategoryChip(
              label: category.label,
              isSelected: !_isSearchMode && _selectedCategory == category,
              onTap: () => _onCategoryChanged(category),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(
            'Gathering news from multiple sources...',
            style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.white.withValues(alpha: 0.25), size: 56),
            const SizedBox(height: 14),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed:
                  _isSearchMode ? () => _searchNews(_searchQuery) : _loadNews,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsGrid() {
    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined,
                color: Colors.white.withValues(alpha: 0.15), size: 56),
            const SizedBox(height: 14),
            Text(
              'No articles found',
              style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          _isSearchMode ? () => _searchNews(_searchQuery) : _loadNews,
      color: AppTheme.primary,
      backgroundColor: AppTheme.bgCard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            itemCount: _articles.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(
                color: Colors.white.withValues(alpha: 0.1),
                thickness: 1,
              ),
            ),
            itemBuilder: (context, index) {
              return NewsCard(
                article: _articles[index],
                index: index,
                onTap: () => _openArticle(_articles[index]),
              );
            },
          );
        },
      ),
    );
  }
}
