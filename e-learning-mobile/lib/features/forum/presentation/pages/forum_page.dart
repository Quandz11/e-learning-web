import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../shared/constants/app_roles.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../controllers/forum_controller.dart';

class ForumPage extends ConsumerStatefulWidget {
  const ForumPage({super.key});

  @override
  ConsumerState<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends ConsumerState<ForumPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forumControllerProvider);
    final controller = ref.read(forumControllerProvider.notifier);
    final session = ref.read(sessionControllerProvider.notifier).sessionOrNull;
    final currentUserId = session?.user.id;
    final isAdmin =
        (session?.user.role.toUpperCase() ?? '') == AppRoles.admin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(title: const Text('Diễn đàn')),
      floatingActionButton: state.selectedCategoryId != null
          ? FloatingActionButton.extended(
              onPressed: state.submitting
                  ? null
                  : () => _showNewThreadSheet(context, controller),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Tạo chủ đề',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          // Error banner
          if (state.error != null)
            Container(
              width: double.infinity,
              color: AppColors.error.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                state.error!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.error,
                ),
              ),
            ),

          // Category scroll
          if (state.categories.isNotEmpty)
            Container(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final cat = state.categories[index];
                    final isSelected = cat.id == state.selectedCategoryId;
                    return GestureDetector(
                      onTap: () => controller.selectCategory(cat.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightBg),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                        ),
                        child: Text(
                          cat.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textDark
                                    : AppColors.textLight),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Thread list
          Expanded(
            child: state.loading && state.threads.isEmpty
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.selectedCategoryId == null
                    ? EmptyState(
                        icon: Icons.forum_outlined,
                        message: 'Chọn một danh mục\nđể xem chủ đề.',
                      )
                    : state.threads.isEmpty
                        ? EmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            message: 'Chưa có chủ đề nào.\nHãy tạo chủ đề đầu tiên!',
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () => controller.loadThreads(
                              state.selectedCategoryId!,
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                              itemCount: state.threads.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, index) {
                                final thread = state.threads[index];
                                final threadId =
                                    thread['id']?.toString() ?? '';
                                final isSelected =
                                    threadId == state.selectedThreadId;
                                final postCount = _toInt(thread['postCount']);

                                return GestureDetector(
                                  onTap: threadId.isEmpty
                                      ? null
                                      : () => _openThread(
                                            context,
                                            thread,
                                            controller,
                                            currentUserId,
                                            isAdmin,
                                            isDark,
                                          ),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(
                                              alpha: 0.06,
                                            )
                                          : (isDark
                                              ? AppColors.darkCard
                                              : AppColors.lightCard),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary.withValues(
                                                alpha: 0.4,
                                              )
                                            : (isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          thread['title']?.toString() ??
                                              'Không có tiêu đề',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.textDark
                                                : AppColors.textLight,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_outline_rounded,
                                              size: 14,
                                              color: isDark
                                                  ? AppColors.textDarkSecondary
                                                  : AppColors.textLightSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              thread['authorName']?.toString() ??
                                                  'Ẩn danh',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: isDark
                                                    ? AppColors.textDarkSecondary
                                                    : AppColors
                                                        .textLightSecondary,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$postCount phản hồi',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _openThread(
    BuildContext context,
    Map<String, dynamic> thread,
    ForumController controller,
    String? currentUserId,
    bool isAdmin,
    bool isDark,
  ) async {
    final threadId = thread['id']?.toString() ?? '';
    await controller.openThread(threadId);

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ThreadDetailSheet(
        threadId: threadId,
        thread: thread,
        currentUserId: currentUserId,
        isAdmin: isAdmin,
        isDark: isDark,
        controller: controller,
      ),
    );
  }

  Future<void> _showNewThreadSheet(
    BuildContext context,
    ForumController controller,
  ) async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewThreadSheet(
        titleController: titleCtrl,
        contentController: contentCtrl,
        onSubmit: () async {
          final catId =
              ref.read(forumControllerProvider).selectedCategoryId;
          if (catId == null) return;
          await controller.createThread(
            categoryId: catId,
            title: titleCtrl.text,
            content: contentCtrl.text,
          );
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

// ── Thread Detail Bottom Sheet ───────────────────────────────────────────────

class _ThreadDetailSheet extends ConsumerStatefulWidget {
  const _ThreadDetailSheet({
    required this.threadId,
    required this.thread,
    required this.currentUserId,
    required this.isAdmin,
    required this.isDark,
    required this.controller,
  });

  final String threadId;
  final Map<String, dynamic> thread;
  final String? currentUserId;
  final bool isAdmin;
  final bool isDark;
  final ForumController controller;

  @override
  ConsumerState<_ThreadDetailSheet> createState() =>
      _ThreadDetailSheetState();
}

class _ThreadDetailSheetState extends ConsumerState<_ThreadDetailSheet> {
  final _replyCtrl = TextEditingController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forumControllerProvider);
    final isDark = widget.isDark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Thread content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                children: [
                  Text(
                    widget.thread['title']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.thread['content']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'bởi ${widget.thread['authorName'] ?? 'Ẩn danh'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phản hồi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.loading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  else if (state.posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Chưa có phản hồi nào.',
                        style: GoogleFonts.inter(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      ),
                    )
                  else
                    ...state.posts.map((post) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['authorName']?.toString() ?? 'Ẩn danh',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              post['content']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            // Reply input
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Viết phản hồi...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: state.submitting
                        ? null
                        : () async {
                            final text = _replyCtrl.text.trim();
                            if (text.isEmpty) return;
                            _replyCtrl.clear();
                            await widget.controller.createPost(
                              threadId: widget.threadId,
                              content: text,
                            );
                          },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: state.submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── New Thread Bottom Sheet ──────────────────────────────────────────────────

class _NewThreadSheet extends StatelessWidget {
  const _NewThreadSheet({
    required this.titleController,
    required this.contentController,
    required this.onSubmit,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tạo chủ đề mới',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contentController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Nội dung'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onSubmit,
            child: const Text('Đăng chủ đề'),
          ),
        ],
      ),
    );
  }
}

int _toInt(dynamic raw) {
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}
