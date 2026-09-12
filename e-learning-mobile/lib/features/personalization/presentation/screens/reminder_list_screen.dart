import 'package:e_learning_mobile/core/notifications/local_notification_service.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/personalization/data/personalization_repository.dart';
import 'package:e_learning_mobile/features/personalization/domain/reminder_model.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReminderListScreen extends ConsumerStatefulWidget {
  const ReminderListScreen({super.key});

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalizationStateProvider);
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FBF9),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary(),
            size: 18,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/app/wellness');
            }
          },
        ),
        title: Text(
          'Danh sách nhắc nhở',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: -0.3,
            color: context.textPrimary(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Thử nghiệm thông báo',
            icon: Icon(
              Icons.notifications_active_outlined,
              size: 22,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
            ),
            onPressed: () async {
              await LocalNotificationService.instance.showImmediateNotification(
                id: 8888,
                title: '🌱 Nhắc nhở Sức khỏe & Học tập',
                body: 'Đã đến giờ uống nước lọc và hoàn thành bài học hôm nay!',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔔 Đã kích hoạt thông báo nhắc nhở tức thì đến thiết bị!'),
                    backgroundColor: Color(0xFF0F5B38),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FBF9),
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Lỗi: $err',
            style: const TextStyle(
              fontWeight: FontWeight.w300,
              color: Colors.red,
            ),
          ),
        ),
        data: (profile) {
          final reminders = profile.reminders;
          return Column(
            children: [
              // Segmented Pill Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0
                                  ? (isDark ? colorScheme.surfaceContainerHigh : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _selectedTabIndex == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Nhắc nhở chung',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: _selectedTabIndex == 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: _selectedTabIndex == 0
                                    ? context.textPrimary()
                                    : context.textSecondary(),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1
                                  ? (isDark ? colorScheme.surfaceContainerHigh : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _selectedTabIndex == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Lịch nhắc nhở',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: _selectedTabIndex == 1
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: _selectedTabIndex == 1
                                    ? context.textPrimary()
                                    : context.textSecondary(),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: reminders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                size: 26,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Chưa có lịch nhắc nhở nào',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: context.textPrimary(),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tạo nhắc nhở uống nước hoặc vào bữa ăn để giữ nhịp sinh học.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: context.textSecondary(),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          final rem = reminders[index];
                          return _buildReminderCard(context, ref, rem);
                        },
                      ),
              ),

              // Bottom Sticky Minimalist Pill CTA
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push(AppRoutes.appPersonalizationReminderNew);
                      },
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Thêm nhắc nhở mới',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF108A55) : const Color(0xFF0F5B38),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, WidgetRef ref, Reminder rem) {
    final timeStr =
        '${rem.startTimeHour.toString().padLeft(2, '0')}:${rem.startTimeMinute.toString().padLeft(2, '0')}';
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.cardBorder(),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  rem.type.icon,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rem.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary(),
                      ),
                    ),
                    if (rem.message.isNotEmpty)
                      Text(
                        rem.message,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: context.textSecondary(),
                        ),
                      ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: rem.enabled,
                activeColor: isDark ? const Color(0xFF34D399) : const Color(0xFF0F5B38),
                onChanged: (val) {
                  ref
                      .read(personalizationStateProvider.notifier)
                      .toggleReminder(rem.id, val);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(
            color: context.cardBorder(),
            thickness: 0.8,
            height: 1,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 15,
                color: context.textMuted(),
              ),
              const SizedBox(width: 4),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: context.textPrimary(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                Icons.repeat_rounded,
                size: 15,
                color: context.textMuted(),
              ),
              const SizedBox(width: 4),
              Text(
                rem.repeatDays.length == 7 ? 'Hằng ngày' : 'T2 - CN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: context.textSecondary(),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: context.textSecondary(),
                ),
                onPressed: () {
                  context.push(AppRoutes.reminderEditPath(rem.id));
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onPressed: () {
                  ref
                      .read(personalizationStateProvider.notifier)
                      .deleteReminder(rem.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

