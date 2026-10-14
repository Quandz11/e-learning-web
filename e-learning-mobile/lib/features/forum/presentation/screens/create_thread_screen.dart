import 'package:e_learning_mobile/features/forum/data/forum_repository.dart';
import 'package:e_learning_mobile/features/forum/presentation/controllers/forum_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateThreadScreen extends ConsumerStatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  ConsumerState<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends ConsumerState<CreateThreadScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedCategoryId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final forumState = ref.read(forumControllerProvider);
    if (forumState.selectedCategoryId != null) {
      _selectedCategoryId = forumState.selectedCategoryId;
    } else if (forumState.categories.isNotEmpty) {
      _selectedCategoryId = forumState.categories.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề bài viết')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung bài viết')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(forumRepositoryProvider);
      await repo.createThread(
        categoryId: _selectedCategoryId!,
        title: title,
        content: content,
      );
      ref.read(forumControllerProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng bài thảo luận thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể đăng bài: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumControllerProvider);

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
              context.go('/app/community');
            }
          },
        ),
        title: Text(
          'Tạo thảo luận mới',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.textPrimary(),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Đăng bài',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.isDark
                            ? context.colorScheme.primary
                            : const Color(0xFF0F5B38),
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Category selector
          Text(
            'Danh mục thảo luận',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimary(),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.cardBg(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cardBorder()),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategoryId,
                dropdownColor: context.cardBg(),
                isExpanded: true,
                hint: Text(
                  'Chọn chuyên mục',
                  style: TextStyle(color: context.textMuted()),
                ),
                items: forumState.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: context.textPrimary(),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategoryId = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title field
          Text(
            'Tiêu đề câu hỏi / chia sẻ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimary(),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.textPrimary(),
            ),
            decoration: InputDecoration(
              hintText: 'Ví dụ: Cần chuẩn bị gì trước khi bắt đầu nhịn ăn?',
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: context.textMuted(),
              ),
              filled: true,
              fillColor: context.cardBg(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.cardBorder()),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.cardBorder()),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colorScheme.primary),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Content field
          Text(
            'Nội dung chi tiết',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimary(),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: context.textPrimary(),
            ),
            maxLines: 8,
            decoration: InputDecoration(
              hintText:
                  'Mô tả chi tiết thắc mắc, trải nghiệm hoặc các câu hỏi cần được hỗ trợ...',
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: context.textMuted(),
              ),
              filled: true,
              fillColor: context.cardBg(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.cardBorder()),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.cardBorder()),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
