import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

class PlannerFastingTrackerCard extends StatelessWidget {
  const PlannerFastingTrackerCard({
    super.key,
    required this.fastingStatus,
    this.plan,
    required this.onEditSchedule,
    required this.onAnswerMood,
    this.coachReply,
  });

  final WellnessFastingStatus? fastingStatus;
  final WellnessPlan? plan;
  final VoidCallback onEditSchedule;
  final VoidCallback onAnswerMood;
  final WellnessCoachReply? coachReply;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final remainingMinutes = fastingStatus?.remainingMinutes ?? 0;
    final hours = remainingMinutes ~/ 60;
    final mins = remainingMinutes % 60;
    final remainingText = '$hours giờ $mins phút';

    final isFasting = fastingStatus?.state.toUpperCase() == 'FASTING';
    final progress = ((fastingStatus?.progressPercent ?? 0.0) / 100.0).clamp(
      0.0,
      1.0,
    );

    // Format start and end times
    final startStr = fastingStatus != null
        ? '${fastingStatus!.windowStartLocal.hour.toString().padLeft(2, '0')}:${fastingStatus!.windowStartLocal.minute.toString().padLeft(2, '0')}'
        : '20:00';
    final endStr = fastingStatus != null
        ? '${fastingStatus!.windowEndLocal.hour.toString().padLeft(2, '0')}:${fastingStatus!.windowEndLocal.minute.toString().padLeft(2, '0')}'
        : '12:00';

    final fastHours = plan?.fastingHours ?? 16;
    final elapsedHours = isFasting ? (progress * fastHours) : 0.0;

    // Biological Fasting Phase calculation
    final _BioPhase bioPhase = _calculateBioPhase(isFasting, elapsedHours);

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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Title & Remaining time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch trình nhịn ăn của bạn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary(),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFasting
                          ? 'Thời gian nhịn ăn còn lại'
                          : 'Thời gian ăn uống còn lại',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: context.textMuted(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remainingText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onEditSchedule,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: context.textSecondary(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segment labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nhịn ăn',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF2563EB),
                ),
              ),
              Text(
                'Ăn uống',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dual-color progress timeline bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final fastH = (plan?.fastingHours ?? 16).clamp(1, 24);
                  final eatH = (plan?.eatingHours ?? 8).clamp(1, 24);
                  final totalFlex = fastH + eatH;
                  final fastingWidth =
                      (totalWidth * (fastH / totalFlex)).clamp(0.0, totalWidth);
                  final eatingWidth =
                      (totalWidth - fastingWidth).clamp(0.0, totalWidth);

                  return Row(
                    children: [
                      // Fasting portion (blue)
                      Container(
                        width: fastingWidth,
                        color: isDark
                            ? const Color(0xFF1E3A8A)
                            : const Color(0xFFDBEAFE),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: fastingWidth * (isFasting ? progress : 1.0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      // Eating portion (green)
                      Container(
                        width: eatingWidth,
                        color: isDark
                            ? const Color(0xFF064E3B)
                            : const Color(0xFFD1FAE5),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: eatingWidth * (!isFasting ? progress : 0.0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF10B981)
                                : const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Timeline Start / End labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Bắt đầu $startStr',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: context.textMuted(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Kết thúc $endStr',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: context.textMuted(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Real Biological Phase Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? context.colorScheme.surfaceContainerHighest
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cardBorder(), width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bioPhase.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(bioPhase.icon, size: 20, color: bioPhase.color),
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
                              bioPhase.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary(),
                              ),
                            ),
                          ),
                          if (isFasting)
                            Text(
                              '${elapsedHours.toStringAsFixed(1)}h trôi qua',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: bioPhase.color,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        bioPhase.description,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: context.textSecondary(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Divider
          Divider(
            height: 1,
            thickness: 0.8,
            color: context.cardBorder().withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),

          // Bottom Check-in question row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cơ thể bạn hôm nay cảm thấy thế nào?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onAnswerMood,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? context.colorScheme.surfaceContainerHighest
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: context.cardBorder(),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        coachReply != null
                            ? Icons.check_circle_outline_rounded
                            : Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: coachReply != null
                            ? const Color(0xFF10B981)
                            : context.textSecondary(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        coachReply != null ? 'ĐỔI Ý' : 'TRẢ LỜI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: context.textPrimary(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // If coach replied, show subtle preview
          if (coachReply != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF13221C)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E3A2F)
                      : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      coachReply!.reply,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFF166534),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  _BioPhase _calculateBioPhase(bool isFasting, double elapsedHours) {
    if (!isFasting) {
      return const _BioPhase(
        title: 'Khung giờ Nạp Năng Lượng (Ăn uống)',
        description:
            'Bổ sung đủ protein, rau xanh và chất béo lành mạnh để cơ thể nạp năng lượng.',
        icon: Icons.restaurant_rounded,
        color: Color(0xFF10B981),
      );
    }

    if (elapsedHours < 4) {
      return const _BioPhase(
        title: 'Giai đoạn 1: Ổn định đường huyết (0 - 4h)',
        description:
            'Cơ thể đang tiêu hóa bữa ăn cuối, lượng đường và insulin trong máu dần hạ về mức cân bằng.',
        icon: Icons.water_drop_outlined,
        color: Color(0xFF3B82F6),
      );
    } else if (elapsedHours < 8) {
      return const _BioPhase(
        title: 'Giai đoạn 2: Hệ tiêu hóa nghỉ ngơi (4 - 8h)',
        description:
            'Dạ dày trống, insulin giảm. Cơ thể bắt đầu chuyển từ dùng glucose sang sử dụng glycogen dự trữ.',
        icon: Icons.spa_outlined,
        color: Color(0xFF6366F1),
      );
    } else if (elapsedHours < 12) {
      return const _BioPhase(
        title: 'Giai đoạn 3: Bắt đầu Đốt mỡ thừa (8 - 12h)',
        description:
            'Nguồn glycogen giảm sâu, gan bắt đầu chuyển hóa tế bào mỡ thừa thành Ketone tạo năng lượng.',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFF97316),
      );
    } else {
      return const _BioPhase(
        title: 'Giai đoạn 4: Đốt mỡ sâu & Autophagy (12h+)',
        description:
            'Kích hoạt trạng thái tự thực bào: Tế bào tự thanh lọc độc tố, sửa chữa protein hư hỏng.',
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFF10B981),
      );
    }
  }
}

class _BioPhase {
  const _BioPhase({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
