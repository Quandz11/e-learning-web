import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/running/presentation/controllers/running_controller.dart';
import 'package:e_learning_mobile/features/running/presentation/widgets/log_manual_run_sheet.dart';
import 'package:e_learning_mobile/features/running/presentation/widgets/running_history_item.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_empty_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RunningScreen extends ConsumerWidget {
  const RunningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(runningControllerProvider);
    final controller = ref.read(runningControllerProvider.notifier);
    final summary = state.summary;
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Hoạt động Chạy bộ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nhập buổi chạy',
            onPressed: () => LogManualRunSheet.show(context),
          ),
        ],
      ),
      body: state.isLoading && state.activities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.activities.isEmpty
              ? AppErrorView(
                  message: state.errorMessage!,
                  onRetry: controller.load,
                )
              : RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Total Accumulation Hero Card
                      _buildAccumulatedHeroCard(context, summary, isDark),
                      const SizedBox(height: AppSpacing.md),

                      // 4 Metric Grid
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Tuần này',
                              value: '${summary.weekDistanceKm.toStringAsFixed(1)} km',
                              icon: Icons.calendar_view_week_rounded,
                              iconColor: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              label: 'Tháng này',
                              value: '${summary.monthDistanceKm.toStringAsFixed(1)} km',
                              icon: Icons.calendar_month_rounded,
                              iconColor: const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Số buổi chạy',
                              value: '${summary.totalRunsCount}',
                              icon: Icons.repeat_rounded,
                              iconColor: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              label: 'Pace trung bình',
                              value: summary.averagePaceFormatted,
                              icon: Icons.speed_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push(AppRoutes.liveRun),
                              icon: const Icon(Icons.play_arrow_rounded, size: 22),
                              label: const Text(
                                'Bắt đầu chạy GPS',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () => LogManualRunSheet.show(context),
                              icon: const Icon(Icons.edit_note_rounded, size: 20),
                              label: const Text('Nhập km'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: colorScheme.primary.withValues(alpha: 0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lịch sử hoạt động',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary(),
                            ),
                          ),
                          Text(
                            '${state.totalCount} buổi',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textMuted(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // History list
                      if (state.activities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: AppEmptyView(
                            message: 'Chưa có buổi chạy nào.\nHãy bắt đầu buổi chạy GPS hoặc nhập số km để theo dõi hành trình!',
                          ),
                        )
                      else
                        ...state.activities.map(
                          (act) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: RunningHistoryItem(
                              activity: act,
                              onDelete: () => controller.deleteRun(act.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAccumulatedHeroCard(BuildContext context, dynamic summary, bool isDark) {
    final totalKm = summary.totalDistanceKm as double;
    final longestKm = summary.longestRunKm as double;
    final totalCal = summary.totalCalories as int;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF064E3B), const Color(0xFF0F766E)]
              : [const Color(0xFF059669), const Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG QUÃNG ĐƯỜNG TÍCH LŨY',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 13, color: Colors.amberAccent),
                    const SizedBox(width: 2),
                    Text(
                      '${summary.currentStreakDays} ngày liên tiếp',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                totalKm.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'km',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kỷ lục xa nhất: ${longestKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                'Đã đốt: $totalCal kcal',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textMuted(),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
