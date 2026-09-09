import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/learning_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/learning_state.dart';
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
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learningControllerProvider.notifier).ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningControllerProvider);
    final controller = ref.read(learningControllerProvider.notifier);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _LearningContent(
                    state: state,
                    onRetry: controller.load,
                    onSectionRetry: controller.refresh,
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

class _LearningContent extends StatelessWidget {
  const _LearningContent({
    required this.state,
    required this.onRetry,
    required this.onSectionRetry,
  });

  final LearningState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onSectionRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const _LearningLoadingSkeleton();
    }

    if (state.status == LearningStatus.failure && !state.hasLoadedContent) {
      return AppErrorView(
        message: _toVietnameseMessage(
          state.primaryFailure,
          fallback: 'Không thể tải nội dung học tập lúc này.',
        ),
        onRetry: onRetry,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LearningHeader(),
        if (state.refreshFailure != null) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionErrorCard(
            message: _toVietnameseMessage(
              state.refreshFailure,
              fallback: 'Không thể làm mới nội dung học tập.',
            ),
            onRetry: onSectionRetry,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _MyLearningSection(
          enrollments: state.enrollments,
          issue: state.enrollmentIssue,
          onRetry: onSectionRetry,
        ),
        if (state.categories.isNotEmpty || state.categoryIssue != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _CategoriesSection(
            categories: state.categories,
            issue: state.categoryIssue,
            onRetry: onSectionRetry,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _CourseCatalogSection(courses: state.courses),
      ],
    );
  }
}

class _LearningHeader extends StatelessWidget {
  const _LearningHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text('Học tập', style: textTheme.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tiếp tục hành trình học tập của bạn.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(Icons.school_rounded, color: colorScheme.primary, size: 40),
        ],
      ),
    );
  }
}

class _MyLearningSection extends StatelessWidget {
  const _MyLearningSection({
    required this.enrollments,
    required this.issue,
    required this.onRetry,
  });

  final List<LearningEnrollment> enrollments;
  final LearningSectionIssue? issue;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (issue != null && enrollments.isEmpty) {
      return _SectionWrapper(
        title: 'Khóa học của tôi',
        child: _SectionErrorCard(
          message: _toVietnameseMessage(
            issue!.failure,
            fallback: 'Không thể tải khóa học của bạn.',
          ),
          onRetry: onRetry,
        ),
      );
    }

    return _SectionWrapper(
      title: 'Khóa học của tôi',
      child: enrollments.isEmpty
          ? const AppEmptyView(
              message:
                  'Bạn chưa đăng ký khóa học nào. Khám phá các khóa học phù hợp với bạn bên dưới.',
            )
          : Column(
              children: enrollments
                  .map(
                    (enrollment) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _EnrollmentCard(enrollment: enrollment),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({
    required this.categories,
    required this.issue,
    required this.onRetry,
  });

  final List<LearningCategory> categories;
  final LearningSectionIssue? issue;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'Danh mục',
      child: categories.isNotEmpty
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppSpacing.sm,
                        ),
                        child: Semantics(
                          label: 'Danh mục ${category.name}',
                          child: Chip(label: Text(category.name)),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            )
          : _SectionErrorCard(
              message: _toVietnameseMessage(
                issue!.failure,
                fallback: 'Không thể tải danh mục lúc này.',
              ),
              onRetry: onRetry,
            ),
    );
  }
}

class _CourseCatalogSection extends StatelessWidget {
  const _CourseCatalogSection({required this.courses});

  final List<LearningCourse> courses;

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'Khóa học hiện có',
      child: courses.isEmpty
          ? const AppEmptyView(
              message: 'Chưa có khóa học phù hợp. Vui lòng quay lại sau.',
            )
          : Column(
              children: courses
                  .map(
                    (course) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _LearningCourseCard(course: course),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({required this.enrollment});

  final LearningEnrollment enrollment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = enrollment.progressPercentage / 100;

    return Semantics(
      container: true,
      label:
          'Khóa học ${enrollment.courseTitle}. Đã hoàn thành ${enrollment.progressPercentage} phần trăm.',
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CourseImage(
              imageUrl: enrollment.courseThumbnail,
              label: enrollment.courseTitle,
              fallbackIcon: Icons.play_lesson_outlined,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enrollment.courseTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _enrollmentStatusLabel(enrollment),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Đã hoàn thành ${enrollment.progressPercentage}%',
                    style: textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    value:
                        'Đã hoàn thành ${enrollment.progressPercentage} phần trăm',
                    child: LinearProgressIndicator(value: progress),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Truy cập gần nhất ${_dateFormatter.format(enrollment.lastAccessedAt.toLocal())}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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

class _LearningCourseCard extends StatelessWidget {
  const _LearningCourseCard({required this.course});

  final LearningCourse course;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final description = course.description == null
        ? null
        : _stripHtml(course.description!);

    return Semantics(
      container: true,
      label: 'Khóa học ${course.title}',
      child: AppCard(
        onTap: () => context.push(AppRoutes.courseDetailPath(course.id)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CourseImage(
              imageUrl: course.thumbnailUrl,
              label: course.title,
              fallbackIcon: Icons.menu_book_outlined,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _StatusChip(
                        label: course.isFree ? 'Miễn phí' : 'Khóa học trả phí',
                        color: course.isFree
                            ? colorScheme.primary
                            : colorScheme.tertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    course.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  if (course.instructorName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      course.instructorName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                  if (course.defaultAccessDurationDays != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Thời hạn truy cập ${course.defaultAccessDurationDays} ngày',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CourseImage extends StatelessWidget {
  const _CourseImage({
    required this.imageUrl,
    required this.label,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final String label;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 112,
        height: 84,
        child: url == null || url.isEmpty
            ? _ImageFallback(icon: fallbackIcon, label: label)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const AppSkeleton(width: 112, height: 84),
                errorWidget: (_, __, ___) =>
                    _ImageFallback(icon: fallbackIcon, label: label),
                fadeInDuration: Duration.zero,
                memCacheWidth: 224,
                maxWidthDiskCache: 448,
              ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
      child: Center(
        child: Semantics(
          label: 'Hình minh họa mặc định cho $label',
          child: Icon(icon, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _SectionWrapper extends StatelessWidget {
  const _SectionWrapper({required this.title, required this.child});

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

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard({required this.message, required this.onRetry});

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

class _LearningLoadingSkeleton extends StatelessWidget {
  const _LearningLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 120, height: 28),
              SizedBox(height: AppSpacing.sm),
              AppSkeleton(width: 240),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        AppSkeleton(width: 140, height: 20),
        SizedBox(height: AppSpacing.md),
        AppCard(child: AppSkeleton(height: 120)),
        SizedBox(height: AppSpacing.lg),
        AppSkeleton(width: 160, height: 20),
        SizedBox(height: AppSpacing.md),
        AppCard(child: AppSkeleton(height: 120)),
      ],
    );
  }
}

String _enrollmentStatusLabel(LearningEnrollment enrollment) {
  if (enrollment.isCompleted) {
    return 'Đã hoàn thành';
  }
  if (enrollment.isExpired) {
    return 'Đã hết hạn truy cập';
  }
  if (enrollment.accessExpiresAt != null) {
    return 'Truy cập đến ${_dateFormatter.format(enrollment.accessExpiresAt!.toLocal())}';
  }
  return 'Đang học';
}

String _toVietnameseMessage(AppFailure? failure, {required String fallback}) {
  return learningFailureMessage(failure, fallback: fallback);
}

String _stripHtml(String value) {
  return stripHtml(value);
}

final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
