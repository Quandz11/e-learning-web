import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_state.dart';
import 'package:e_learning_mobile/features/learning/presentation/learning_error_messages.dart';
import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    required this.courseId,
    required this.lessonPartId,
    super.key,
  });

  final String courseId;
  final String lessonPartId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isValidId(widget.courseId) && _isValidId(widget.lessonPartId)) {
        ref.read(_provider.notifier).ensureLoaded();
      }
    });
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
      return const SafeArea(
        bottom: false,
        child: AppErrorView(message: 'Không tìm thấy bài học cần hiển thị.'),
      );
    }

    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: _LessonContent(
                  state: state,
                  onRetry: controller.load,
                  onRefreshRetry: controller.refresh,
                  onMarkComplete: controller.markComplete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonContent extends StatelessWidget {
  const _LessonContent({
    required this.state,
    required this.onRetry,
    required this.onRefreshRetry,
    required this.onMarkComplete,
  });

  final LessonState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onRefreshRetry;
  final Future<void> Function() onMarkComplete;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const _LessonSkeleton();
    }

    final detail = state.detail;
    if (state.status == LessonStatus.failure || detail == null) {
      return AppErrorView(
        message: learningFailureMessage(
          state.primaryFailure,
          fallback: 'Không thể tải bài học lúc này.',
        ),
        onRetry: onRetry,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Quay lại',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        _LessonHeader(detail: detail),
        if (state.refreshFailure != null) ...[
          const SizedBox(height: AppSpacing.md),
          _InlineIssue(
            message: learningFailureMessage(
              state.refreshFailure,
              fallback: 'Không thể làm mới bài học.',
            ),
            onRetry: onRefreshRetry,
          ),
        ],
        if (state.completionFailure != null) ...[
          const SizedBox(height: AppSpacing.md),
          _InlineIssue(
            message: learningFailureMessage(
              state.completionFailure,
              fallback: 'Không thể cập nhật tiến độ.',
            ),
            onRetry: onMarkComplete,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _LessonBody(detail: detail),
        const SizedBox(height: AppSpacing.lg),
        _CompletionCard(
          detail: detail,
          isCompleting: state.isCompleting,
          onMarkComplete: onMarkComplete,
        ),
      ],
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.detail});

  final LessonDetailResult detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final part = detail.part;
    final progress = detail.partProgress;
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder(), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest
                      : const Color(0xFFF0F7F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.spa_outlined,
                  size: 13,
                  color: isDark ? colorScheme.primary : const Color(0xFF0F5B38),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detail.course.title,
                  style: textTheme.labelLarge?.copyWith(
                    color: context.textSecondary(),
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              part.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 20,
                letterSpacing: -0.4,
                color: context.textPrimary(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Chip(
                label: Text(_typeLabel(part)),
                backgroundColor: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF0F7F2),
                side: BorderSide(
                  color: isDark
                      ? colorScheme.outlineVariant
                      : const Color(0xFFD1E7DD),
                  width: 0.8,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? colorScheme.primary : const Color(0xFF0F5B38),
                ),
              ),
              if (part.videoDuration > 0)
                Chip(
                  label: Text(_durationLabel(part.videoDuration)),
                  backgroundColor: isDark
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFFEFF6FF),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFBFDBFE),
                    width: 0.8,
                  ),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF2563EB),
                  ),
                ),
              if (part.isPreview)
                Chip(
                  label: const Text('Xem thử'),
                  backgroundColor: isDark
                      ? const Color(0xFF78350F)
                      : const Color(0xFFFFFBEB),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFFDE68A),
                    width: 0.8,
                  ),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD97706),
                  ),
                ),
              if (progress?.isCompleted == true)
                Chip(
                  label: const Text('Đã hoàn thành'),
                  backgroundColor: isDark
                      ? const Color(0xFF064E3B)
                      : const Color(0xFFF0FDF4),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFBBF7D0),
                    width: 0.8,
                  ),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF16A34A),
                  ),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.cardBorder(), width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(
                    progress.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    size: 14,
                    color: progress.isCompleted
                        ? const Color(0xFF16A34A)
                        : context.textMuted(),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      progress.isCompleted
                          ? 'Bạn đã hoàn thành nội dung này.'
                          : 'Thời lượng đã xem: ${progress.watchedDuration} giây',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: context.textSecondary(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonBody extends StatelessWidget {
  const _LessonBody({required this.detail});

  final LessonDetailResult detail;

  @override
  Widget build(BuildContext context) {
    final part = detail.part;
    final content = part.content;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder(), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content != null && stripHtml(content).isNotEmpty) ...[
            HtmlWidget(
              content,
              textStyle: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: context.textPrimary(),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (part.isVideo) _OpenMediaButton(detail: detail),
          if (part.isDocument) _OpenDocumentButton(detail: detail),
          if (!part.isVideo &&
              !part.isDocument &&
              (content == null || stripHtml(content).isEmpty))
            Text(
              'Nội dung này chưa được hỗ trợ trên ứng dụng.',
              style: TextStyle(
                color: context.textMuted(),
                fontWeight: FontWeight.w300,
                fontSize: 13,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          _LessonNavigation(detail: detail),
        ],
      ),
    );
  }
}

class _OpenMediaButton extends StatelessWidget {
  const _OpenMediaButton({required this.detail});

  final LessonDetailResult detail;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Mở trình phát video',
      icon: const Icon(Icons.play_circle_outline_rounded),
      onPressed: () => context.push(
        AppRoutes.mediaPlayerPath(
          courseId: detail.course.id,
          lessonPartId: detail.part.id,
        ),
      ),
    );
  }
}

