import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/forum/data/models/forum_models.dart';
import 'package:e_learning_mobile/features/forum/presentation/controllers/forum_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ForumHomeScreen extends ConsumerWidget {
  const ForumHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forumControllerProvider);
    final controller = ref.read(forumControllerProvider.notifier);
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFFBFBFA),
      appBar: AppBar(
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFFBFBFA),
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
          'Cộng đồng Chia sẻ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.textPrimary(),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRoutes.appCommunityCreateThread);
        },
        backgroundColor: isDark ? colorScheme.primary : const Color(0xFF0F5B38),
        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
        label: const Text(
          'Đặt câu hỏi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Column(
        children: [
          // Category selector
          if (state.categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final cat = state.categories[index];
                  final isSelected = state.selectedCategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller.selectCategory(cat.id),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                      ? colorScheme.primary
                                      : const Color(0xFF0F5B38))
                                : context.cardBg(),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                        ? colorScheme.primary
                                        : const Color(0xFF0F5B38))
                                  : context.cardBorder(),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : context.textSecondary(),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Thread list
          Expanded(
            child: state.isLoading && state.threads.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? colorScheme.primary : const Color(0xFF0F5B38),
                      ),
                    ),
                  )
                : state.error != null && state.threads.isEmpty
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
                            'Không thể tải các chủ đề thảo luận',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.textPrimary(),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => controller.refresh(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? colorScheme.primary
                                  : const Color(0xFF0F5B38),
                              side: BorderSide(
                                color: isDark
                                    ? colorScheme.primary
                                    : const Color(0xFF0F5B38),
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
                : state.threads.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerHighest
                                : const Color(0xFFEBF5EE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.forum_outlined,
                            size: 32,
                            color: isDark
                                ? colorScheme.primary
                                : const Color(0xFF0F5B38),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có bài thảo luận nào',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary(),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hãy là người đầu tiên đặt câu hỏi trong chuyên mục này!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: context.textSecondary(),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: isDark
                        ? colorScheme.primary
                        : const Color(0xFF0F5B38),
                    onRefresh: () => controller.refresh(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: state.threads.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final thread = state.threads[index];
                        return _ThreadCard(
                          thread: thread,
                          onTap: () {
                            context.push('/app/community/threads/${thread.id}');
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

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.thread, required this.onTap});

  final ForumThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateStr = dateFormat.format(thread.createdAt.toLocal());
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author header
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest
                          : const Color(0xFF0F5B38).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: isDark
                          ? colorScheme.primary
                          : const Color(0xFF0F5B38),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    thread.authorName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary(),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: context.textMuted(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                thread.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary(),
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),

              // Content snippet
              Text(
                thread.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: context.textSecondary(),
                  height: 1.4,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 12),

              // Footer stats
              Row(
                children: [
                  Icon(
                    Icons.mode_comment_outlined,
                    size: 14,
                    color: isDark
                        ? colorScheme.primary
                        : const Color(0xFF0F5B38),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${thread.postCount} phản hồi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? colorScheme.primary
                          : const Color(0xFF0F5B38),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: context.textMuted(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${thread.viewCount} xem',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: context.textMuted(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
