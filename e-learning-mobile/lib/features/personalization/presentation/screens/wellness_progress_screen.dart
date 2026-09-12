import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WellnessProgressScreen extends ConsumerStatefulWidget {
  const WellnessProgressScreen({super.key});

  @override
  ConsumerState<WellnessProgressScreen> createState() =>
      _WellnessProgressScreenState();
}

class _WellnessProgressScreenState
    extends ConsumerState<WellnessProgressScreen> {
  int _activeTabIndex = 0; // 0: Nhật ký 30 ngày, 1: Tổng quan & Cân nặng

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(wellnessControllerProvider.notifier).loadTimeline(days: 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessControllerProvider);
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: Text(
          'Nhật ký & Tiến trình',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: -0.3,
            color: context.textPrimary(),
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FBF9),
        iconTheme: IconThemeData(color: context.textPrimary()),
      ),
      body: Column(
        children: [
          // iOS Segmented Floating Switcher
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      label: 'Nhật ký 30 ngày',
                      icon: Icons.calendar_today_outlined,
                      isActive: _activeTabIndex == 0,
                      onTap: () => setState(() => _activeTabIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      label: 'Mục tiêu Cân nặng',
                      icon: Icons.show_chart_rounded,
                      isActive: _activeTabIndex == 1,
                      onTap: () => setState(() => _activeTabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : _activeTabIndex == 0
                    ? _buildTimelineView(context, state)
                    : _buildWeightOverviewView(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? context.colorScheme.surfaceContainerHigh : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38))
                  : context.textSecondary(),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isActive ? context.textPrimary() : context.textSecondary(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView(BuildContext context, WellnessState state) {
    final timelineItems = state.timeline?.items ?? [];
    final isDark = context.isDark;

    if (timelineItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 26,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có dữ liệu nhật ký',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: context.textPrimary(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy check-in hằng ngày để hệ thống theo dõi lộ trình của bạn.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: context.textSecondary(),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: timelineItems.length,
      itemBuilder: (context, index) {
        final item = timelineItems[index];
        final isLast = index == timelineItems.length - 1;
        return _buildTimelineRow(context, item, isLast);
      },
    );
  }

  Widget _buildTimelineRow(
    BuildContext context,
    WellnessProgressTimelineItem item,
    bool isLast,
  ) {
    final formattedDate =
        '${item.logDate.day.toString().padLeft(2, '0')}/${item.logDate.month.toString().padLeft(2, '0')}';
    final isDark = context.isDark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Connector Column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.hasCheckin
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38))
                        : (isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFD1D5DB)),
                    border: Border.all(
                      color: isDark ? context.colorScheme.surface : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: isDark ? context.colorScheme.outlineVariant : const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.cardBg(),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: context.cardBorder(),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary(),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.hasCheckin
                              ? context.chipBg(false)
                              : (isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.hasCheckin ? 'Đã ghi nhận' : 'Trống',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: item.hasCheckin
                                ? context.chipText(false)
                                : context.textMuted(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _buildMiniMetric(
                        context,
                        icon: Icons.local_drink_rounded,
                        color: const Color(0xFF0284C7),
                        value: '${item.waterMl} ml',
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _buildMiniMetric(
                        context,
                        icon: Icons.directions_run_rounded,
                        color: const Color(0xFFD97706),
                        value: '${item.workoutMinutes}p',
                      ),
                      if (item.currentWeightKg != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        _buildMiniMetric(
                          context,
                          icon: Icons.scale_rounded,
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
                          value: '${item.currentWeightKg} kg',
                        ),
                      ],
                    ],
                  ),
                  if (item.phase.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${item.phase} • Ngày ${item.phaseDayIndex}/${item.phaseTotalDays}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: context.textMuted(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: context.textPrimary(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightOverviewView(BuildContext context, WellnessState state) {
    final weightProg = state.dashboard?.weightProgress;
    final startWeight = weightProg?.startWeightKg ?? 65.0;
    final currentWeight = weightProg?.currentWeightKg ?? startWeight;
    final targetWeight = weightProg?.targetWeightKg ?? 60.0;
    final progressPercent = weightProg?.progressPercent ?? 0.0;
    final delta = currentWeight - startWeight;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trajectory Summary Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.cardBg(),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: context.cardBorder(),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lộ trình Cân nặng',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: delta <= 0
                            ? context.chipBg(false)
                            : (isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        delta <= 0
                            ? '${delta.toStringAsFixed(1)} kg'
                            : '+${delta.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: delta <= 0
                              ? context.chipText(false)
                              : (isDark ? const Color(0xFFF87171) : Colors.red[700]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWeightStatColumn(context, 'Bắt đầu', '$startWeight kg'),
                    Container(
                      width: 1,
                      height: 32,
                      color: context.cardBorder(),
                    ),
                    _buildWeightStatColumn(
                      context,
                      'Hiện tại',
                      '$currentWeight kg',
                      isHighlight: true,
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: context.cardBorder(),
                    ),
                    _buildWeightStatColumn(context, 'Mục tiêu', '$targetWeight kg'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (progressPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Đạt ${progressPercent.toStringAsFixed(0)}% mục tiêu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: context.textSecondary(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Guidance Note
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFF9FBF9),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: context.cardBorder(),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.spa_outlined,
                  size: 20,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Cân nặng có thể dao động 0.5 - 1kg mỗi ngày do lượng nước. Hãy kiên trì đo vào cùng một khung giờ mỗi sáng sau khi thức dậy.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: context.textSecondary(),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStatColumn(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    final isDark = context.isDark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: context.textSecondary(),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            color: isHighlight
                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38))
                : context.textPrimary(),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

