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
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
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

    return Scaffold(
      backgroundColor: context.isDark ? context.colorScheme.surface : const Color(0xFFFBFBFA),
      body: SafeArea(
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
        // 1. Bento Learning Overview Strip (3 metrics like Personalize)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: context.cardBg(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.cardBorder(),
              width: 0.8,
            ),
            boxShadow: context.isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildBentoMetricCol(
                  context: context,
                  label: 'Đang học',
                  value: '${allEnrollments.where((e) => !e.isCompleted).length}',
                  unit: 'khóa',
                  icon: Icons.auto_stories_outlined,
                  color: context.isDark ? context.colorScheme.primary : const Color(0xFF0F5B38),
                  bgColor: context.isDark ? context.colorScheme.surfaceContainerLow : const Color(0xFFF0F7F2),
                ),
              ),
              Container(height: 36, width: 0.8, color: context.cardBorder()),
              Expanded(
                child: _buildBentoMetricCol(
                  context: context,
                  label: 'Hoàn thành',
                  value: '${allEnrollments.where((e) => e.isCompleted).length}',
                  unit: 'khóa',
                  icon: Icons.verified_outlined,
                  color: const Color(0xFF108A55),
                  bgColor: context.isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFEDF7F1),
                ),
              ),
              Container(height: 36, width: 0.8, color: context.cardBorder()),
              Expanded(
                child: _buildBentoMetricCol(
                  context: context,
                  label: 'Hiện có',
                  value: '${widget.state.courses.length}',
                  unit: 'khóa',
                  icon: Icons.explore_outlined,
                  color: const Color(0xFF2563EB),
                  bgColor: context.isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFEFF6FF),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Status Filter Chips
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
    final isDark = context.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : context.cardBorder(),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : (isDark ? colorScheme.onSurface : colorScheme.onSurfaceVariant),
        fontWeight: FontWeight.w400,
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

  Widget _buildBentoMetricCol({
    required BuildContext context,
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary(),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: context.textMuted(),
                ),
              ),
            ],
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              color: context.textSecondary(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningHeader extends StatelessWidget {
  const _LearningHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'Khóa học',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: context.textPrimary(),
          letterSpacing: -0.4,
        ),
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
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDone
                          ? (context.isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFF0FDF4))
                          : (context.isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFF0F7F2)),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isDone
                            ? (context.isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0))
                            : context.cardBorder(),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _enrollmentStatusLabel(enrollment),
                      style: textTheme.labelSmall?.copyWith(
                        color: isDone
                            ? (context.isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
                            : (context.isDark ? context.colorScheme.primary : AppColors.primary),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: context.textMuted(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Gần nhất: ${_dateFormatter.format(enrollment.lastAccessedAt.toLocal())}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: context.textSecondary(),
                            fontWeight: FontWeight.w300,
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
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$lessonCount bài học',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w300,
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
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
        ),
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
