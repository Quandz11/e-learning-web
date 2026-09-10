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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text(
          'Cá nhân hóa Wellness',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: -0.3,
            color: Color(0xFF1A2520),
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFFF9FBF9),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF586B60),
              size: 20,
            ),
            onPressed: () {
              ref.read(wellnessControllerProvider.notifier).loadDashboard();
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : state.failure != null && state.dashboard == null
              ? _buildErrorState(state.failure?.message)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await ref
                        .read(wellnessControllerProvider.notifier)
                        .loadDashboard();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Zen Dial Fasting Hero Card
                        _buildZenDialHero(context, state),
                        const SizedBox(height: AppSpacing.md),

                        // 2. Bento Micro-Checkin (Water, Movement, Weight)
                        _buildBentoMicroCheckin(context, state),
                        const SizedBox(height: AppSpacing.lg),

                        // 3. Daily Habit Rituals Checklist
                        _buildDailyRituals(context, state),
                        const SizedBox(height: AppSpacing.lg),

                        // 4. Bento Feature Navigation Grid (2x2)
                        _buildBentoNavigationGrid(context),
                        const SizedBox(height: AppSpacing.sm),

                        // 5. Reminders Banner Card
                        _buildRemindersBanner(context),
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
              child: const Text(
                'Thử lại',
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Zen Dial Hero Fasting Widget
  Widget _buildZenDialHero(BuildContext context, WellnessState state) {
    final fasting = state.dashboard?.fastingStatus;
    final plan = state.dashboard?.plan;

    final ratio = plan != null
        ? '${plan.fastingHours}:${plan.eatingHours}'
        : '16:8';
    final isFasting = fasting?.state.toUpperCase() == 'FASTING';
    final progressPercent = fasting?.progressPercent ?? 0.0;
    final remainingMinutes = fasting?.remainingMinutes ?? 0;
    final remainingHours = remainingMinutes ~/ 60;
    final remainingMins = remainingMinutes % 60;
    final displayTime =
        '${remainingHours}h ${remainingMins.toString().padLeft(2, '0')}m';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAEFE9), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row with subtle pulse dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isFasting ? const Color(0xFF108A55) : const Color(0xFFD97706),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isFasting ? const Color(0xFF108A55) : const Color(0xFFD97706))
                          .withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isFasting ? 'ĐANG NHỊN ĂN' : 'CỬA SỔ ĂN UỐNG',
                style: TextStyle(
                  letterSpacing: 1.2,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isFasting ? const Color(0xFF0F5B38) : const Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  ratio,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF43544B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Center Circular Dial
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: (progressPercent / 100.0).clamp(0.0, 1.0),
                  strokeWidth: 3.5,
                  backgroundColor: const Color(0xFFEFF3EE),
                  color: const Color(0xFF0F5B38),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayTime,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                      color: Color(0xFF1A2520),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'thời gian còn lại',
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
          const SizedBox(height: 18),

          // Edit schedule subtle link button
          InkWell(
            onTap: () => context.push(AppRoutes.appPersonalizationPlanEditor),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tùy chỉnh kế hoạch',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0F5B38),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Color(0xFF0F5B38),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Bento Micro-Checkin Tracker
  Widget _buildBentoMicroCheckin(BuildContext context, WellnessState state) {
    final todayLog = state.dashboard?.todayLog;
    final currentWater = todayLog?.waterMl ?? 0;
    final currentMovement = todayLog?.workoutMinutes ?? 0;
    final currentWeight = todayLog?.currentWeightKg;
    final cupsCount = (currentWater / 250).ceil();

    return Row(
      children: [
        // Water Bento Card
        Expanded(
          child: _buildBentoCard(
            context: context,
            icon: Icons.local_drink_rounded,
            iconColor: const Color(0xFF0284C7),
            bgColor: const Color(0xFFE0F2FE),
            label: 'Nước uống',
            value: '$currentWater ml',
            subtitle: '$cupsCount/8 cốc',
            actionText: '+Thêm',
            onAction: () => _showWaterActionSheet(context, currentWater),
          ),
        ),
        const SizedBox(width: 10),

        // Movement Bento Card
        Expanded(
          child: _buildBentoCard(
            context: context,
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
            label: 'Vận động',
            value: '$currentMovement phút',
            subtitle: 'Mục tiêu: 30p',
            actionText: '+Tập',
            onAction: () => _showWorkoutActionSheet(context, currentMovement),
          ),
        ),
        const SizedBox(width: 10),

        // Weight Bento Card
        Expanded(
          child: _buildBentoCard(
            context: context,
            icon: Icons.scale_rounded,
            iconColor: const Color(0xFF0F5B38),
            bgColor: const Color(0xFFDCFCE7),
            label: 'Cân nặng',
            value: currentWeight != null
                ? '${currentWeight.toStringAsFixed(1)} kg'
                : '-- kg',
            subtitle: currentWeight != null ? 'Hôm nay' : 'Chưa ghi',
            actionText: 'Ghi',
            onAction: () => _showEnhancedWeightSheet(context, currentWeight, state),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    String? subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return GestureDetector(
      onTap: onAction,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAEFE9), width: 0.8),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F3),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F5B38),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFF717873),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2520),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF8E9E94),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 3. Daily Habit Rituals Checklist
  Widget _buildDailyRituals(BuildContext context, WellnessState state) {
    final tasks = state.dashboard?.todayTasks ?? [];
    if (tasks.isEmpty) return const SizedBox.shrink();

    final completedCount = tasks.where((t) => t.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEFE9), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 14,
            offset: Offset(0, 2),
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
                'Nhiệm vụ Thói quen',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A2520),
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6F3),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$completedCount/${tasks.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F5B38),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...tasks.map((task) {
            return InkWell(
              onTap: () {
                ref
                    .read(wellnessControllerProvider.notifier)
                    .completeTask(task.id);
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? const Color(0xFF0F5B38)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isCompleted
                              ? const Color(0xFF0F5B38)
                              : const Color(0xFFC7D3CA),
                          width: 1.2,
                        ),
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.lessonTitle.isNotEmpty
                                ? task.lessonTitle
                                : 'Bài thực hành chăm sóc thể trạng',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: task.isCompleted
                                  ? const Color(0xFF9EABA3)
                                  : const Color(0xFF1A2520),
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              task.description,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF8E9E94),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 4. Bento Navigation Grid (2x2)
  Widget _buildBentoNavigationGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Không gian Cá nhân hóa',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1A2520),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBentoNavCard(
                title: 'Trợ lý Sức khỏe',
                subtitle: 'Tâm trí & Thực đơn',
                icon: Icons.psychology_outlined,
                iconColor: const Color(0xFF0F5B38),
                bgColor: const Color(0xFFF0F7F2),
                onTap: () => context.push(AppRoutes.appPersonalizationCoach),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoNavCard(
                title: 'Kế hoạch',
                subtitle: 'Tỷ lệ & Giờ nhịn',
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () =>
                    context.push(AppRoutes.appPersonalizationPlanEditor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBentoNavCard(
                title: 'Tiến trình',
                subtitle: '30 ngày & Cân nặng',
                icon: Icons.insights_rounded,
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                onTap: () =>
                    context.push(AppRoutes.appPersonalizationProgressTimeline),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoNavCard(
                title: 'Thư viện',
                subtitle: 'Thiền, Thở & Bài tập',
                icon: Icons.spa_outlined,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                onTap: () => context.push(AppRoutes.appPersonalizationResources),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoNavCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAEFE9), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x03000000),
              blurRadius: 10,
              offset: Offset(0, 2),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFFB5C2BA),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1A2520),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: Color(0xFF8E9E94),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Reminders Banner Card
  Widget _buildRemindersBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.appPersonalizationReminders),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAEFE9), width: 0.8),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 20,
              color: Color(0xFF0F5B38),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lịch nhắc nhở thói quen',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1A2520),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Thông báo uống nước, bắt đầu & kết thúc nhịn ăn',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF8E9E94),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFB5C2BA),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Water Intake Action Sheet (with visual cups)
  void _showWaterActionSheet(BuildContext context, int currentWater) {
    final cupsCount = (currentWater / 250).ceil();
    final progress = (currentWater / 2000.0).clamp(0.0, 1.0);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
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
                          const Text(
                            'Ghi nhận Nước uống',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E2621),
                            ),
                          ),
                          Text(
                            'Đã uống $currentWater ml • $cupsCount/8 cốc trong ngày',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF717873),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE0F2FE),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chọn nhanh lượng nước vừa uống:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E2621),
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
                        ref.read(wellnessControllerProvider.notifier).logWaterDelta(150);
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
                        ref.read(wellnessControllerProvider.notifier).logWaterDelta(250);
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildWaterOption(
                      title: 'Bình nước',
                      volume: '+500 ml',
                      icon: Icons.water_drop_outlined,
                      onTap: () {
                        ref.read(wellnessControllerProvider.notifier).logWaterDelta(500);
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
            color: isHighlight ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlight ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
              width: isHighlight ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isHighlight ? const Color(0xFF0284C7) : const Color(0xFF64748B),
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
                  fontWeight: FontWeight.w600,
                  color: isHighlight ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Workout / Movement Action Sheet
  void _showWorkoutActionSheet(BuildContext context, int currentMovement) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
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
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_run_rounded,
                        color: Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ghi nhận Hoạt động Vận động',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E2621),
                            ),
                          ),
                          Text(
                            'Đã tập $currentMovement phút hôm nay • Mục tiêu: 30 phút',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF717873),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Chọn bài tập vừa thực hiện:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E2621),
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
                  title: 'Yoga & Dãn cơ phục hồi',
                  minutes: 20,
                  desc: 'Thư giãn cơ bắp và giảm căng thẳng',
                ),
                _buildWorkoutOption(
                  ctx: ctx,
                  icon: Icons.directions_run_rounded,
                  title: 'Chạy bộ / Đi bộ nhanh',
                  minutes: 30,
                  desc: 'Tăng cường trao đổi chất và đốt mỡ',
                ),
                _buildWorkoutOption(
                  ctx: ctx,
                  icon: Icons.fitness_center_rounded,
                  title: 'Tập thể lực / HIIT / Kháng lực',
                  minutes: 45,
                  desc: 'Xây dựng cơ bắp và đốt calo sâu',
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
          ref.read(wellnessControllerProvider.notifier).logWorkout(minutes, title);
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
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFFD97706)),
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
                        fontWeight: FontWeight.w500,
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
                    fontWeight: FontWeight.w600,
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

  // 3. Enhanced Weight Tracking Action Sheet
  void _showEnhancedWeightSheet(
    BuildContext context,
    double? currentWeight,
    WellnessState state,
  ) {
    final weightProg = state.dashboard?.weightProgress;
    final startWeight = weightProg?.startWeightKg ?? (currentWeight ?? 65.0);
    final controller = TextEditingController(
      text: currentWeight?.toStringAsFixed(1) ?? '62.0',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final parsedWeight = double.tryParse(controller.text) ?? 62.0;
            final delta = parsedWeight - startWeight;

            return Padding(
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.scale_rounded,
                          color: Color(0xFF0F5B38),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ghi nhận Cân nặng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E2621),
                              ),
                            ),
                            Text(
                              delta.abs() < 0.05
                                  ? 'Bằng cân nặng lúc bắt đầu ($startWeight kg)'
                                  : delta < 0
                                      ? 'Giảm ${(delta.abs()).toStringAsFixed(1)} kg so với ban đầu'
                                      : 'Tăng ${delta.toStringAsFixed(1)} kg so với ban đầu',
                              style: TextStyle(
                                fontSize: 12,
                                color: delta < 0
                                    ? const Color(0xFF0F5B38)
                                    : const Color(0xFF717873),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Weight Stepper Display
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEAEFE9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 32),
                          color: const Color(0xFF0F5B38),
                          onPressed: () {
                            final current = double.tryParse(controller.text) ?? 62.0;
                            final next = (current - 0.1).clamp(30.0, 250.0);
                            controller.text = next.toStringAsFixed(1);
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E2621),
                            ),
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              suffixText: 'kg',
                              suffixStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF717873),
                              ),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 32),
                          color: const Color(0xFF0F5B38),
                          onPressed: () {
                            final current = double.tryParse(controller.text) ?? 62.0;
                            final next = (current + 0.1).clamp(30.0, 250.0);
                            controller.text = next.toStringAsFixed(1);
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final val = double.tryParse(controller.text);
                        if (val != null && val > 0) {
                          ref.read(wellnessControllerProvider.notifier).logWeight(val);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã ghi nhận cân nặng: ${val.toStringAsFixed(1)} kg'),
                              backgroundColor: const Color(0xFF0F5B38),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5B38),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: const Text(
                        'Lưu cân nặng hôm nay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
