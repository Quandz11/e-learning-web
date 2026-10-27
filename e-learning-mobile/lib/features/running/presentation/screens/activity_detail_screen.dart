import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/features/running/presentation/controllers/running_controller.dart';
import 'package:e_learning_mobile/features/running/presentation/screens/pre_run_screen.dart';
import 'package:e_learning_mobile/features/running/presentation/screens/rewards_inventory_screen.dart';
import 'package:e_learning_mobile/features/running/presentation/widgets/select_goal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen({super.key});

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final runningState = ref.watch(runningControllerProvider);
    final summary = runningState.summary;
    final unlockedBadges = summary.unlockedBadges.toSet();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              // Hero cover
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Visual scenic header
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F623F), Color(0xFF1E3A2F), Color(0xFF0A241A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Overlay graphic pattern
                          Opacity(
                            opacity: 0.15,
                            child: CustomPaint(
                              painter: _HeroPatternPainter(),
                            ),
                          ),
                          // Runner silhouette / icon graphic in center
                          Center(
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.directions_run,
                                size: 52,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Top Bar buttons
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isFavorite = !_isFavorite;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  size: 20,
                                  color: _isFavorite ? Colors.red : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Details Card
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions_run,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chạy bộ',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Hoạt động rèn luyện thể chất',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'Chạy bộ giúp bạn tăng cường sức khỏe tim mạch, nâng cao thể lực dẻo dai và tích lũy năng lượng cho hành trình học tập mỗi ngày.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Rewards section header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Phần thưởng',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RewardsInventoryScreen(),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      'Chi tiết',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Energy rule card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bolt,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Năng lượng học tập',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Chạy 1.0 KM = +1 E (Tích lũy theo từng cự ly)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Milestones row
                        const Text(
                          'Thành tích (đạt mốc cự ly)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFlowerMilestone(
                                label: '3 KM',
                                color: const Color(0xFFF59E0B),
                                isUnlocked: unlockedBadges.contains('badge_flower_bronze_3k') ||
                                    summary.longestRunKm >= 3.0,
                              ),
                              const SizedBox(width: 12),
                              _buildFlowerMilestone(
                                label: '5 KM',
                                color: const Color(0xFF3B82F6),
                                isUnlocked: unlockedBadges.contains('badge_flower_blue_5k') ||
                                    summary.longestRunKm >= 5.0,
                              ),
                              const SizedBox(width: 12),
                              _buildFlowerMilestone(
                                label: '10 KM',
                                color: const Color(0xFFEF4444),
                                isUnlocked: unlockedBadges.contains('badge_flower_red_10k') ||
                                    summary.longestRunKm >= 10.0,
                              ),
                              const SizedBox(width: 12),
                              _buildFlowerMilestone(
                                label: '21 KM',
                                color: const Color(0xFF8B5CF6),
                                isUnlocked: unlockedBadges.contains('badge_flower_purple_21k') ||
                                    summary.longestRunKm >= 21.0,
                              ),
                              const SizedBox(width: 12),
                              _buildFlowerMilestone(
                                label: '42 KM',
                                color: const Color(0xFFEC4899),
                                isUnlocked: unlockedBadges.contains('badge_crown_gold_42k') ||
                                    summary.longestRunKm >= 42.0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Streaks row
                        const Text(
                          'Kiên trì (theo chuỗi ngày)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStreakCard(
                                days: 7,
                                isUnlocked: summary.currentStreakDays >= 7,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStreakCard(
                                days: 14,
                                isUnlocked: summary.currentStreakDays >= 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStreakCard(
                                days: 28,
                                isUnlocked: summary.currentStreakDays >= 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Button: Thêm vào Mục tiêu
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => SelectGoalSheet.show(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            '+ Mục tiêu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Button: Bắt đầu
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PreRunScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Bắt đầu',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowerMilestone({
    required String label,
    required Color color,
    required bool isUnlocked,
  }) {
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isUnlocked ? color.withValues(alpha: 0.12) : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnlocked ? color.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_florist,
            size: 26,
            color: isUnlocked ? color : Colors.grey.shade400,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isUnlocked ? FontWeight.w800 : FontWeight.w600,
              color: isUnlocked ? color : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard({
    required int days,
    required bool isUnlocked,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFFFEF2F2) : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnlocked ? const Color(0xFFFCA5A5) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            size: 22,
            color: isUnlocked ? const Color(0xFFEF4444) : Colors.grey.shade400,
          ),
          const SizedBox(height: 6),
          Text(
            '$days ngày',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isUnlocked ? FontWeight.w800 : FontWeight.w600,
              color: isUnlocked ? const Color(0xFF991B1B) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5),
        30.0 + i * 28.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
