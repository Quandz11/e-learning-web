import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  ConsumerState<PersonalizationScreen> createState() =>
      _PersonalizationScreenState();
}

class _PersonalizationScreenState extends ConsumerState<PersonalizationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(wellnessControllerProvider.notifier).ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cá nhân hóa Wellness',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () {
              ref.read(wellnessControllerProvider.notifier).loadDashboard();
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.failure != null && state.dashboard == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Không thể tải dữ liệu: ${state.failure?.message}',
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(wellnessControllerProvider.notifier)
                              .loadDashboard();
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(wellnessControllerProvider.notifier)
                        .loadDashboard();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fasting Hero Card
                        _buildFastingHeroCard(context, state),
                        const SizedBox(height: AppSpacing.lg),

                        // Quick Check-in Tracker
                        _buildQuickCheckInCard(context, state),
                        const SizedBox(height: AppSpacing.lg),

                        // Daily Checklist
                        _buildDailyTasksCard(context, state),
                        const SizedBox(height: AppSpacing.lg),

                        // Sub-pages Navigation Section
                        Text(
                          'Tính năng Cá nhân hóa',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        _buildFeatureCard(
                          context,
                          icon: Icons.auto_awesome_rounded,
                          iconBgColor: AppColors.mint,
                          iconColor: AppColors.primary,
                          title: 'Trợ lý AI Wellness',
                          subtitle:
                              'Tư vấn trạng thái cơ thể & Gợi ý thực đơn Eat Clean',
                          onTap: () => context.push(
                            AppRoutes.appPersonalizationCoach,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        _buildFeatureCard(
                          context,
                          icon: Icons.tune_rounded,
                          iconBgColor: Colors.blue[50]!,
                          iconColor: Colors.blue[700]!,
                          title: 'Cấu hình Kế hoạch Nhịn ăn',
                          subtitle:
                              'Tùy chỉnh tỷ lệ nhịn/ăn, giờ giấc & cân nặng mục tiêu',
                          onTap: () => context.push(
                            AppRoutes.appPersonalizationPlanEditor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        _buildFeatureCard(
                          context,
                          icon: Icons.insights_rounded,
                          iconBgColor: Colors.purple[50]!,
                          iconColor: Colors.purple[700]!,
                          title: 'Nhật ký 30 ngày & Cân nặng',
                          subtitle:
                              'Biểu đồ tiến trình cân nặng & Lịch sử thực hiện thói quen',
                          onTap: () => context.push(
                            AppRoutes.appPersonalizationProgressTimeline,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        _buildFeatureCard(
                          context,
                          icon: Icons.self_improvement_rounded,
                          iconBgColor: Colors.amber[50]!,
                          iconColor: Colors.amber[800]!,
                          title: 'Thư viện Thiền & Tập luyện',
                          subtitle:
                              'Bài tập thở, thiền phục hồi & vận động nhẹ nhàng',
                          onTap: () => context.push(
                            AppRoutes.appPersonalizationResources,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        _buildFeatureCard(
                          context,
                          icon: Icons.notifications_active_rounded,
                          iconBgColor: Colors.green[50]!,
                          iconColor: Colors.green[700]!,
                          title: 'Nhắc nhở Thói quen',
                          subtitle: 'Quản lý lịch thông báo nhắc nhở hằng ngày',
                          onTap: () => context.push(
                            AppRoutes.appPersonalizationReminders,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFastingHeroCard(BuildContext context, WellnessState state) {
    final theme = Theme.of(context);
    final fasting = state.dashboard?.fastingStatus;
    final plan = state.dashboard?.plan;

    final ratio = plan != null
        ? '${plan.fastingHours}/${plan.eatingHours}'
        : '16/8';
    final isFasting = fasting?.state.toUpperCase() == 'FASTING';
    final progressPercent = fasting?.progressPercent ?? 0.0;
    final remainingMinutes = fasting?.remainingMinutes ?? 0;
    final remainingHours = (remainingMinutes / 60.0).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Chế độ $ratio',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                onPressed: () =>
                    context.push(AppRoutes.appPersonalizationPlanEditor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFasting ? 'Đang Nhịn Ăn' : 'Cửa Sổ Ăn Uống',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Còn lại: $remainingHours giờ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: (progressPercent / 100.0).clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: Colors.white24,
                      color: AppColors.mint,
                    ),
                  ),
                  Text(
                    '${progressPercent.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: (progressPercent / 100.0).clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            color: AppColors.mint,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCheckInCard(BuildContext context, WellnessState state) {
    final theme = Theme.of(context);
    final todayLog = state.dashboard?.todayLog;

    final currentWater = todayLog?.waterMl ?? 0;
    const targetWater = 2500;

    final currentMovement = todayLog?.workoutMinutes ?? 0;
    const targetMovement = 30;

    final currentWeight = todayLog?.currentWeightKg;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check-in Thói quen Hôm nay',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Water Tracker
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: Colors.blue, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uống nước: $currentWater / $targetWater ml',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: (currentWater / targetWater).clamp(0.0, 1.0),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(wellnessControllerProvider.notifier)
                      .logWaterDelta(250);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text(
                  '+250ml',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),

          // Movement Tracker
          Row(
            children: [
              const Icon(Icons.directions_run_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vận động: $currentMovement / $targetMovement phút',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: (currentMovement / targetMovement).clamp(0.0, 1.0),
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(wellnessControllerProvider.notifier)
                      .logWorkout(15, 'Vận động nhẹ');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text(
                  '+15ph',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),

          // Weight Entry
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  currentWeight != null
                      ? 'Cân nặng ghi nhận: $currentWeight kg'
                      : 'Chưa ghi nhận cân nặng hôm nay',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => _showWeightDialog(context, currentWeight),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text(
                  'Ghi nhận',
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTasksCard(BuildContext context, WellnessState state) {
    final theme = Theme.of(context);
    final tasks = state.dashboard?.todayTasks ?? [];

    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nhiệm vụ Thói quen',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${tasks.where((t) => t.isCompleted).length} / ${tasks.length} hoàn thành',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...tasks.map((task) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: task.isCompleted,
              activeColor: AppColors.primary,
              title: Text(
                task.lessonTitle.isNotEmpty ? task.lessonTitle : 'Nhiệm vụ thói quen',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
              ),
              subtitle: task.description.isNotEmpty
                  ? Text(
                      task.description,
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              onChanged: (val) {
                ref
                    .read(wellnessControllerProvider.notifier)
                    .completeTask(task.id);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightDialog(BuildContext context, double? currentWeight) {
    final controller = TextEditingController(
      text: currentWeight?.toString() ?? '60.0',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghi nhận Cân nặng Hôm nay'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Cân nặng (kg)',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                ref
                    .read(wellnessControllerProvider.notifier)
                    .logWeight(val);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
