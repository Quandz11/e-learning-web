import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_state.dart';
import 'package:e_learning_mobile/features/learning/presentation/learning_error_messages.dart';
import 'package:e_learning_mobile/features/learning/presentation/widgets/document_reader_panel.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentReaderScreen extends ConsumerStatefulWidget {
  const DocumentReaderScreen({
    required this.courseId,
    required this.lessonPartId,
    super.key,
  });

  final String courseId;
  final String lessonPartId;

  @override
  ConsumerState<DocumentReaderScreen> createState() =>
      _DocumentReaderScreenState();
}

class _DocumentReaderScreenState extends ConsumerState<DocumentReaderScreen> {
  late final PdfViewerController _pdfController;
  final int _currentPage = 1;
  final int _totalPages = 8;
  double _zoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isValidId(widget.courseId) && _isValidId(widget.lessonPartId)) {
        ref.read(_provider.notifier).ensureLoaded();
      }
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  LessonRouteArgs get _args => LessonRouteArgs(
    courseId: widget.courseId,
    lessonPartId: widget.lessonPartId,
  );

  AutoDisposeStateNotifierProvider<LessonController, LessonState>
  get _provider => lessonControllerProvider(_args);

  @override
  Widget build(BuildContext context) {
    if (!_isValidId(widget.courseId) || !_isValidId(widget.lessonPartId)) {
      return Scaffold(
        backgroundColor: context.isDark ? context.colorScheme.surface : AppColors.background,
        body: const SafeArea(
          child: AppErrorView(message: 'Không tìm thấy tài liệu cần hiển thị.'),
        ),
      );
    }

    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);

    return Scaffold(
      backgroundColor: context.isDark ? context.colorScheme.surface : AppColors.background,
      appBar: AppBar(
        backgroundColor: context.isDark ? context.colorScheme.surface : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary(),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          state.detail?.part.title ?? 'Đọc Tài Liệu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimary(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải tài liệu PDF',
            icon: Icon(Icons.download_rounded, color: context.colorScheme.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang tải xuống file PDF...')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: state.isInitialLoading
            ? const AppLoadingView(label: 'Đang tải tài liệu...')
            : state.status == LessonStatus.failure || state.detail == null
            ? AppErrorView(
                message: learningFailureMessage(
                  state.primaryFailure,
                  fallback: 'Không thể tải tài liệu lúc này.',
                ),
                onRetry: controller.load,
              )
              : Column(
                children: [
                  // 1. Floating Pill PDF Reader Toolbar Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.cardBg(),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: context.cardBorder(),
                          width: 0.8,
                        ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.isDark ? const Color(0xFF143823) : const Color(0xFFEFF5F1),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              'Trang $_currentPage / $_totalPages',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: context.colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 18,
                              color: context.textPrimary(),
                            ),
                            onPressed: () {
                              if (_zoomScale > 0.75) {
                                final newZoom = _zoomScale - 0.25;
                                setState(() => _zoomScale = newZoom);
                                try {
                                  _pdfController.zoomLevel = newZoom;
                                } catch (_) {}
                              }
                            },
                          ),
                          Text(
                            '${(_zoomScale * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: context.textPrimary(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color: context.textPrimary(),
                            ),
                            onPressed: () {
                              if (_zoomScale < 3.0) {
                                final newZoom = _zoomScale + 0.25;
                                setState(() => _zoomScale = newZoom);
                                try {
                                  _pdfController.zoomLevel = newZoom;
                                } catch (_) {}
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Document Reader Panel Canvas with explicit bounds and sleek frame
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSizes.contentMaxWidth,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.cardBg(),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: context.cardBorder(),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: DocumentReaderPanel(part: state.detail!.part),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Bottom Complete Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardBg(),
                      border: Border(
                        top: BorderSide(color: context.cardBorder(), width: 0.8),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            controller.markComplete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã hoàn thành bài đọc!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text(
                            'Đánh dấu đã đọc hoàn thành',
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

bool _isValidId(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
