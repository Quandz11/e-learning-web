import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/learning_controller.dart';
import 'package:e_learning_mobile/features/progress/presentation/controllers/progress_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LearningProgressScreen extends ConsumerStatefulWidget {
  const LearningProgressScreen({super.key});

  @override
  ConsumerState<LearningProgressScreen> createState() => _LearningProgressScreenState();
}

class _LearningProgressScreenState extends ConsumerState<LearningProgressScreen> {
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressControllerProvider.notifier).load();
      ref.read(learningControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressState = ref.watch(progressControllerProvider);
    final learningState = ref.watch(learningControllerProvider);
    final summary = progressState.summary;

    final overallPercent = summary?.overallProgressPercent ?? 0.0;
    final totalMinutes = summary?.totalMinutesLearned ?? 0;
    final streakDays = summary?.currentStreakDays ?? 0;
    final completedLessons = summary?.completedLessonsCount ?? 0;
    final weeklyStats = summary?.weeklyStudyStats ?? const [];

    final myEnrollments = learningState.enrollments;

    return Scaffold(
      backgroundColor: context.isDark ? context.colorScheme.surface : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tiến độ học tập',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            letterSpacing: -0.3,
            color: context.textPrimary(),
          ),
        ),
        elevation: 0,
        backgroundColor: context.isDark ? context.colorScheme.surface : AppColors.background,
      ),
      body: RefreshIndicator(
        color: context.colorScheme.primary,
        onRefresh: () async {
          await ref.read(progressControllerProvider.notifier).refresh();
          await ref.read(learningControllerProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Circular Gauge Overview Summary Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
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
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Zen Dial Header with Live Status Dot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFF108A55),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF108A55).withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TIẾN ĐỘ TÍCH CỰC',
                          style: TextStyle(
                            letterSpacing: 1.2,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.isDark ? const Color(0xFF143823) : const Color(0xFFF0F5F1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Mục tiêu tuần',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: context.isDark ? context.colorScheme.primary : const Color(0xFF43544B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Circular Progress Zen Dial
                    SizedBox(
                      height: 140,
                      width: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 130,
                            width: 130,
                            child: CircularProgressIndicator(
                              value: (overallPercent / 100.0).clamp(0.0, 1.0),
                              strokeWidth: 4.5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: context.isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFEFF3EE),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.colorScheme.primary,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${overallPercent.toStringAsFixed(0)}%',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -0.5,
                                  color: context.textPrimary(),
                                  fontSize: 32,
                                ),
                              ),
                              Text(
                                'tổng tích lũy',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w300,
                                  color: context.textMuted(),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 3 Metrics Row Below Gauge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(
                          context,
                          '$streakDays ngày',
                          'Chuỗi liên tục',
                          Icons.local_fire_department_rounded,
                          AppColors.warning,
                        ),
                        Container(height: 32, width: 0.8, color: context.cardBorder()),
                        _buildMetricCol(
                          context,
                          '$completedLessons bài',
                          'Bài đã xong',
                          Icons.check_circle_outline_rounded,
                          context.colorScheme.primary,
                        ),
                        Container(height: 32, width: 0.8, color: context.cardBorder()),
                        _buildMetricCol(
                          context,
                          '$totalMinutes phút',
                          'Tổng giờ học',
                          Icons.timer_outlined,
                          Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Divider(height: 1, thickness: 0.8, color: context.cardBorder()),
                    const SizedBox(height: AppSpacing.md),

                    // Weekly Learning Streak Chart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thời gian học tuần này',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary(),
                          ),
                        ),
                        Text(
                          'Mục tiêu: 30p/ngày',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: context.textSecondary(),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: weeklyStats.isNotEmpty
                          ? weeklyStats
                              .map((stat) => _DayStreakBar(
                                    day: stat.dayOfWeek,
                                    minutes: stat.minutesLearned,
                                    isToday: stat.isToday,
                                  ))
                              .toList()
                          : const [
                              _DayStreakBar(day: 'T2', minutes: 0, isToday: false),
                              _DayStreakBar(day: 'T3', minutes: 0, isToday: false),
                              _DayStreakBar(day: 'T4', minutes: 0, isToday: false),
                              _DayStreakBar(day: 'T5', minutes: 0, isToday: false),
                              _DayStreakBar(day: 'T6', minutes: 0, isToday: false),
                              _DayStreakBar(day: 'T7', minutes: 0, isToday: false),
                              _DayStreakBar(day: 'CN', minutes: 0, isToday: false),
                            ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. Status Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, 0, 'Tất cả (${myEnrollments.length})'),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      context,
                      1,
                      'Đang học (${myEnrollments.where((e) => !e.isCompleted).length})',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      context,
                      2,
                      'Hoàn thành (${myEnrollments.where((e) => e.isCompleted).length})',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Dynamic Enrolled Courses Progress Cards
              if (myEnrollments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.cardBg(),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.cardBorder(), width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 40, color: context.textMuted()),
                      const SizedBox(height: 8),
                      Text(
                        'Chưa có khóa học nào',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hãy khám phá các khóa học sức khỏe để bắt đầu!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: context.textMuted(),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...myEnrollments
                    .where((e) {
                      if (_selectedFilterIndex == 1) return !e.isCompleted;
                      if (_selectedFilterIndex == 2) return e.isCompleted;
                      return true;
                    })
                    .map((enrollment) => _buildCourseProgressCard(
                          context,
                          title: enrollment.courseTitle,
                          subtitle: enrollment.isCompleted
                              ? 'Đã hoàn thành 100%'
                              : 'Tiến độ: ${enrollment.progressPercentage}% · Đang học',
                          progress: (enrollment.progressPercentage / 100.0).clamp(0.0, 1.0),
                          courseId: enrollment.courseId,
                        )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: context.colorScheme.primary,
      backgroundColor: context.cardBg(),
      elevation: 0,
      side: BorderSide(
        color: isSelected
            ? context.colorScheme.primary
            : context.cardBorder(),
        width: 0.8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : context.textPrimary(),
        fontWeight: FontWeight.w400,
        fontSize: 13,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedFilterIndex = index;
          });
        }
      },
    );
  }

  Widget _buildMetricCol(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary(),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary(),
            fontWeight: FontWeight.w300,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseProgressCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double progress,
    required String courseId,
  }) {
    final theme = Theme.of(context);
    final percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                    color: context.textPrimary(),
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w300,
              color: context.textSecondary(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: context.isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFEFF5F1),
              valueColor: AlwaysStoppedAnimation(context.colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                context.push(AppRoutes.courseDetailPath(courseId));
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text(
                'Tiếp tục học >',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.primary,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayStreakBar extends StatelessWidget {
  const _DayStreakBar({
    required this.day,
    required this.minutes,
    required this.isToday,
  });

  final String day;
  final int minutes;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    // Max 60 mins for full height (64px)
    final heightRatio = (minutes / 60.0).clamp(0.08, 1.0);
    final barHeight = 64.0 * heightRatio;
    final hasLearned = minutes > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          minutes > 0 ? '${minutes}p' : '-',
          style: TextStyle(
            fontSize: 10,
            fontWeight: isToday ? FontWeight.w500 : FontWeight.w300,
            color: isToday ? context.colorScheme.primary : context.textSecondary(),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 64,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: context.isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFEFF5F1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Container(
            width: 22,
            height: barHeight,
            decoration: BoxDecoration(
              color: isToday
                  ? context.colorScheme.primary
                  : (hasLearned ? (context.isDark ? const Color(0xFF388E3C) : const Color(0xFF68B28B)) : Colors.transparent),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w500 : FontWeight.w400,
            color: isToday ? context.colorScheme.primary : context.textPrimary(),
          ),
        ),
      ],
    );
  }
}
