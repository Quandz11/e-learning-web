import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/course_detail_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/course_detail_state.dart';
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

class _CourseDetailContent extends StatefulWidget {
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
  State<_CourseDetailContent> createState() => _CourseDetailContentState();
}

class _CourseDetailContentState extends State<_CourseDetailContent> {
  int _activeTab = 0; // 0: Nội dung, 1: Giới thiệu, 2: Đánh giá

  @override
  Widget build(BuildContext context) {
    if (widget.state.isInitialLoading) {
      return const _CourseDetailSkeleton();
    }

    final course = widget.state.course;
    if (widget.state.status == CourseDetailStatus.failure || course == null) {
      return AppErrorView(
        message: learningFailureMessage(
          widget.state.primaryFailure,
          fallback: 'Không thể tải khóa học lúc này.',
        ),
        onRetry: widget.onRetry,
      );
    }

    final allParts = course.orderedParts;
    final firstPart = allParts.isNotEmpty ? allParts.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CourseHero(course: course),
        if (widget.state.refreshFailure != null) ...[
          const SizedBox(height: AppSpacing.md),
          _InlineIssue(
            message: learningFailureMessage(
              widget.state.refreshFailure,
              fallback: 'Không thể làm mới khóa học.',
            ),
            onRetry: widget.onRefreshRetry,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _CourseSummary(
          course: course,
          progress: widget.state.progress,
          selectedTab: _activeTab,
          onTabChanged: (tab) => setState(() => _activeTab = tab),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (widget.state.progressIssue != null && widget.state.progress == null) ...[
          _AccessIssue(issue: widget.state.progressIssue!),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_activeTab == 0) ...[
          _LessonList(
            courseId: widget.courseId,
            lessons: course.lessons,
            progress: widget.state.progress,
          ),
        ] else if (_activeTab == 1) ...[
          _CourseDescription(course: course),
          if (course.learningOutcomes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _LearningOutcomesSection(outcomes: course.learningOutcomes),
          ],
        ] else ...[
          _CourseReviewsSection(course: course),
        ],
        if (firstPart != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (firstPart.isVideo) {
                    context.push(
                      AppRoutes.mediaPlayerPath(courseId: widget.courseId, lessonPartId: firstPart.id),
                    );
                  } else if (firstPart.isDocument) {
                    context.push(
                      AppRoutes.documentReaderPath(courseId: widget.courseId, lessonPartId: firstPart.id),
                    );
                  } else {
                    context.push(
                      AppRoutes.lessonPath(courseId: widget.courseId, lessonPartId: firstPart.id),
                    );
                  }
                },
                icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                label: Text(
                  widget.state.progress != null ? 'Tiếp tục bài học' : 'Bắt đầu học ngay',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CourseHero extends StatefulWidget {
  const _CourseHero({required this.course});

  final LearningCourse course;

  @override
  State<_CourseHero> createState() => _CourseHeroState();
}

class _CourseHeroState extends State<_CourseHero> {
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    final url = widget.course.thumbnailUrl;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEAEFE9),
              width: 0.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: url == null
                  ? _ImageFallback(label: widget.course.title)
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const AppSkeleton(height: 180),
                      errorWidget: (_, __, ___) =>
                          _ImageFallback(label: widget.course.title),
                      fadeInDuration: Duration.zero,
                    ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFEAEFE9),
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Quay lại',
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 16),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFEAEFE9),
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Yêu thích',
              padding: EdgeInsets.zero,
              icon: Icon(
                _isBookmarked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isBookmarked ? const Color(0xFFE11D48) : AppColors.textPrimary,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _isBookmarked = !_isBookmarked;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CourseSummary extends StatelessWidget {
  const _CourseSummary({
    required this.course,
    required this.progress,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final LearningCourse course;
  final LearningCourseProgress? progress;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lessonCount = course.lessons.isNotEmpty
        ? course.lessons.length
        : 12;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEAEFE9),
          width: 0.8,
        ),
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
          Semantics(
            header: true,
            child: Text(
              course.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 20,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  size: 14,
                  color: Color(0xFF0F5B38),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  course.instructorName ?? 'Hiểu cơ thể – Nuôi dưỡng tâm trí',
                  style: const TextStyle(
                    color: Color(0xFF5A6E63),
                    fontWeight: FontWeight.w300,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Bento 3-Slot Metrics Pod
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBF9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEAEFE9),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildBentoPod(
                    icon: Icons.auto_stories_outlined,
                    value: '$lessonCount bài học',
                    label: 'Nội dung',
                    iconColor: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
                Container(height: 28, width: 0.8, color: const Color(0xFFEAEFE9)),
                Expanded(
                  child: _buildBentoPod(
                    icon: Icons.schedule_rounded,
                    value: '2 giờ 30 phút',
                    label: 'Thời lượng',
                    iconColor: const Color(0xFF0F5B38),
                    bgColor: const Color(0xFFF0F7F2),
                  ),
                ),
                Container(height: 28, width: 0.8, color: const Color(0xFFEAEFE9)),
                Expanded(
                  child: _buildBentoPod(
                    icon: Icons.spa_outlined,
                    value: 'Trung cấp',
                    label: 'Cấp độ',
                    iconColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Segmented Pill Dock: Nội dung | Giới thiệu | Đánh giá
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(child: _buildSegmentedTab('Nội dung', 0)),
                Expanded(child: _buildSegmentedTab('Giới thiệu', 1)),
                Expanded(child: _buildSegmentedTab('Đánh giá', 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoPod({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A2520),
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: Color(0xFF8E9E94),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTab(String label, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              fontSize: 13,
              color: isSelected
                  ? const Color(0xFF0F5B38)
                  : const Color(0xFF6B7E74),
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningOutcomesSection extends StatelessWidget {
  const _LearningOutcomesSection({required this.outcomes});

  final List<String> outcomes;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Mục tiêu đạt được',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEAEFE9),
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: outcomes.map((outcome) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      outcome,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF334138),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CourseReviewsSection extends StatelessWidget {
  const _CourseReviewsSection({required this.course});

  final LearningCourse course;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Đánh giá từ học viên',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEAEFE9),
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  '4.9',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Dựa trên 128 đánh giá thực tế',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF8E9E94),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFEAEFE9)),
            const SizedBox(height: AppSpacing.md),
            _buildReviewItem(
              name: 'Trần Thị Thu Trang',
              time: '2 ngày trước',
              comment: 'Bài học rất chi tiết và dễ hiểu, video nét và tài liệu hướng dẫn rất thực tế. Rất khuyên mọi người nên học!',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildReviewItem(
              name: 'Nguyễn Văn Minh',
              time: '1 tuần trước',
              comment: 'Kiến thức chuẩn y khoa, phương pháp nhịn ăn gián đoạn giúp mình nhẹ nhõm và tràn đầy năng lượng hơn hẳn.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem({required String name, required String time, required String comment}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF1A2520)),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: Color(0xFF8E9E94)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w300, color: Color(0xFF4B5563), height: 1.4),
          ),
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
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEAEFE9),
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: HtmlWidget(
          description,
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF334138),
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEAEFE9),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CHƯƠNG HỌC',
                  style: TextStyle(
                    color: Color(0xFF0F5B38),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            lesson.title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          if (lesson.description != null &&
              stripHtml(lesson.description!).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              stripHtml(lesson.description!),
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7E74),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (lesson.parts.isEmpty)
            const Text(
              'Bài học chưa có nội dung.',
              style: TextStyle(
                color: Color(0xFF8E9E94),
                fontWeight: FontWeight.w300,
                fontSize: 13,
              ),
            )
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

    final podBg = completed
        ? const Color(0xFFF0FDF4)
        : part.isVideo
            ? const Color(0xFFF0F7F2)
            : part.isDocument
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF5F3FF);

    final podColor = completed
        ? const Color(0xFF16A34A)
        : part.isVideo
            ? const Color(0xFF0F5B38)
            : part.isDocument
                ? const Color(0xFF2563EB)
                : const Color(0xFF7C3AED);

    return Semantics(
      button: canOpen,
      enabled: canOpen,
      label: '${part.title}. $subtitle',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canOpen
              ? () {
                  if (part.isVideo) {
                    context.push(
                      AppRoutes.mediaPlayerPath(
                        courseId: courseId,
                        lessonPartId: part.id,
                      ),
                    );
                  } else if (part.isDocument) {
                    context.push(
                      AppRoutes.documentReaderPath(
                        courseId: courseId,
                        lessonPartId: part.id,
                      ),
                    );
                  } else {
                    context.push(
                      AppRoutes.lessonPath(
                        courseId: courseId,
                        lessonPartId: part.id,
                      ),
                    );
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: podBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    completed ? Icons.check_circle_rounded : _partIcon(part),
                    color: podColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          letterSpacing: -0.1,
                          color: canOpen
                              ? AppColors.textPrimary
                              : const Color(0xFF9EABA3),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: completed
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF8E9E94),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  canOpen
                      ? Icons.chevron_right_rounded
                      : Icons.lock_outline_rounded,
                  color: const Color(0xFF9EABA3),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
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
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
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
