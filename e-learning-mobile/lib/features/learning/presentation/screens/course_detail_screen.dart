import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/course_detail_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/course_detail_state.dart';
import 'package:e_learning_mobile/features/learning/presentation/learning_error_messages.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_empty_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({required this.courseId, super.key});

  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isValidId(widget.courseId)) {
        ref
            .read(courseDetailControllerProvider(widget.courseId).notifier)
            .ensureLoaded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidId(widget.courseId)) {
      return const SafeArea(
        bottom: false,
        child: AppErrorView(message: 'Không tìm thấy khóa học cần hiển thị.'),
      );
    }

    final provider = courseDetailControllerProvider(widget.courseId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

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
                child: _CourseDetailContent(
                  state: state,
                  courseId: widget.courseId,
                  onRetry: controller.load,
                  onRefreshRetry: controller.refresh,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseDetailContent extends StatelessWidget {
  const _CourseDetailContent({
    required this.state,
    required this.courseId,
    required this.onRetry,
    required this.onRefreshRetry,
  });

  final CourseDetailState state;
  final String courseId;
  final Future<void> Function() onRetry;
  final Future<void> Function() onRefreshRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const _CourseDetailSkeleton();
    }

    final course = state.course;
    if (state.status == CourseDetailStatus.failure || course == null) {
      return AppErrorView(
        message: learningFailureMessage(
          state.primaryFailure,
          fallback: 'Không thể tải khóa học lúc này.',
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
        _CourseHero(course: course),
        if (state.refreshFailure != null) ...[
          const SizedBox(height: AppSpacing.md),
          _InlineIssue(
            message: learningFailureMessage(
              state.refreshFailure,
              fallback: 'Không thể làm mới khóa học.',
            ),
            onRetry: onRefreshRetry,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _CourseSummary(course: course, progress: state.progress),
        const SizedBox(height: AppSpacing.lg),
        if (state.progressIssue != null && state.progress == null)
          _AccessIssue(issue: state.progressIssue!),
        if (state.progressIssue != null && state.progress == null)
          const SizedBox(height: AppSpacing.lg),
        _CourseDescription(course: course),
        const SizedBox(height: AppSpacing.lg),
        _LessonList(
          courseId: courseId,
          lessons: course.lessons,
          progress: state.progress,
        ),
      ],
    );
  }
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course});

  final LearningCourse course;

  @override
  Widget build(BuildContext context) {
    final url = course.thumbnailUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: url == null
            ? _ImageFallback(label: course.title)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => const AppSkeleton(height: 180),
                errorWidget: (_, __, ___) =>
                    _ImageFallback(label: course.title),
                fadeInDuration: Duration.zero,
                memCacheWidth: 720,
                maxWidthDiskCache: 1080,
              ),
      ),
    );
  }
}

class _CourseSummary extends StatelessWidget {
  const _CourseSummary({required this.course, required this.progress});

