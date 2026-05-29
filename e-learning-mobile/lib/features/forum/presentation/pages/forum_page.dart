import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../shared/constants/app_roles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../controllers/forum_controller.dart';

class ForumPage extends ConsumerStatefulWidget {
  const ForumPage({super.key});

  @override
  ConsumerState<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends ConsumerState<ForumPage> {
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forumControllerProvider);
    final controller = ref.read(forumControllerProvider.notifier);
    ref.watch(sessionControllerProvider);
    final session = ref.read(sessionControllerProvider.notifier).sessionOrNull;
    final currentUserId = session?.user.id;
    final isAdmin = (session?.user.role.toUpperCase() ?? '') == AppRoles.admin;

    return AppScaffold(
      title: 'Forum',
      child: Column(
        children: [
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _CategoryStrip(
                    categoryNames: state.categories
                        .map((category) => category.name)
                        .toList(),
                    selectedIndex: state.categories.indexWhere(
                      (category) => category.id == state.selectedCategoryId,
                    ),
                    onTap: (index) async {
                      final category = state.categories[index];
                      await controller.selectCategory(category.id);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed:
                      state.selectedCategoryId == null || state.submitting
                      ? null
                      : () => _showThreadDialog(context, controller),
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.loading && state.threads.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _ThreadList(
                          threads: state.threads,
                          selectedThreadId: state.selectedThreadId,
                          onTap: (threadId) => controller.openThread(threadId),
                          onRefresh: state.selectedCategoryId == null
                              ? null
                              : () => controller.loadThreads(
                                  state.selectedCategoryId!,
                                ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        flex: 5,
                        child: _ThreadDetailPanel(
                          thread: state.selectedThread,
                          posts: state.posts,
                          loading: state.loading,
                          submitting: state.submitting,
                          replyController: _replyController,
                          canManageThread: (thread) => _canManage(
                            thread['authorId']?.toString(),
                            currentUserId,
                            isAdmin,
                          ),
                          canManagePost: (post) => _canManage(
                            post['authorId']?.toString(),
                            currentUserId,
                            isAdmin,
                          ),
                          onReply: () async {
                            final threadId = state.selectedThreadId;
                            if (threadId == null || threadId.isEmpty) {
                              return;
                            }
                            final reply = _replyController.text;
                            _replyController.clear();
                            await controller.createPost(
                              threadId: threadId,
                              content: reply,
                            );
                          },
                          onEditThread: state.selectedThread == null
                              ? null
                              : () => _showThreadDialog(
                                  context,
                                  controller,
                                  thread: state.selectedThread,
                                ),
                          onDeleteThread: state.selectedThread == null
                              ? null
                              : () => _confirmDeleteThread(
                                  context,
                                  controller,
                                  state.selectedThread!['id']?.toString() ?? '',
                                ),
                          onEditPost: (post) => _showPostDialog(
                            context,
                            controller,
                            state.selectedThreadId,
                            post: post,
                          ),
                          onDeletePost: (post) => _confirmDeletePost(
                            context,
                            controller,
                            state.selectedThreadId,
                            post['id']?.toString() ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool _canManage(String? authorId, String? currentUserId, bool isAdmin) {
    if (isAdmin) {
      return true;
    }
    if (authorId == null || currentUserId == null) {
      return false;
    }
    return authorId == currentUserId;
  }

  Future<void> _showThreadDialog(
    BuildContext context,
    ForumController controller, {
    Map<String, dynamic>? thread,
  }) async {
    final titleController = TextEditingController(
      text: thread?['title']?.toString() ?? '',
    );
    final contentController = TextEditingController(
      text: thread?['content']?.toString() ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(thread == null ? 'Create thread' : 'Edit thread'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Content'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final selectedCategoryId = ref
        .read(forumControllerProvider)
        .selectedCategoryId;
    if (thread == null) {
      if (selectedCategoryId == null) {
        return;
      }
      await controller.createThread(
        categoryId: selectedCategoryId,
        title: titleController.text,
        content: contentController.text,
      );
      return;
    }

    final threadId = thread['id']?.toString() ?? '';
    await controller.updateThread(
      threadId: threadId,
      title: titleController.text,
      content: contentController.text,
    );
  }

  Future<void> _showPostDialog(
    BuildContext context,
    ForumController controller,
    String? threadId, {
    required Map<String, dynamic> post,
  }) async {
    if (threadId == null || threadId.isEmpty) {
      return;
    }

    final contentController = TextEditingController(
      text: post['content']?.toString() ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit reply'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: contentController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.updatePost(
      postId: post['id']?.toString() ?? '',
      threadId: threadId,
      content: contentController.text,
    );
  }

  Future<void> _confirmDeleteThread(
    BuildContext context,
    ForumController controller,
    String threadId,
  ) async {
    if (threadId.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete thread'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteThread(threadId);
    }
  }

  Future<void> _confirmDeletePost(
    BuildContext context,
    ForumController controller,
    String? threadId,
    String postId,
  ) async {
    if (threadId == null || threadId.isEmpty || postId.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reply'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deletePost(postId: postId, threadId: threadId);
    }
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categoryNames,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<String> categoryNames;
  final int selectedIndex;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    if (categoryNames.isEmpty) {
      return const Text('No categories available.');
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categoryNames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return ChoiceChip(
            selected: selected,
            label: Text(categoryNames[index]),
            onSelected: (_) => onTap(index),
          );
        },
      ),
    );
  }
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({
    required this.threads,
    required this.selectedThreadId,
    required this.onTap,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> threads;
  final String? selectedThreadId;
  final Future<void> Function(String threadId) onTap;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No threads in this category.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        final threadId = thread['id']?.toString() ?? '';
        final isSelected = threadId == selectedThreadId;
        final postCount = _toInt(thread['postCount']);

        return Card(
          child: ListTile(
            selected: isSelected,
            title: Text(thread['title']?.toString() ?? 'Untitled'),
            subtitle: Text(
              'By ${thread['authorName'] ?? 'Unknown'} • $postCount replies',
            ),
            onTap: threadId.isEmpty ? null : () => onTap(threadId),
          ),
        );
      },
    );
  }
}

class _ThreadDetailPanel extends StatelessWidget {
  const _ThreadDetailPanel({
    required this.thread,
    required this.posts,
    required this.loading,
    required this.submitting,
    required this.replyController,
    required this.canManageThread,
    required this.canManagePost,
    required this.onReply,
    required this.onEditThread,
    required this.onDeleteThread,
    required this.onEditPost,
    required this.onDeletePost,
  });

  final Map<String, dynamic>? thread;
  final List<Map<String, dynamic>> posts;
  final bool loading;
  final bool submitting;
  final TextEditingController replyController;
  final bool Function(Map<String, dynamic> thread) canManageThread;
  final bool Function(Map<String, dynamic> post) canManagePost;
  final Future<void> Function() onReply;
  final Future<void> Function()? onEditThread;
  final Future<void> Function()? onDeleteThread;
  final Future<void> Function(Map<String, dynamic> post) onEditPost;
  final Future<void> Function(Map<String, dynamic> post) onDeletePost;

  @override
  Widget build(BuildContext context) {
    if (thread == null) {
      return const Center(child: Text('Select a thread to view details.'));
    }

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread!['title']?.toString() ?? 'Untitled',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(thread!['content']?.toString() ?? ''),
                const SizedBox(height: 8),
                Text(
                  'By ${thread!['authorName'] ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (canManageThread(thread!)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: submitting ? null : onEditThread,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: submitting ? null : onDeleteThread,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: posts.isEmpty
                ? const Center(child: Text('No replies yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            post['authorName']?.toString() ?? 'Unknown',
                          ),
                          subtitle: Text(post['content']?.toString() ?? ''),
                          trailing: canManagePost(post)
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      onEditPost(post);
                                      return;
                                    }
                                    if (value == 'delete') {
                                      onDeletePost(post);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: replyController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Write a reply'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: submitting ? null : onReply,
                child: Text(submitting ? 'Saving...' : 'Reply'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

int _toInt(dynamic raw) {
  if (raw is int) {
    return raw;
  }
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}
