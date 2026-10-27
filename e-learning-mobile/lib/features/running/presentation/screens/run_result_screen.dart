import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/features/running/presentation/widgets/rewards_celebration_dialog.dart';
import 'package:flutter/material.dart';

class RunResultScreen extends StatelessWidget {
  const RunResultScreen({
    super.key,
    required this.activity,
  });

  final RunningActivity activity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Medal badge icon
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 46,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Hoàn thành!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Stat Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      icon: Icons.timer_outlined,
                      label: 'Thời gian',
                      value: activity.durationFormatted,
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _buildStatRow(
                      icon: Icons.straighten,
                      label: 'Quãng đường',
                      value: '${activity.distanceKm.toStringAsFixed(2)} KM',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _buildStatRow(
                      icon: Icons.speed,
                      label: 'Tốc độ trung bình',
                      value: activity.paceFormatted,
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _buildStatRow(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Năng lượng tiêu hao',
                      value: '${activity.caloriesBurned} kcal',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Button: Xem phần thưởng
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    RewardsCelebrationDialog.show(context, activity);
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
                        Icon(Icons.card_giftcard, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Xem phần thưởng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Button: Quay lại trang chủ
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Về trang chủ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