  final LearningCourse course;
  final LearningCourseProgress? progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final courseProgress = progress;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(course.title, style: textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(
                icon: Icons.sell_outlined,
                label: course.isFree ? 'Miễn phí' : 'Khóa học trả phí',
              ),
              if (course.instructorName != null)
                _InfoChip(
                  icon: Icons.person_outline_rounded,
                  label: course.instructorName!,
                ),
              if (course.defaultAccessDurationDays != null)
                _InfoChip(
                  icon: Icons.event_available_outlined,
                  label: 'Truy cập ${course.defaultAccessDurationDays} ngày',
                ),
            ],
          ),
          if (courseProgress != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Tiến độ học tập', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              label:
                  'Đã hoàn thành ${courseProgress.progressPercentage} phần trăm',
              child: LinearProgressIndicator(
                value: courseProgress.progressPercentage / 100,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Đã hoàn thành ${courseProgress.completedParts}/${courseProgress.totalParts} nội dung',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CourseDescription extends StatelessWidget {
  const _CourseDescription({required this.course});

  final LearningCourse course;

  @override
  Widget build(BuildContext context) {
    final description = course.description;
    if (description == null || stripHtml(description).isEmpty) {
      return const SizedBox.shrink();
    }

    return _Section(
      title: 'Giới thiệu khóa học',
      child: AppCard(child: HtmlWidget(description)),
    );
  }
}

class _LessonList extends StatelessWidget {
  const _LessonList({
    required this.courseId,
    required this.lessons,
    required this.progress,
  });

  final String courseId;
  final List<LearningLesson> lessons;
  final LearningCourseProgress? progress;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return const _Section(
        title: 'Nội dung khóa học',
        child: AppEmptyView(message: 'Khóa học chưa có nội dung hiển thị.'),
      );
    }

    return _Section(
      title: 'Nội dung khóa học',
      child: Column(
        children: lessons
            .map(
              (lesson) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _LessonGroup(
                  courseId: courseId,
                  lesson: lesson,
                  progress: progress,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _LessonGroup extends StatelessWidget {
  const _LessonGroup({
    required this.courseId,
    required this.lesson,
    required this.progress,
  });

  final String courseId;
  final LearningLesson lesson;
  final LearningCourseProgress? progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lesson.title, style: textTheme.titleMedium),
          if (lesson.description != null &&
              stripHtml(lesson.description!).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(stripHtml(lesson.description!), style: textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (lesson.parts.isEmpty)
            const Text('Bài học chưa có nội dung.')
          else
            ...lesson.parts.map(
              (part) => _LessonPartTile(
                courseId: courseId,
                part: part,
                progress: progress?.progressFor(part.id),
                canOpen: progress != null || part.isPreview,
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonPartTile extends StatelessWidget {
  const _LessonPartTile({
    required this.courseId,
    required this.part,
    required this.progress,
    required this.canOpen,
  });

  final String courseId;
  final LearningLessonPart part;
  final LearningLessonProgress? progress;
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    final completed = progress?.isCompleted == true;
    final subtitle = [
      _typeLabel(part),
      if (part.videoDuration > 0) _durationLabel(part.videoDuration),
      if (part.isPreview) 'Xem thử',
      if (completed) 'Đã hoàn thành',
      if (!canOpen) 'Chưa có quyền truy cập',
    ].join(' • ');

    return Semantics(
      button: canOpen,
      enabled: canOpen,
      label: '${part.title}. $subtitle',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(completed ? Icons.check_circle : _partIcon(part)),
        title: Text(part.title),
        subtitle: Text(subtitle),
        enabled: canOpen,
        trailing: canOpen
            ? const Icon(Icons.chevron_right_rounded)
            : const Icon(Icons.lock_outline_rounded),
        onTap: canOpen
            ? () => context.push(
                AppRoutes.lessonPath(courseId: courseId, lessonPartId: part.id),
              )
            : null,
      ),
    );
  }
}

class _AccessIssue extends StatelessWidget {
  const _AccessIssue({required this.issue});

  final LearningSectionIssue issue;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              learningFailureMessage(
                issue.failure,
                fallback: 'Bạn chưa có quyền truy cập tiến độ khóa học.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
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

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
      child: Center(
        child: Semantics(
          label: 'Hình minh họa mặc định cho $label',
          child: Icon(
            Icons.menu_book_outlined,
            color: colorScheme.onSurfaceVariant,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _CourseDetailSkeleton extends StatelessWidget {
  const _CourseDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSkeleton(height: 180),
        SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 220, height: 26),
              SizedBox(height: AppSpacing.sm),
              AppSkeleton(width: 180),
              SizedBox(height: AppSpacing.md),
              AppSkeleton(height: 8),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        AppCard(child: AppSkeleton(height: 120)),
      ],
    );
  }
}

IconData _partIcon(LearningLessonPart part) {
  if (part.isVideo) {
    return Icons.play_circle_outline_rounded;
  }
  if (part.isDocument) {
    return Icons.description_outlined;
  }
  return Icons.article_outlined;
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