class _OpenDocumentButton extends StatelessWidget {
  const _OpenDocumentButton({required this.detail});

  final LessonDetailResult detail;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Đọc tài liệu',
      icon: const Icon(Icons.description_outlined),
      onPressed: () => context.push(
        AppRoutes.documentReaderPath(
          courseId: detail.course.id,
          lessonPartId: detail.part.id,
        ),
      ),
    );
  }
}

class _LessonNavigation extends StatelessWidget {
  const _LessonNavigation({required this.detail});

  final LessonDetailResult detail;

  @override
  Widget build(BuildContext context) {
    final parts = detail.course.orderedParts;
    final currentIndex = parts.indexWhere((part) => part.id == detail.part.id);
    if (currentIndex == -1 || parts.length <= 1) {
      return const SizedBox.shrink();
    }

    final previous = currentIndex > 0 ? parts[currentIndex - 1] : null;
    final next = currentIndex < parts.length - 1
        ? parts[currentIndex + 1]
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Text(
          'Điều hướng bài học',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: previous == null
                    ? null
                    : () => _openPart(context, previous),
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Bài trước'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: next == null ? null : () => _openPart(context, next),
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Bài tiếp'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openPart(BuildContext context, LearningLessonPart part) {
    context.pushReplacement(
      AppRoutes.lessonPath(courseId: detail.course.id, lessonPartId: part.id),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({
    required this.detail,
    required this.isCompleting,
    required this.onMarkComplete,
  });

  final LessonDetailResult detail;
  final bool isCompleting;
  final Future<void> Function() onMarkComplete;

  @override
  Widget build(BuildContext context) {
    final completed = detail.partProgress?.isCompleted == true;
    if (detail.progress == null && detail.part.isPreview) {
      return const AppCard(
        child: Text(
          'Đây là nội dung xem thử. Tiến độ chỉ cập nhật khi bạn có quyền truy cập khóa học.',
        ),
      );
    }

    if (completed) {
      return const AppCard(
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Nội dung này đã được đánh dấu hoàn thành.')),
          ],
        ),
      );
    }

    return AppCard(
      child: AppButton(
        label: 'Đánh dấu hoàn thành',
        loading: isCompleting,
        onPressed: detail.canMarkComplete ? () => onMarkComplete() : null,
      ),
    );
  }
}

class _InlineIssue extends StatelessWidget {
  const _InlineIssue({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Thử lại',
            fullWidth: false,
            onPressed: () => onRetry(),
          ),
        ],
      ),
    );
  }
}

class _LessonSkeleton extends StatelessWidget {
  const _LessonSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 180, height: 20),
              SizedBox(height: AppSpacing.sm),
              AppSkeleton(width: 240, height: 28),
              SizedBox(height: AppSpacing.md),
              AppSkeleton(width: 120),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        AppCard(child: AppSkeleton(height: 180)),
      ],
    );
  }
}

String _typeLabel(LearningLessonPart part) {
  if (part.isVideo) {
    return 'Video';
  }
  if (part.isDocument) {
    return 'Tài liệu';
  }
  return part.type;
}

String _durationLabel(double seconds) {
  final minutes = (seconds / 60).ceil();
  return '$minutes phút';
}

bool _isValidId(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
