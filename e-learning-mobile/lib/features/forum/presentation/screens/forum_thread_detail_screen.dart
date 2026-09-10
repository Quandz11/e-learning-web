import 'package:e_learning_mobile/features/forum/data/forum_repository.dart';
import 'package:e_learning_mobile/features/forum/data/models/forum_models.dart';
import 'package:e_learning_mobile/features/forum/presentation/controllers/forum_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ForumThreadDetailScreen extends ConsumerStatefulWidget {
  const ForumThreadDetailScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ForumThreadDetailScreen> createState() => _ForumThreadDetailScreenState();
}

class _ForumThreadDetailScreenState extends ConsumerState<ForumThreadDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(forumRepositoryProvider);
      await repo.createPost(threadId: widget.threadId, content: text);
      _commentController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        ref.invalidate(forumThreadPostsProvider(widget.threadId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi bình luận: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(forumThreadDetailProvider(widget.threadId));
    final postsAsync = ref.watch(forumThreadPostsProvider(widget.threadId));

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E2621)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chi tiết Thảo luận',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2621),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: threadAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F5B38)),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE9EBEA), width: 1),
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
                                  color: const Color(0xFF0F5B38).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                  color: Color(0xFF0F5B38),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      thread.authorName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E2621),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Text(
                                      dateFormat.format(thread.createdAt.toLocal()),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w300,
                                        color: Color(0xFFA5A9A5),
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2621),
                              letterSpacing: -0.4,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            thread.content,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF334036),
                              height: 1.6,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section Title: Comments
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Phản hồi & Thảo luận',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E2621),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Posts list
                    postsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F5B38)),
                          ),
                        ),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Lỗi tải bình luận: $err'),
                      ),
                      data: (posts) {
                        if (posts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: const Text(
                              'Chưa có phản hồi nào. Hãy chia sẻ suy nghĩ của bạn!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF717873),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: posts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return _PostCard(post: post, dateFormat: dateFormat);
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom comment input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              10 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE9EBEA), width: 1)),
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
                      color: const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E2621)),
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        hintText: 'Nhập câu trả lời của bạn...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFFA5A9A5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
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
                      : const Icon(Icons.send_rounded, color: Color(0xFF0F5B38)),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EBEA), width: 1),
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
                  color: const Color(0xFF0F5B38).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: Color(0xFF0F5B38),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                post.authorName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E2621),
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(post.createdAt.toLocal()),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFFA5A9A5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: Color(0xFF334036),
              height: 1.5,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
