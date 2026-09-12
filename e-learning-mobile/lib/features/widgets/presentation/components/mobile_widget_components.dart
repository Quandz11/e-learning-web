import 'package:flutter/material.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/features/widgets/domain/mobile_widget_models.dart';

/// 1. Home Screen Small Widget (2x2) - Chuỗi học tập & Mục tiêu ngày
class SmallStreakWidgetView extends StatelessWidget {
  final MobileWidgetStateData data;
  final VoidCallback? onTap;

  const SmallStreakWidgetView({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B2B23) : AppColors.surface;
    final primaryColor = isDark ? const Color(0xFF4CAF50) : AppColors.primary;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 165, maxHeight: 165),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2C3E35) : AppColors.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🔥',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  '${data.streakDays} ngày',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFF8A65) : const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: data.goalProgressRatio,
                        strokeWidth: 4,
                        backgroundColor: isDark ? const Color(0xFF2C3E35) : AppColors.mint,
                        color: primaryColor,
                      ),
                      Text(
                        '${(data.goalProgressRatio * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mục tiêu',
                        style: TextStyle(fontSize: 10, color: subTextColor),
                      ),
                      Text(
                        '${data.learnedMinutes}/${data.targetMinutes} p',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'SKVI Learning Widget',
              style: TextStyle(
                fontSize: 8.5,
                color: subTextColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. Home Screen Medium Widget (4x2) - Bài học dở dang (Course Resume)
class MediumCourseWidgetView extends StatelessWidget {
  final MobileWidgetStateData data;
  final VoidCallback? onTap;

  const MediumCourseWidgetView({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B2B23) : AppColors.surface;
    final primaryColor = isDark ? const Color(0xFF4CAF50) : AppColors.primary;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2C3E35) : AppColors.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C3E35) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_fill, size: 12, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Đang học',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '🔥 Chuỗi ${data.streakDays} ngày',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFFF8A65) : const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.activeCourseTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              data.nextLessonTitle,
              style: TextStyle(fontSize: 11, color: subTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiến độ khóa học',
                  style: TextStyle(fontSize: 10, color: subTextColor),
                ),
                Text(
                  '${data.activeCourseProgress}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: data.activeCourseProgress / 100.0,
                minHeight: 5,
                backgroundColor: isDark ? const Color(0xFF2C3E35) : AppColors.mint,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. Home Screen Large Widget (4x4) - Study Dashboard
class LargeDashboardWidgetView extends StatelessWidget {
  final MobileWidgetStateData data;
  final VoidCallback? onTap;

  const LargeDashboardWidgetView({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B2B23) : AppColors.surface;
    final primaryColor = isDark ? const Color(0xFF4CAF50) : AppColors.primary;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2C3E35) : AppColors.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bảng tin học tập',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '🔥 ${data.streakDays} ngày',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle Stats Row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14201B) : AppColors.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Đã học', '${data.learnedMinutes}p', textColor, subTextColor),
                  Container(height: 20, width: 1, color: isDark ? Colors.white24 : AppColors.border),
                  _buildStatItem('Mục tiêu', '${data.targetMinutes}p', textColor, subTextColor),
                  Container(height: 20, width: 1, color: isDark ? Colors.white24 : AppColors.border),
                  _buildStatItem('Tiến độ', '${(data.goalProgressRatio * 100).toInt()}%', primaryColor, subTextColor),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Active Course Detail Card
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF23362C) : AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'KHOÁ HỌC HIỆN TẠI',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${data.activeCourseProgress}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.activeCourseTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.nextLessonTitle,
                    style: TextStyle(fontSize: 10.5, color: subTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: data.activeCourseProgress / 100.0,
                      minHeight: 5,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reminder Bottom Row
            Row(
              children: [
                Icon(Icons.alarm, size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Nhắc học: ${data.nextReminderTime}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Học ngay',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valColor, Color labelColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valColor),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(fontSize: 9.5, color: labelColor),
        ),
      ],
    );
  }
}

/// 4. Lock Screen Circular Widget (1x1)
class LockScreenCircularWidgetView extends StatelessWidget {
  final MobileWidgetStateData data;

  const LockScreenCircularWidgetView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(color: Colors.white38, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: data.goalProgressRatio,
              strokeWidth: 3.5,
              color: const Color(0xFFFF7043),
              backgroundColor: Colors.white24,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 12)),
              Text(
                '${data.streakDays}d',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 5. Lock Screen Inline Widget
class LockScreenInlineWidgetView extends StatelessWidget {
  final MobileWidgetStateData data;

  const LockScreenInlineWidgetView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📚 ', style: TextStyle(fontSize: 12)),
          Text(
            '${data.learnedMinutes}/${data.targetMinutes} phút • Chuỗi ${data.streakDays} ngày 🔥',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 6. Lock Screen Rectangular Widget (2x1)
class LockScreenRectangularWidgetView extends StatelessWidget {
  final MobileWidgetStateData data;

  const LockScreenRectangularWidgetView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 54,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_filled, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                'Lịch học: ${data.nextReminderTime}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            data.nextLessonTitle,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 7. Rich Notification Center Preview Banner
class RichNotificationPreviewView extends StatelessWidget {
  final MobileWidgetStateData data;

  const RichNotificationPreviewView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF22332A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E4438) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'SKVI E-Learning • Nhắc học tập',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Bây giờ',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Đã đến giờ học hôm nay! 🎯',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bạn chỉ còn 5 phút để hoàn thành mục tiêu ngày và giữ chuỗi ${data.streakDays} ngày liên tục 🔥.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.goalProgressRatio,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white12 : AppColors.mint,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Hoãn 15p',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Học ngay',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
