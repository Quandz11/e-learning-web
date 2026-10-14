import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_mobile/features/articles/data/models/article_models.dart';
import 'package:e_learning_mobile/features/articles/presentation/controllers/articles_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ArticlesScreen extends ConsumerStatefulWidget {
  const ArticlesScreen({super.key});

  @override
  ConsumerState<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends ConsumerState<ArticlesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articlesControllerProvider);
    final controller = ref.read(articlesControllerProvider.notifier);

    return Scaffold(
      backgroundColor: context.isDark
          ? context.colorScheme.surface
          : const Color(0xFFFBFBFA),
      appBar: AppBar(
        backgroundColor: context.isDark
            ? context.colorScheme.surface
            : const Color(0xFFFBFBFA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: context.textPrimary(),
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/app');
            }
          },
        ),
        title: Text(
          'Kiến thức Sống khỏe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.textPrimary(),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: context.cardBg(),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cardBorder(), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Color(0xFF0F5B38),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textPrimary(),
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        hintText: 'Tìm kiếm bài viết, cẩm nang...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: context.textMuted(),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (val) => controller.search(val),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        controller.search('');
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: context.textSecondary(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Category Chips
          if (state.categories.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'Tất cả',
                    isSelected: state.selectedCategoryId == null,
                    onTap: () => controller.selectCategory(null),
                  ),
                  const SizedBox(width: 8),
                  ...state.categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: cat.name,
                        isSelected: state.selectedCategoryId == cat.id,
                        onTap: () => controller.selectCategory(cat.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Article list
          Expanded(
            child: state.isLoading && state.articles.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0F5B38),
                      ),
                    ),
                  )
                : state.error != null && state.articles.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 48,
                            color: context.textMuted(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không thể tải danh sách bài viết',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.textPrimary(),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => controller.load(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.colorScheme.primary,
                              side: BorderSide(
                                color: context.colorScheme.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : state.articles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? const Color(0xFF143823)
                                : const Color(0xFFEBF5EE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.article_outlined,
                            size: 32,
                            color: context.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có bài viết nào phù hợp',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary(),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: context.colorScheme.primary,
                    onRefresh: () => controller.refresh(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: state.articles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = state.articles[index];
                        return _ArticleCard(
                          article: item,
                          onTap: () {
                            context.push('/app/articles/${item.slug}');
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? context.colorScheme.primary : context.cardBg(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? context.colorScheme.primary
                  : context.cardBorder(),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              color: isSelected ? Colors.white : context.textSecondary(),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});

  final ArticleSummary article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateStr = article.publishedAt != null
        ? dateFormat.format(article.publishedAt!.toLocal())
        : dateFormat.format(article.createdAt.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardBg(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder(), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 96,
                  height: 84,
                  color: context.isDark
                      ? context.colorScheme.surfaceContainerHighest
                      : const Color(0xFFF1F3F2),
                  child:
                      article.featuredImageUrl != null &&
                          article.featuredImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.featuredImageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 192,
                          maxWidthDiskCache: 384,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.image_outlined,
                            size: 28,
                            color: context.textMuted(),
                          ),
                        )
                      : Icon(
                          Icons.article_outlined,
                          size: 28,
                          color: context.textMuted(),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article.categoryName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? const Color(0xFF143823)
                              : const Color(0xFFEBF5EE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.categoryName!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.primary,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary(),
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: context.textMuted(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: context.textMuted(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.visibility_outlined,
                          size: 12,
                          color: context.textMuted(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${article.viewCount}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: context.textMuted(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
