import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

class PlannerMealTimelineSection extends StatelessWidget {
  const PlannerMealTimelineSection({
    super.key,
    this.fastingStatus,
    this.plan,
    this.todayLog,
    this.mealSuggestion,
    required this.onLogMealNow,
    required this.onRequestAiMeal,
  });

  final WellnessFastingStatus? fastingStatus;
  final WellnessPlan? plan;
  final WellnessDailyLog? todayLog;
  final WellnessMealSuggestion? mealSuggestion;
  final VoidCallback onLogMealNow;
  final VoidCallback onRequestAiMeal;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isFasting = fastingStatus?.state.toUpperCase() == 'FASTING';

    final eatingHours = plan?.eatingHours ?? 8;
    DateTime eatingStart;
    DateTime eatingEnd;

    if (fastingStatus != null) {
      if (isFasting) {
        eatingStart = fastingStatus!.windowEndLocal;
        eatingEnd = eatingStart.add(Duration(hours: eatingHours));
      } else {
        eatingStart = fastingStatus!.windowStartLocal;
        eatingEnd = fastingStatus!.windowEndLocal;
      }
    } else {
      eatingStart = DateTime(2026, 1, 1, 12, 0);
      eatingEnd = DateTime(2026, 1, 1, 20, 0);
    }

    final startStr =
        '${eatingStart.hour.toString().padLeft(2, '0')}:${eatingStart.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${eatingEnd.hour.toString().padLeft(2, '0')}:${eatingEnd.minute.toString().padLeft(2, '0')}';

    final midTime = eatingStart.add(Duration(minutes: (eatingHours * 30)));
    final midStr =
        '${midTime.hour.toString().padLeft(2, '0')}:${midTime.minute.toString().padLeft(2, '0')}';

    final lastMealTime = eatingEnd.subtract(const Duration(minutes: 30));
    final lastStr =
        '${lastMealTime.hour.toString().padLeft(2, '0')}:${lastMealTime.minute.toString().padLeft(2, '0')}';

    final ateAt = todayLog?.ateAtLocal;
    final hasLoggedMeal = ateAt != null;
    final ateTimeStr = hasLoggedMeal
        ? '${ateAt.hour.toString().padLeft(2, '0')}:${ateAt.minute.toString().padLeft(2, '0')}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Header
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFasting
                      ? (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9))
                      : (isDark
                          ? const Color(0xFF064E3B)
                          : const Color(0xFFD1FAE5)),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  isFasting
                      ? 'Khung ăn: $startStr - $endStr'
                      : 'Đang mở: $startStr - $endStr',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isFasting
                        ? context.textSecondary()
                        : const Color(0xFF059669),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(
                color: context.cardBorder().withValues(alpha: 0.7),
                thickness: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Real Meal Guidance & Status Banner
        Container(
          padding: const EdgeInsets.all(14),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: hasLoggedMeal
                          ? const Color(0xFFD1FAE5)
                          : (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasLoggedMeal
                            ? const Color(0xFF10B981)
                            : context.cardBorder(),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        hasLoggedMeal
                            ? Icons.check_circle_rounded
                            : Icons.restaurant_rounded,
                        size: 22,
                        color: hasLoggedMeal
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLoggedMeal
                              ? 'Đã nạp bữa ăn hôm nay ($ateTimeStr)'
                              : 'Khung giờ Dinh dưỡng Hôm nay',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary(),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasLoggedMeal
                              ? 'Cơ thể đã bắt đầu chu trình hấp thu dinh dưỡng. Hãy uống đủ nước và chuẩn bị kết thúc khung ăn đúng giờ.'
                              : 'Quy tắc vàng khi nhịn ăn: Ưu tiên đạm và rau xanh trước, ăn chậm nhai kỹ và dừng lại khi vừa đủ no.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.45,
                            color: context.textSecondary(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Interactive Action: Log meal now
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: onLogMealNow,
                  icon: Icon(
                    hasLoggedMeal
                        ? Icons.update_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    hasLoggedMeal
                        ? 'Cập nhật giờ ăn gần nhất'
                        : 'Ghi nhận đã ăn bữa này',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasLoggedMeal
                        ? const Color(0xFF0F5B38)
                        : const Color(0xFF10B981),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Calculated Meal Timeline Milestones
        _buildMealMilestone(
          context: context,
          timeStr: startStr,
          title: 'Bữa ăn đầu tiên',
          recommendation:
              'Protein nạc (ức gà, trứng), rau xanh và chất béo tốt (quả bơ, dầu ô liu). Tránh tinh bột nhanh để ngừa đột biến đường huyết.',
          icon: Icons.wb_sunny_outlined,
          iconColor: const Color(0xFFF59E0B),
          isPassed: hasLoggedMeal,
        ),
        const SizedBox(height: 8),
        _buildMealMilestone(
          context: context,
          timeStr: midStr,
          title: 'Bữa Phụ Giữa Khung',
          recommendation:
              'Hạt ngũ cốc, hạnh nhân, sữa chua Hy Lạp không đường hoặc sinh tố rau củ.',
          icon: Icons.cookie_outlined,
          iconColor: const Color(0xFF3B82F6),
          isPassed: false,
        ),
        const SizedBox(height: 8),
        _buildMealMilestone(
          context: context,
          timeStr: lastStr,
          title: 'Bữa Cuối Khung (Trước khi nhịn)',
          recommendation:
              'Bữa ăn giàu chất xơ hòa tan và protein giải phóng chậm (cá, đậu phụ) để giữ cảm giác no lâu qua đêm.',
          icon: Icons.nightlight_round,
          iconColor: const Color(0xFF8B5CF6),
          isPassed: false,
        ),
        const SizedBox(height: 12),

        // AI Generated meal preview if available
        if (mealSuggestion != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2A22) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2B4C38)
                    : const Color(0xFFBBF7D0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Thực đơn đề xuất từ AI Coach:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  mealSuggestion!.menu,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: context.textPrimary(),
                  ),
                ),
                if (mealSuggestion!.nutritionNotes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Lưu ý dinh dưỡng: ${mealSuggestion!.nutritionNotes}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: context.textSecondary(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Action button: AI Menu Assistant
        Center(
          child: TextButton.icon(
            onPressed: onRequestAiMeal,
            icon: const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: Color(0xFF0F5B38),
            ),
            label: const Text(
              'Gợi ý thực đơn theo nguyên liệu sẵn có trong tủ lạnh',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F5B38),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealMilestone({
    required BuildContext context,
    required String timeStr,
    required String title,
    required String recommendation,
    required IconData icon,
    required Color iconColor,
    required bool isPassed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorder(), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary(),
                        ),
                      ),
                    ),
                    if (isPassed) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  recommendation,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: context.textSecondary(),
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
