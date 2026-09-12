import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_mobile/features/articles/presentation/controllers/articles_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(articleDetailProvider(slug));

    return Scaffold(
      backgroundColor: context.isDark ? context.colorScheme.surface : const Color(0xFFFBFBFA),
      appBar: AppBar(
        backgroundColor: context.isDark ? context.colorScheme.surface : const Color(0xFFFBFBFA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.textPrimary()),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/app/articles');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, size: 22, color: context.textPrimary()),
            onPressed: () {
              // Share action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép liên kết bài viết'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: articleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F5B38)),
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: context.textMuted()),
                const SizedBox(height: 16),
                Text(
                  'Không thể tải bài viết',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary(),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: context.textSecondary(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.refresh(articleDetailProvider(slug)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.primary,
                    side: BorderSide(color: context.colorScheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (article) {
          final dateFormat = DateFormat('dd/MM/yyyy');
          final dateStr = article.publishedAt != null
              ? dateFormat.format(article.publishedAt!.toLocal())
              : dateFormat.format(article.createdAt.toLocal());

          // Estimate reading time (~200 words per minute)
          final wordCount = article.content.split(RegExp(r'\s+')).length;
          final readingMinutes = (wordCount / 180).ceil().clamp(1, 60);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // Category tag
              if (article.categoryName != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.isDark ? const Color(0xFF143823) : const Color(0xFFEBF5EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.categoryName!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.primary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Title
              Text(
                article.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary(),
                  letterSpacing: -0.6,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Metadata (author, date, reading time)
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.authorName ?? 'Ban biên tập SKVI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary(),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                              color: context.textMuted(),
                            ),
                          ),
                          Text(' • ', style: TextStyle(color: context.textMuted())),
                          Text(
                            '$readingMinutes phút đọc',
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
                ],
              ),
              const SizedBox(height: 20),

              // Featured image
              if (article.featuredImageUrl != null &&
                  article.featuredImageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: article.featuredImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: context.isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFF1F3F2),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Excerpt callout
              if (article.excerpt != null && article.excerpt!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFF4F9F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: context.colorScheme.primary, width: 4),
                    ),
                  ),
                  child: Text(
                    article.excerpt!,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: context.textPrimary(),
                      height: 1.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Main body (HTML)
              HtmlWidget(
                article.content,
                textStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: context.textPrimary(),
                  height: 1.65,
                  letterSpacing: -0.1,
                ),
                customStylesBuilder: (element) {
                  if (element.localName == 'h1') {
                    return {'font-size': '20px', 'font-weight': '600', 'margin-top': '16px'};
                  }
                  if (element.localName == 'h2') {
                    return {'font-size': '18px', 'font-weight': '600', 'margin-top': '14px'};
                  }
                  if (element.localName == 'h3') {
                    return {'font-size': '16px', 'font-weight': '500', 'margin-top': '12px'};
                  }
                  if (element.localName == 'p') {
                    return {'margin-bottom': '12px'};
                  }
                  if (element.localName == 'img') {
                    return {'border-radius': '12px', 'max-width': '100%'};
                  }
                  return null;
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
