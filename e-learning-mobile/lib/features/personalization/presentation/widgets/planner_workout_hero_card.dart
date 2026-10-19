import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

class PlannerWorkoutHeroCard extends StatelessWidget {
  const PlannerWorkoutHeroCard({
    super.key,
    this.workoutResource,
    this.completedMinutes = 0,
    required this.onOpenWorkout,
    required this.onLogWorkout,
  });

  final WellnessResourceItem? workoutResource;
  final int completedMinutes;
  final VoidCallback onOpenWorkout;
  final ValueChanged<int> onLogWorkout;

  int _extractDurationMinutes(String title, String desc) {
    final match = RegExp(r'(\d+)\s*(?:m|min|phút)', caseSensitive: false)
        .firstMatch('$title $desc');
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 15;
    }
    return 15;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final title = workoutResource?.title.isNotEmpty == true
        ? workoutResource!.title
        : 'Bài tập Vận động Hàng ngày';
    final desc = workoutResource?.description.isNotEmpty == true
        ? workoutResource!.description
        : 'Tăng cường trao đổi chất và duy trì độ dẻo dai.';

    final durationMins = _extractDurationMinutes(title, desc);
    final hasCompleted = completedMinutes >= durationMins;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder(), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenWorkout,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Visual Thumbnail Banner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 90,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF2E384D), const Color(0xFF1E2433)]
                                : [const Color(0xFFFEE2E2), const Color(0xFFFECACA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 42,
                              color: const Color(0xFFEF4444).withValues(alpha: 0.85),
                            ),
                            Positioned(
                              bottom: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.play_circle_fill_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$durationMins phút',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Right Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: const Text(
                                    'BÀI TẬP HÔM NAY',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEF4444),
                                      letterSpacing: 0.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: context.textMuted(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary(),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textSecondary(),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons Row: BẮT ĐẦU BÀI TẬP & Quick Log
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: onOpenWorkout,
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'BẮT ĐẦU BÀI TẬP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () => onLogWorkout(durationMins),
                          icon: Icon(
                            hasCompleted
                                ? Icons.check_circle_rounded
                                : Icons.check_rounded,
                            size: 14,
                            color: hasCompleted
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          label: Text(
                            hasCompleted ? 'Đã xong' : 'Xong ${durationMins}p',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: hasCompleted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: hasCompleted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
