import 'package:e_learning_mobile/features/articles/data/articles_repository.dart';
import 'package:e_learning_mobile/features/forum/data/forum_repository.dart';
import 'package:e_learning_mobile/features/learning/data/learning_repository.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum SearchCategory { all, courses, articles, forum }

class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.routePath,
    this.badgeText,
  });

  final String id;
  final String title;
  final String subtitle;
  final SearchCategory category;
  final String routePath;
  final String? badgeText;
}

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchCategory _selectedCategory = SearchCategory.all;
  bool _isSearching = false;
  List<SearchResultItem> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final items = <SearchResultItem>[];

    try {
      // 1. Search Courses
      if (_selectedCategory == SearchCategory.all || _selectedCategory == SearchCategory.courses) {
        final learningRepo = ref.read(learningRepositoryProvider);
        final loadResult = await learningRepo.loadLearning();
        for (final c in loadResult.courses) {
          if (c.title.toLowerCase().contains(trimmed) ||
              (c.description?.toLowerCase().contains(trimmed) ?? false)) {
            items.add(
              SearchResultItem(
                id: c.id,
                title: c.title,
                subtitle: c.description ?? 'Khóa học nhịn ăn & sức khỏe khoa học',
                category: SearchCategory.courses,
                routePath: '/app/learning/course/${c.id}',
                badgeText: 'Khóa học',
              ),
            );
          }
        }
      }

      // 2. Search Articles
      if (_selectedCategory == SearchCategory.all || _selectedCategory == SearchCategory.articles) {
        final articlesRepo = ref.read(articlesRepositoryProvider);
        final articles = await articlesRepo.getArticles(query: trimmed);
        for (final a in articles) {
          items.add(
            SearchResultItem(
              id: a.id,
              title: a.title,
              subtitle: a.excerpt ?? 'Bài viết kiến thức sức khỏe',
              category: SearchCategory.articles,
              routePath: '/app/articles/${a.slug}',
              badgeText: 'Bài viết',
            ),
          );
        }
      }

      // 3. Search Forum Threads
      if (_selectedCategory == SearchCategory.all || _selectedCategory == SearchCategory.forum) {
        final forumRepo = ref.read(forumRepositoryProvider);
        final categories = await forumRepo.getCategories();
        for (final cat in categories) {
          final threads = await forumRepo.getThreadsByCategory(cat.id);
          for (final t in threads) {
            if (t.title.toLowerCase().contains(trimmed) ||
                t.content.toLowerCase().contains(trimmed)) {
              items.add(
                SearchResultItem(
                  id: t.id,
                  title: t.title,
                  subtitle: t.content,
                  category: SearchCategory.forum,
                  routePath: '/app/community/thread/${t.id}',
                  badgeText: 'Thảo luận',
                ),
              );
            }
          }
        }
      }
    } catch (_) {
      // Fallback local matching
    }

    if (mounted) {
      setState(() {
        _results = items;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? colorScheme.surface : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.textPrimary()),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFEFF5F1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isDark ? colorScheme.outlineVariant : const Color(0xFFD3E6DC),
                width: 0.8,
              ),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: context.textPrimary()),
              onChanged: (val) => _performSearch(val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khóa học, bài viết, thảo luận...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: context.textMuted(),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0F5B38)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', SearchCategory.all),
                const SizedBox(width: 8),
                _buildFilterChip('Khóa học', SearchCategory.courses),
                const SizedBox(width: 8),
                _buildFilterChip('Bài viết', SearchCategory.articles),
                const SizedBox(width: 8),
                _buildFilterChip('Thảo luận', SearchCategory.forum),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.8),

          // Search Results Body
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F5B38)),
                    ),
                  )
                : _searchController.text.trim().isEmpty
                    ? _buildEmptyPrompt(context)
                    : _results.isEmpty
                        ? _buildNoResults(context)
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _results[index];
                              return _buildResultCard(context, item);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchCategory category) {
    final isSelected = _selectedCategory == category;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        _performSearch(_searchController.text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? context.colorScheme.primary : const Color(0xFF0F5B38))
              : context.cardBg(),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? (isDark ? context.colorScheme.primary : const Color(0xFF0F5B38))
                : context.cardBorder(),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected ? Colors.white : context.textPrimary(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 56, color: context.textMuted().withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Tìm kiếm nội dung học tập & sức khỏe',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.textPrimary(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nhập từ khóa như "Nhịn ăn", "Uống nước", "Kỹ thuật thở" để tìm nhanh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: context.textSecondary(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.find_in_page_outlined, size: 52, color: Color(0xFFA5A9A5)),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả phù hợp',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.textPrimary(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hãy thử thay đổi danh mục hoặc nhập từ khóa tìm kiếm khác.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: context.textSecondary(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, SearchResultItem item) {
    final isDark = context.isDark;

    IconData icon;
    Color color;

    switch (item.category) {
      case SearchCategory.courses:
        icon = Icons.school_rounded;
        color = const Color(0xFF0F5B38);
        break;
      case SearchCategory.articles:
        icon = Icons.article_rounded;
        color = const Color(0xFF2563EB);
        break;
      case SearchCategory.forum:
        icon = Icons.forum_rounded;
        color = const Color(0xFFD97706);
        break;
      case SearchCategory.all:
        icon = Icons.grid_view_rounded;
        color = const Color(0xFF0F5B38);
        break;
    }

    return InkWell(
      onTap: () => context.push(item.routePath),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.cardBg(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder(), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary(),
                          ),
                        ),
                      ),
                      if (item.badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            item.badgeText!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: context.textSecondary(),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textMuted(), size: 20),
          ],
        ),
      ),
    );
  }
}
