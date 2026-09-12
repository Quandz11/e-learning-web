import 'package:e_learning_mobile/features/forum/data/forum_repository.dart';
import 'package:e_learning_mobile/features/forum/data/models/forum_models.dart';
import 'package:e_learning_mobile/features/forum/presentation/controllers/forum_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ForumThreadDetailScreen extends ConsumerStatefulWidget {
  const ForumThreadDetailScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ForumThreadDetailScreen> createState() => _ForumThreadDetailScreenState();
}

class _ForumThreadDetailScreenState extends ConsumerState<ForumThreadDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(forumRepositoryProvider);
      await repo.createPost(threadId: widget.threadId, content: text);
      _commentController.clear();
      ref.invalidate(forumThreadPostsProvider(widget.threadId));
      ref.invalidate(forumThreadDetailProvider(widget.threadId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi phản hồi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(forumThreadDetailProvider(widget.threadId));
    final postsAsync = ref.watch(forumThreadPostsProvider(widget.threadId));
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFFBFBFA),
      appBar: AppBar(
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFFBFBFA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.textPrimary()),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/app/community');
            }
          },
        ),
        title: Text(
          'Chi tiết Thảo luận',
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
          Expanded(
            child: threadAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? colorScheme.primary : const Color(0xFF0F5B38),
                  ),
                ),
              ),
              error: (error, _) => Center(
                child: Text('Lỗi: $error'),
              ),
              data: (thread) {
                final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Main Thread Post
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.cardBg(),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.cardBorder(), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFF0F5B38).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                  color: isDark ? colorScheme.primary : const Color(0xFF0F5B38),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      thread.authorName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimary(),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Text(
                                      dateFormat.format(thread.createdAt.toLocal()),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w300,
                                        color: context.textMuted(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            thread.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary(),
                              letterSpacing: -0.4,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            thread.content,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: context.textSecondary(),
                              height: 1.6,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Responses header
                    Text(
                      'Các câu trả lời',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary(),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    postsAsync.when(
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? colorScheme.primary : const Color(0xFF0F5B38),
                          ),
                        ),
                      ),
                      error: (error, _) => Text('Lỗi tải câu trả lời: $error'),
                      data: (posts) {
                        if (posts.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Chưa có câu trả lời nào. Hãy là người đầu tiên!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: context.textMuted(),
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: posts.map((post) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PostCard(post: post, dateFormat: dateFormat),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Reply Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              10 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: context.cardBg(),
              border: Border(top: BorderSide(color: context.cardBorder(), width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _commentController,
                      style: TextStyle(fontSize: 14, color: context.textPrimary()),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        hintText: 'Nhập câu trả lời của bạn...',
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: isDark ? colorScheme.primary : const Color(0xFF0F5B38),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.dateFormat});

  final ForumPost post;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorder(), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFF0F5B38).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: isDark ? colorScheme.primary : const Color(0xFF0F5B38),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                post.authorName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary(),
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(post.createdAt.toLocal()),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                  color: context.textMuted(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: context.textSecondary(),
              height: 1.5,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
