import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/learning_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/learning_state.dart';
import 'package:e_learning_mobile/features/learning/presentation/learning_error_messages.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
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

class _LearningContent extends StatefulWidget {
  const _LearningContent({
    required this.state,
    required this.onRetry,
    required this.onSectionRetry,
  });

  final LearningState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onSectionRetry;

  @override
  State<_LearningContent> createState() => _LearningContentState();
}

class _LearningContentState extends State<_LearningContent> {
  int _filterIndex = 0; // 0: Tất cả, 1: Đang học, 2: Đã hoàn thành

  @override
  Widget build(BuildContext context) {
    if (widget.state.isInitialLoading) {
      return const _LearningLoadingSkeleton();
    }

    if (widget.state.status == LearningStatus.failure &&
        !widget.state.hasLoadedContent) {
      return AppErrorView(
        message: _toVietnameseMessage(
          widget.state.primaryFailure,
          fallback: 'Không thể tải nội dung học tập lúc này.',
        ),
        onRetry: widget.onRetry,
      );
    }

    final allEnrollments = widget.state.enrollments;
    final filteredEnrollments = allEnrollments.where((e) {
      if (_filterIndex == 1) return !e.isCompleted;
      if (_filterIndex == 2) return e.isCompleted;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LearningHeader(),
        if (widget.state.refreshFailure != null) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionErrorCard(
            message: _toVietnameseMessage(
              widget.state.refreshFailure,
              fallback: 'Không thể làm mới nội dung học tập.',
            ),
            onRetry: widget.onSectionRetry,
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tất cả', 0),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip('Đang học', 1),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip('Đã hoàn thành', 2),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        _MyLearningSection(
          enrollments: filteredEnrollments,
          issue: widget.state.enrollmentIssue,
          onRetry: widget.onSectionRetry,
        ),
        if (widget.state.categories.isNotEmpty ||
            widget.state.categoryIssue != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _CategoriesSection(
            categories: widget.state.categories,
            issue: widget.state.categoryIssue,
            onRetry: widget.onSectionRetry,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _CourseCatalogSection(courses: widget.state.courses),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final selected = _filterIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: colorScheme.surface,
      elevation: selected ? 2 : 0,
      shadowColor: AppColors.primary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: TextStyle(
        color: selected ? Colors.white : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _filterIndex = index;
          });
        }
      },
    );
  }
}

class _LearningHeader extends StatelessWidget {
  const _LearningHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Quay lại',
          onPressed: () => context.go(AppRoutes.appHome),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const Expanded(
          child: Text(
            'Khóa học',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 48),
      ],
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
    final progress = (enrollment.progressPercentage / 100).clamp(0.0, 1.0);
    final isDone = enrollment.isCompleted;

    return Semantics(
      container: true,
      label:
          'Khóa học ${enrollment.courseTitle}. Đã hoàn thành ${enrollment.progressPercentage} phần trăm.',
      child: AppCard(
        onTap: () => context.push(AppRoutes.courseDetailPath(enrollment.courseId)),
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
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.mint
                          : AppColors.primaryLight.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      _enrollmentStatusLabel(enrollment),
                      style: textTheme.labelSmall?.copyWith(
                        color: isDone ? AppColors.success : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Truy cập: ${_dateFormatter.format(enrollment.lastAccessedAt.toLocal())}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDone ? AppColors.success : AppColors.primary,
                      ),
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
    final lessonCount = course.lessons.isNotEmpty ? course.lessons.length : 12;

    return Semantics(
      container: true,
      label: 'Khóa học ${course.title}',
      child: AppCard(
        onTap: () => context.push(AppRoutes.courseDetailPath(course.id)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$lessonCount bài học',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
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

final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
