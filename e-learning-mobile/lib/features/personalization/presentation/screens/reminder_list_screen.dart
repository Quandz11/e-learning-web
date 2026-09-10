import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/notifications/services/notification_service.dart';
import 'package:e_learning_mobile/features/personalization/data/personalization_repository.dart';
import 'package:e_learning_mobile/features/personalization/domain/reminder_model.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A2520),
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
        title: const Text(
          'Danh sách nhắc nhở',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: -0.3,
            color: Color(0xFF1A2520),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Thử nghiệm thông báo',
            icon: const Icon(
              Icons.notifications_active_outlined,
              size: 22,
              color: Color(0xFF0F5B38),
            ),
            onPressed: () async {
              await NotificationService.instance.sendTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi thông báo nhắc nhở thử nghiệm đến thiết bị!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: const Color(0xFFF9FBF9),
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
                    color: const Color(0xFFEFEFEF),
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
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _selectedTabIndex == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
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
                                    ? const Color(0xFF1A2520)
                                    : const Color(0xFF6B7280),
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
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _selectedTabIndex == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
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
                                    ? const Color(0xFF1A2520)
                                    : const Color(0xFF6B7280),
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
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.notifications_off_outlined,
                                size: 26,
                                color: Color(0xFF0F5B38),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Chưa có lịch nhắc nhở nào',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF1A2520),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Tạo nhắc nhở uống nước hoặc vào bữa ăn để giữ nhịp sinh học.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF6B7280),
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
                        backgroundColor: const Color(0xFF0F5B38),
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: const Color(0xFFEAEFE9),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(rem.type.icon, color: const Color(0xFF0F5B38), size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rem.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2520),
                      ),
                    ),
                    if (rem.message.isNotEmpty)
                      Text(
                        rem.message,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: rem.enabled,
                activeColor: const Color(0xFF0F5B38),
                onChanged: (val) {
                  ref
                      .read(personalizationStateProvider.notifier)
                      .toggleReminder(rem.id, val);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(
            color: Color(0xFFEAEFE9),
            thickness: 0.8,
            height: 1,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 4),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A2520),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                Icons.repeat_rounded,
                size: 15,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 4),
              Text(
                rem.repeatDays.length == 7 ? 'Hằng ngày' : 'T2 - CN',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(0xFF586B60),
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

