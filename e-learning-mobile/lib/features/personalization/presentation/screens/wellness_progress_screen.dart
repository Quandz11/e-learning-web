import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WellnessProgressScreen extends ConsumerStatefulWidget {
  const WellnessProgressScreen({super.key});

  @override
  ConsumerState<WellnessProgressScreen> createState() =>
      _WellnessProgressScreenState();
}

class _WellnessProgressScreenState
    extends ConsumerState<WellnessProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(wellnessControllerProvider.notifier).loadTimeline(days: 30);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Nhật ký Tiến trình 30 Ngày',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.history_rounded),
              text: 'Nhật ký 30 ngày',
            ),
            Tab(
              icon: Icon(Icons.show_chart_rounded),
              text: 'Biểu đồ Cân nặng',
            ),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineTab(context, state),
                _buildWeightChartTab(context, state),
              ],
            ),
    );
  }

  Widget _buildTimelineTab(BuildContext context, WellnessState state) {
    final theme = Theme.of(context);
    final timelineItems = state.timeline?.items ?? [];

    if (timelineItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có dữ liệu nhật ký 30 ngày',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: timelineItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = timelineItems[index];
        return _buildTimelineCard(context, item);
      },
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    WellnessProgressTimelineItem item,
  ) {
    final theme = Theme.of(context);
    final formattedDate =
        '${item.logDate.day}/${item.logDate.month}/${item.logDate.year}';

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    formattedDate,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: item.hasCheckin
                      ? AppColors.mint
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.hasCheckin
                      ? 'Đã check-in'
                      : 'Chưa check-in',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.hasCheckin
                        ? AppColors.primaryDark
                        : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.md),

          // Metrics grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.water_drop_rounded,
                  iconColor: Colors.blue,
                  label: 'Nước uống',
                  value: '${item.waterMl} ml',
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.fitness_center_rounded,
                  iconColor: Colors.orange,
                  label: 'Vận động',
                  value: '${item.workoutMinutes} phút',
                ),
              ),
              if (item.currentWeightKg != null)
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.monitor_weight_rounded,
                    iconColor: AppColors.primary,
                    label: 'Cân nặng',
                    value: '${item.currentWeightKg} kg',
                  ),
                ),
            ],
          ),

          if (item.phase.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Giai đoạn: ${item.phase} (Ngày ${item.phaseDayIndex}/${item.phaseTotalDays})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChartTab(BuildContext context, WellnessState state) {
    final theme = Theme.of(context);
    final weightProg = state.dashboard?.weightProgress;

    final startWeight = weightProg?.startWeightKg ?? 65.0;
    final currentWeight = weightProg?.currentWeightKg ?? startWeight;
    final targetWeight = weightProg?.targetWeightKg ?? 60.0;
    final progressPercent = weightProg?.progressPercent ?? 0.0;
    final diff = currentWeight - startWeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header summary card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Text(
                  'Tổng quan Tiến độ Cân nặng',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeightStat('Ban đầu', '$startWeight kg', Colors.white),
                    _buildWeightStat(
                      'Hiện tại',
                      '$currentWeight kg',
                      AppColors.mint,
                    ),
                    _buildWeightStat('Mục tiêu', '$targetWeight kg', Colors.white),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    diff <= 0
                        ? 'Đã hoàn thành ${progressPercent.toStringAsFixed(1)}% mục tiêu!'
                        : 'Tiến độ cân nặng: ${progressPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

  Widget _buildWeightStat(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
