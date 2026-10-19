import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

class PlannerStatsSummary extends StatelessWidget {
  const PlannerStatsSummary({
    super.key,
    required this.workoutMinutes,
    this.targetWorkoutMinutes = 30,
    required this.waterMl,
    required this.targetWaterMl,
    this.mealsCount = 0,
    this.targetMeals = 3,
    this.caloriesBurned = 0,
    this.targetCalories = 150,
    this.ateAtLocal,
    this.onTapWorkout,
    this.onTapWater,
    this.onTapMeals,
  });

  final int workoutMinutes;
  final int targetWorkoutMinutes;
  final int waterMl;
  final int targetWaterMl;
  final int mealsCount;
  final int targetMeals;
  final int caloriesBurned;
  final int targetCalories;
  final DateTime? ateAtLocal;
  final VoidCallback? onTapWorkout;
  final VoidCallback? onTapWater;
  final VoidCallback? onTapMeals;

  @override
  Widget build(BuildContext context) {
    final mealTimeText = ateAtLocal != null
        ? '${ateAtLocal!.hour.toString().padLeft(2, '0')}:${ateAtLocal!.minute.toString().padLeft(2, '0')}'
        : null;

    final workoutText = workoutMinutes > 0
        ? '$workoutMinutes/${targetWorkoutMinutes}p'
        : (caloriesBurned > 0 ? '$caloriesBurned kcal' : '0/${targetWorkoutMinutes}p');

    final mealsText = mealTimeText != null
        ? 'Đã ăn $mealTimeText'
        : '$mealsCount/$targetMeals bữa';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder(), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Workout (Bài tập / Calo tiêu thụ)
          Expanded(
            child: _buildItem(
              context: context,
              icon: Icons.fitness_center_rounded,
              iconColor: const Color(0xFFEF4444),
              bgColor: const Color(0xFFFEE2E2),
              title: 'Bài tập',
              value: workoutText,
              subtext: workoutMinutes > 0 ? '$caloriesBurned calo' : null,
              onTap: onTapWorkout,
            ),
          ),
          Container(
            height: 32,
            width: 1,
            color: context.cardBorder(),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),

          // 2. Meals (Khung ăn & Nhật ký bữa)
          Expanded(
            child: _buildItem(
              context: context,
              icon: Icons.restaurant_rounded,
              iconColor: const Color(0xFF10B981),
              bgColor: const Color(0xFFD1FAE5),
              title: 'Bữa ăn',
              value: mealsText,
              subtext: mealTimeText != null ? '$mealsCount/$targetMeals bữa' : null,
              onTap: onTapMeals,
            ),
          ),
          Container(
            height: 32,
            width: 1,
            color: context.cardBorder(),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),

          // 3. Water (Nước uống thực tế / Mục tiêu theo cân nặng)
          Expanded(
            child: _buildItem(
              context: context,
              icon: Icons.water_drop_rounded,
              iconColor: const Color(0xFF0284C7),
              bgColor: const Color(0xFFE0F2FE),
              title: 'Nước uống',
              value: '$waterMl/$targetWaterMl ml',
              subtext: waterMl >= targetWaterMl ? 'Đạt mục tiêu' : null,
              onTap: onTapWater,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    String? subtext,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: context.textSecondary(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtext != null) ...[
                    Text(
                      subtext,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF10B981),
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
  }
}
