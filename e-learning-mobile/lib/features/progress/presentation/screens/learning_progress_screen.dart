import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LearningProgressScreen extends StatefulWidget {
  const LearningProgressScreen({super.key});

  @override
  State<LearningProgressScreen> createState() => _LearningProgressScreenState();
}

class _LearningProgressScreenState extends State<LearningProgressScreen> {
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tiến độ học tập',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Circular Gauge Overview Summary Card matching Screen 10
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Circular Progress Gauge
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 110,
                          width: 110,
                          child: CircularProgressIndicator(
                            value: 0.60,
                            strokeWidth: 10,
                            backgroundColor: AppColors.mint,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '60%',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Tổng tiến độ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
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
                        '7 ngày',
                        'Chuỗi liên tục',
                        Icons.local_fire_department_rounded,
                        AppColors.warning,
                      ),
                      Container(height: 36, width: 1, color: AppColors.border),
                      _buildMetricCol(
                        '12 bài',
                        'Bài đã xong',
                        Icons.check_circle_outline_rounded,
                        AppColors.primary,
                      ),
                      Container(height: 36, width: 1, color: AppColors.border),
                      _buildMetricCol(
                        '180 phút',
                        'Tổng giờ học',
                        Icons.timer_outlined,
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 2. Status Filter Pills (Tất cả / Đang học / Hoàn thành)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(0, 'Tất cả (3)'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterChip(1, 'Đang học (2)'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterChip(2, 'Hoàn thành (1)'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Enrolled Courses Progress Cards
            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
              _buildCourseProgressCard(
                context,
                title: 'Nhịn ăn gián đoạn 16/8 cho người mới',
                subtitle: '8/12 bài học · Đang học',
                progress: 0.65,
                courseId: 'course_168',
              ),
              _buildCourseProgressCard(
                context,
                title: 'Thanh lọc cơ thể 7 ngày an toàn',
                subtitle: '2/6 bài học · Đang học',
                progress: 0.33,
                courseId: 'course_detox',
              ),
            ],
            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) ...[
              _buildCourseProgressCard(
                context,
                title: 'Tâm lý học trong nhịn ăn chữa lành',
                subtitle: '15/15 bài học · Đã hoàn thành',
                progress: 1.0,
                courseId: 'course_psychology',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.mint,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : AppColors.sage.withValues(alpha: 0.4),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.mint,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
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
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
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
