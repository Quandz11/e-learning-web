import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

class PlannerDailyTipsSection extends StatelessWidget {
  const PlannerDailyTipsSection({
    super.key,
    this.todayInsight,
    this.onTapArticle,
  });

  final WellnessInsight? todayInsight;
  final VoidCallback? onTapArticle;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final tipText = todayInsight?.tip.isNotEmpty == true
        ? todayInsight!.tip
        : 'Uống nước ấm vào buổi sáng giúp kích hoạt nhu động ruột và tăng trao đổi chất tự nhiên.';

    final summaryText = todayInsight?.summary.isNotEmpty == true
        ? todayInsight!.summary
        : 'Cơ thể thích nghi tốt nhất khi bạn duy trì khung giờ ăn uống đều đặn và ngủ đủ giấc mỗi đêm.';

    final risksText = todayInsight?.risks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Lời khuyên Hàng ngày từ Huấn luyện viên
        Container(
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B2F10)
                      : const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 24,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mẹo hàng ngày',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted(),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tối ưu hóa năng lượng & Trao đổi chất',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tipText,
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
        ),
        const SizedBox(height: 12),

        // 2. Tóm tắt tình trạng sinh học hoặc Lưu ý
        if (risksText != null && risksText.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2E1B4D)
                        : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      size: 22,
                      color: Color(0xFF9333EA),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lưu ý an toàn sức khỏe',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        risksText,
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
          ),
          const SizedBox(height: 12),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2E1B4D)
                        : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.insights_rounded,
                      size: 22,
                      color: Color(0xFF9333EA),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đốt mỡ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summaryText,
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
          ),
          const SizedBox(height: 12),
        ],

        // 3. Bài đọc hướng dẫn lối sống
        InkWell(
          onTap: onTapArticle,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3E1F1F)
                        : const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 22,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kiến thức Wellness',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: context.textMuted(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kho bài viết khoa học & Bài tập thở điều hòa nhịp tim',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary(),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: context.textMuted(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
