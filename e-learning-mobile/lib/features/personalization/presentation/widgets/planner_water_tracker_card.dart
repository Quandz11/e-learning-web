import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

class PlannerWaterTrackerCard extends StatelessWidget {
  const PlannerWaterTrackerCard({
    super.key,
    required this.currentWaterMl,
    required this.targetWaterMl,
    required this.onLogWater,
    this.onQuickAdd,
    this.onLearnMore,
  });

  final int currentWaterMl;
  final int targetWaterMl;
  final VoidCallback onLogWater;
  final ValueChanged<int>? onQuickAdd;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final progress = (targetWaterMl > 0 ? (currentWaterMl / targetWaterMl) : 0.0)
        .clamp(0.0, 1.0);
    final percentInt = (progress * 100).toInt();

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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Bottle illustration container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0C4A6E)
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF0369A1)
                        : const Color(0xFFBAE6FD),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.local_drink_rounded,
                    size: 24,
                    color: isDark
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nước',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary(),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentWaterMl > 0
                          ? 'Đã uống $currentWaterMl / $targetWaterMl ml ($percentInt%)'
                          : 'Uống $targetWaterMl ml hôm nay',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.textSecondary(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action button: + GHI NƯỚC
              InkWell(
                onTap: onLogWater,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? context.colorScheme.surfaceContainerHighest
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.cardBorder(),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: context.textPrimary(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GHI NƯỚC',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: context.textPrimary(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Progress line
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? const Color(0xFF0C4A6E)
                  : const Color(0xFFF0F9FF),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quick 1-tap add buttons row
          Row(
            children: [
              _buildQuickButton(
                context: context,
                label: '+150ml',
                sublabel: 'Cỡ nhỏ',
                onTap: () => onQuickAdd?.call(150),
              ),
              const SizedBox(width: 6),
              _buildQuickButton(
                context: context,
                label: '+250ml',
                sublabel: 'Cỡ vừa',
                isHighlight: true,
                onTap: () => onQuickAdd?.call(250),
              ),
              const SizedBox(width: 6),
              _buildQuickButton(
                context: context,
                label: '+500ml',
                sublabel: 'Cỡ lớn',
                onTap: () => onQuickAdd?.call(500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required BuildContext context,
    required String label,
    required String sublabel,
    bool isHighlight = false,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isHighlight
                ? (isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE))
                : (isDark
                    ? context.colorScheme.surfaceContainerHighest
                    : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlight
                  ? const Color(0xFF0284C7)
                  : context.cardBorder(),
              width: isHighlight ? 1.0 : 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isHighlight
                      ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                      : context.textPrimary(),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 9,
                  color: context.textMuted(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
