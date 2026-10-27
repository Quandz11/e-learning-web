import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/features/personalization/presentation/widgets/planner_calendar_strip.dart';
import 'package:e_learning_mobile/features/personalization/presentation/widgets/planner_daily_status_sheet.dart';
import 'package:e_learning_mobile/features/personalization/presentation/widgets/planner_daily_tasks_card.dart';
import 'package:e_learning_mobile/features/personalization/presentation/widgets/planner_daily_tips_section.dart';
import 'package:e_learning_mobile/features/personalization/presentation/widgets/planner_fasting_tracker_card.dart';
import 'package:e_learning_mobile/features/personalization/presentation/widgets/planner_meal_timeline_section.dart';
import 'package:e_learning_mobile/features/personalization/presentation/widgets/planner_stats_summary.dart';
import 'package:e_learning_mobile/features/personalization/presentation/widgets/planner_water_tracker_card.dart';
import 'package:e_learning_mobile/features/personalization/presentation/widgets/planner_workout_hero_card.dart';
import 'package:e_learning_mobile/features/running/presentation/widgets/running_summary_card.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  ConsumerState<PersonalizationScreen> createState() =>
      _PersonalizationScreenState();
}

class _PersonalizationScreenState extends ConsumerState<PersonalizationScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(wellnessControllerProvider.notifier).ensureLoaded();
    });
  }

  Future<void> _openWorkoutVideo(String? url, int workoutMinutes) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (mounted) {
      _showWorkoutActionSheet(context, workoutMinutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wellnessControllerProvider);
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    final dash = state.dashboard;
    final plan = dash?.plan;
    final todayLog = dash?.todayLog;
    final currentWater = todayLog?.waterMl ?? 0;
    final workoutMinutes = todayLog?.workoutMinutes ?? 0;
    final ateAtLocal = todayLog?.ateAtLocal;

    // Real calculated values based on user profile and clinical standards
    final userWeight = (todayLog?.currentWeightKg ??
            plan?.latestWeightKg ??
            plan?.startWeightKg ??
            60.0)
        .toDouble();

    // Target water: 35ml per kg of bodyweight
    final targetWaterMl = (userWeight > 0 ? (userWeight * 35).round() : 2000);

    // Calories burned: MET 5.0 (Moderate full body workout) * weight * hours
    final caloriesBurned =
        ((5.0 * userWeight * (workoutMinutes / 60.0))).round();
    final targetCalories = ((5.0 * userWeight * (30 / 60.0))).round();

    // Meals tracking
    final mealsCount = ateAtLocal != null ? 1 : 0;
    final targetMeals =
        (plan?.eatingHours != null && plan!.eatingHours <= 6) ? 2 : 3;

    final workoutResource = dash?.todayResources?.workout;
    final workoutTitle = workoutResource?.title.isNotEmpty == true
        ? workoutResource!.title
        : 'Bài tập Vận động Hàng ngày';

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAF9),
      appBar: AppBar(
        titleSpacing: 16,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kế hoạch',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.4,
                  color: context.textPrimary(),
                ),
              ),
              Text(
                'Cá nhân hóa Wellness',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                  letterSpacing: -0.1,
                  color: context.textMuted(),
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor:
            isDark ? colorScheme.surface : const Color(0xFFF8FAF9),
        actions: [
          // Nút Trợ giúp nổi bật màu đỏ SOS
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.push(AppRoutes.appPersonalizationCoach),
              icon: const Icon(
                Icons.support_agent_rounded,
                size: 15,
                color: Colors.white,
              ),
              label: const Text(
                'Trợ giúp',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626), // SOS Red
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : state.failure != null && dash == null
          ? _buildErrorState(state.failure?.message)
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref
                    .read(wellnessControllerProvider.notifier)
                    .refresh();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Calendar week strip (T2 -> CN)
                    PlannerCalendarStrip(
                      selectedDate: _selectedDate,
                      onSelectDate: (date) {
                        setState(() => _selectedDate = date);
                      },
                    ),
                    const SizedBox(height: 14),

                    // 2. Glanceable Top Stats Bar (Vận động, Bữa ăn, Nước - Dữ liệu tính toán thật)
                    PlannerStatsSummary(
                      workoutMinutes: workoutMinutes,
                      targetWorkoutMinutes: 30,
                      waterMl: currentWater,
                      targetWaterMl: targetWaterMl,
                      mealsCount: mealsCount,
                      targetMeals: targetMeals,
                      caloriesBurned: caloriesBurned,
                      targetCalories: targetCalories,
                      ateAtLocal: ateAtLocal,
                      onTapWorkout: () => _showWorkoutActionSheet(
                        context,
                        workoutMinutes,
                      ),
                      onTapWater: () => _showWaterActionSheet(
                        context,
                        currentWater,
                        targetWaterMl,
                      ),
                      onTapMeals: () => _showMealAssistantSheet(context),
                    ),
                    const SizedBox(height: 16),

                    // 3. Fasting Schedule & Real-time Bio-Phases Tracker
                    PlannerFastingTrackerCard(
                      fastingStatus: dash?.fastingStatus,
                      plan: plan,
                      coachReply: state.lastCoachReply,
                      onEditSchedule: () => context.push(
                        AppRoutes.appPersonalizationPlanEditor,
                      ),
                      onAnswerMood: () => PlannerDailyStatusSheet.show(context),
                    ),
                    const SizedBox(height: 16),

                    // 4. Interactive Water Tracker (1-tap quick add buttons)
                    PlannerWaterTrackerCard(
                      currentWaterMl: currentWater,
                      targetWaterMl: targetWaterMl,
                      onQuickAdd: (delta) {
                        ref
                            .read(wellnessControllerProvider.notifier)
                            .logWaterDelta(delta);
                      },
                      onLogWater: () => _showWaterActionSheet(
                        context,
                        currentWater,
                        targetWaterMl,
                      ),
                      onLearnMore: () => _showWaterLearnMoreSheet(context),
                    ),
                    const SizedBox(height: 16),

                    // 5. Featured Workout Hero Card (Bound to real workout resource)
                    PlannerWorkoutHeroCard(
                      workoutResource: workoutResource,
                      completedMinutes: workoutMinutes,
                      onOpenWorkout: () => _openWorkoutVideo(
                        workoutResource?.url,
                        workoutMinutes,
                      ),
                      onLogWorkout: (mins) {
                        ref
                            .read(wellnessControllerProvider.notifier)
                            .logWorkout(mins, workoutTitle);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Running & GPS Activity Tracker Card
                    const RunningSummaryCard(),
                    const SizedBox(height: 16),

                    // 6. Eating Window Timeline & Real Meal Logging
                    PlannerMealTimelineSection(
                      fastingStatus: dash?.fastingStatus,
                      plan: plan,
                      todayLog: todayLog,
                      mealSuggestion: state.lastMealSuggestion,
                      onLogMealNow: () {
                        ref
                            .read(wellnessControllerProvider.notifier)
                            .logMealTime();
                      },
                      onRequestAiMeal: () => _showMealAssistantSheet(context),
                    ),
                    const SizedBox(height: 16),

                    // 7. Daily Tasks / Checklist (Real tasks from backend)
                    if (dash?.todayTasks != null && dash!.todayTasks.isNotEmpty) ...[
                      PlannerDailyTasksCard(
                        tasks: dash.todayTasks,
                        onToggleTask: (taskId) {
                          ref
                              .read(wellnessControllerProvider.notifier)
                              .completeTask(taskId);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 8. Daily Insights & Knowledge Cards (Real AI Insight)
                    PlannerDailyTipsSection(
                      todayInsight: dash?.todayInsight,
                      onTapArticle: () => context.push(
                        AppRoutes.appPersonalizationResources,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 9. Bottom Navigation Hub
                    _buildNavigationHub(context),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.spa_outlined,
              size: 40,
              color: Color(0xFF8E9E94),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? 'Không thể tải dữ liệu lúc này.',
              style: const TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 14,
                color: Color(0xFF586B60),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () {
                ref.read(wellnessControllerProvider.notifier).loadDashboard();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xFF0F5B38)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation Hub
  Widget _buildNavigationHub(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.cardBorder(), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiện ích Lối sống & Sức khỏe',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.textPrimary(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHubItem(
                  context: context,
                  icon: Icons.insights_rounded,
                  label: 'Tiến trình 30 ngày',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => context.push(
                    AppRoutes.appPersonalizationProgressTimeline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHubItem(
                  context: context,
                  icon: Icons.tune_rounded,
                  label: 'Tùy chỉnh lịch nhịn',
                  color: const Color(0xFF2563EB),
                  onTap: () => context.push(
                    AppRoutes.appPersonalizationPlanEditor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildHubItem(
                  context: context,
                  icon: Icons.spa_outlined,
                  label: 'Thư viện Thiền & Thở',
                  color: const Color(0xFFD97706),
                  onTap: () => context.push(
                    AppRoutes.appPersonalizationResources,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHubItem(
                  context: context,
                  icon: Icons.notifications_active_outlined,
                  label: 'Lịch nhắc nhở',
                  color: isDark ? context.colorScheme.primary : const Color(0xFF0F5B38),
                  onTap: () => context.push(
                    AppRoutes.appPersonalizationReminders,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHubItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? context.colorScheme.surfaceContainerHighest
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBorder(), width: 0.8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary(),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: context.textMuted(),
            ),
          ],
        ),
      ),
    );
  }

  // Water Action Sheet (+150ml, +250ml, +500ml)
  void _showWaterActionSheet(
    BuildContext context,
    int currentWater,
    int targetWater,
  ) {
    final cupsCount = (currentWater / 250).ceil();
    final progress =
        (targetWater > 0 ? (currentWater / targetWater.toDouble()) : 0.0)
            .clamp(0.0, 1.0);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2EBE5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_drink_rounded,
                        color: Color(0xFF0284C7),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ghi nhận Lượng nước uống',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary(),
                            ),
                          ),
                          Text(
                            'Đã uống $currentWater / $targetWater ml • $cupsCount cốc trong ngày',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE0F2FE),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0284C7),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Chọn nhanh lượng nước vừa uống:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildWaterOption(
                      title: 'Cốc nhỏ',
                      volume: '+150 ml',
                      icon: Icons.local_cafe_outlined,
                      onTap: () {
                        ref
                            .read(wellnessControllerProvider.notifier)
                            .logWaterDelta(150);
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildWaterOption(
                      title: 'Cốc chuẩn',
                      volume: '+250 ml',
                      icon: Icons.local_drink_rounded,
                      isHighlight: true,
                      onTap: () {
                        ref
                            .read(wellnessControllerProvider.notifier)
                            .logWaterDelta(250);
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildWaterOption(
                      title: 'Bình nước',
                      volume: '+500 ml',
                      icon: Icons.water_drop_outlined,
                      onTap: () {
                        ref
                            .read(wellnessControllerProvider.notifier)
                            .logWaterDelta(500);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaterOption({
    required String title,
    required String volume,
    required IconData icon,
    bool isHighlight = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isHighlight
                ? const Color(0xFFE0F2FE)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlight
                  ? const Color(0xFF0284C7)
                  : const Color(0xFFE2E8F0),
              width: isHighlight ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isHighlight
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                volume,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isHighlight
                      ? const Color(0xFF0284C7)
                      : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWaterLearnMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tầm quan trọng của Nước khi Nhịn ăn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary(),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Trong thời gian nhịn ăn gián đoạn, cơ thể đào thải nước và chất điện giải nhanh hơn bình thường. Uống đủ 35ml nước cho mỗi kg cân nặng mỗi ngày giúp:',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: context.textSecondary(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('• Giảm cảm giác đói giả do thiếu nước.'),
                const Text('• Hỗ trợ gan và thận thanh lọc độc tố hiệu quả.'),
                const Text('• Duy trì năng lượng và hạn chế tình trạng mệt mỏi.'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: const Text('Đã hiểu', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Workout Action Sheet
  void _showWorkoutActionSheet(BuildContext context, int currentMovement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2EBE5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ghi nhận Hoạt động Thể chất',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary(),
                            ),
                          ),
                          Text(
                            'Đã tập $currentMovement phút hôm nay • Mục tiêu: 30 phút',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Chọn bài tập vừa thực hiện:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary(),
                  ),
                ),
                const SizedBox(height: 10),
                _buildWorkoutOption(
                  ctx: ctx,
                  icon: Icons.directions_walk_rounded,
                  title: 'Đi bộ nhẹ nhàng',
                  minutes: 15,
                  desc: 'Hỗ trợ tuần hoàn máu và nhẹ bụng',
                ),
                _buildWorkoutOption(
                  ctx: ctx,
                  icon: Icons.self_improvement_rounded,
                  title: 'Yoga & Giãn cơ phục hồi',
                  minutes: 20,
                  desc: 'Thư giãn cơ bắp và giảm căng thẳng',
                ),
                _buildWorkoutOption(
                  ctx: ctx,
                  icon: Icons.fitness_center_rounded,
                  title: 'Shaped Lower Body Workout',
                  minutes: 24,
                  desc: 'Bài tập cơ thân dưới & đốt calo',
                ),
                _buildWorkoutOption(
                  ctx: ctx,
                  icon: Icons.directions_run_rounded,
                  title: 'Chạy bộ / Vận động nhịp tim cao',
                  minutes: 30,
                  desc: 'Tăng cường trao đổi chất sâu',
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutOption({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required int minutes,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          ref
              .read(wellnessControllerProvider.notifier)
              .logWorkout(minutes, title);
          Navigator.pop(ctx);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAEFE9), width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFFEF4444)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2621),
                      ),
                    ),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E9E94),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$minutes phút',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F5B38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AI Meal Assistant Dialog
  void _showMealAssistantSheet(BuildContext context) {
    final controller = TextEditingController(
      text: 'Ức gà, Trứng, Súp lơ xanh, Gạo lứt, Cà chua',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EBE5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trợ lý Lên Thực đơn Thông minh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Nhập các nguyên liệu bạn đang có sẵn trong tủ lạnh:',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                style: TextStyle(color: context.textPrimary()),
                decoration: InputDecoration(
                  hintText: 'VD: Thịt bò, rau muống, nấm, trứng...',
                  filled: true,
                  fillColor: context.isDark
                      ? context.colorScheme.surfaceContainerHighest
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.cardBorder()),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.cardBorder()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final raw = controller.text.trim();
                    final items = raw
                        .split(RegExp(r'[,;\n]'))
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    if (items.isNotEmpty) {
                      ref
                          .read(wellnessControllerProvider.notifier)
                          .generateMeal(
                            WellnessCoachMealRequest(
                              ingredients: items,
                              servings: 1,
                              goal: 'healthy',
                              dietaryPreference: 'Low Carb',
                            ),
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Huấn luyện viên đang tạo thực đơn cho bạn...',
                          ),
                          backgroundColor: Color(0xFF0F5B38),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5B38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: const Text(
                    'Sinh Thực đơn Phù hợp',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
