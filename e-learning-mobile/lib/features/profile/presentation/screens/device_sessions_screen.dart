import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/session/session_controller.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/auth/data/models/logout_request.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_theme_extensions.dart';
import '../../../../shared/widgets/app_page.dart';
import '../../data/device_sessions_repository.dart';

class DeviceSessionsScreen extends ConsumerStatefulWidget {
  const DeviceSessionsScreen({super.key});

  @override
  ConsumerState<DeviceSessionsScreen> createState() =>
      _DeviceSessionsScreenState();
}

class _DeviceSessionsScreenState extends ConsumerState<DeviceSessionsScreen> {
  bool _busy = false;
  String? _error;

  // Optimistic local copy — updated immediately on revoke so UI doesn't flash loading
  List<DeviceSession>? _localSessions;

  Future<void> _revoke(DeviceSession? session) async {
    if (_busy) return;
    final isRevokeAllOthers = session == null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isRevokeAllOthers
              ? 'Đăng xuất các thiết bị khác?'
              : 'Đăng xuất thiết bị?',
        ),
        content: Text(
          isRevokeAllOthers
              ? 'Bạn sẽ đăng xuất khỏi tất cả các thiết bị khác ngoại trừ thiết bị đang sử dụng này.'
              : 'Bạn có chắc chắn muốn đăng xuất khỏi "${session.deviceName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (session?.isCurrent == true) {
        final current = ref.read(sessionControllerProvider).session;
        await ref
            .read(authRepositoryProvider)
            .logout(LogoutRequest(refreshToken: current?.refreshToken));
        await ref.read(sessionControllerProvider.notifier).clearSession();
        return;
      }

      final repository = ref.read(deviceSessionsRepositoryProvider);
      if (isRevokeAllOthers) {
        await repository.revokeOthers();
        // Optimistic: keep only current session
        if (mounted && _localSessions != null) {
          setState(() {
            _localSessions = _localSessions!.where((s) => s.isCurrent).toList();
          });
        }
      } else {
        await repository.revoke(session.id);
        // Optimistic: remove the specific session
        if (mounted && _localSessions != null) {
          setState(() {
            _localSessions = _localSessions!
                .where((s) => s.id != session.id)
                .toList();
          });
        }
      }

      // Sync in background without showing loading state
      ref.invalidate(deviceSessionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRevokeAllOthers
                  ? 'Đã đăng xuất khỏi các thiết bị khác thành công.'
                  : 'Đã đăng xuất khỏi "${session.deviceName}".',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không thể đăng xuất thiết bị. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  IconData _deviceIcon(String platform, String deviceName) {
    final text = '${platform.toLowerCase()} ${deviceName.toLowerCase()}';
    if (text.contains('ipad') || text.contains('tablet')) {
      return Icons.tablet_mac_rounded;
    } else if (text.contains('iphone') ||
        text.contains('android') ||
        text.contains('mobile') ||
        text.contains('phone')) {
      return Icons.smartphone_rounded;
    } else if (text.contains('mac') ||
        text.contains('windows') ||
        text.contains('linux') ||
        text.contains('pc') ||
        text.contains('web')) {
      return Icons.laptop_chromebook_rounded;
    }
    return Icons.devices_rounded;
  }

  String _formatPlatform(String platform) {
    final p = platform.trim().toLowerCase();
    if (p == 'web') return 'Trình duyệt Web';
    if (p == 'android') return 'Android';
    if (p == 'ios') return 'iOS';
    if (p == 'windows') return 'Windows';
    if (p == 'macos' || p == 'mac') return 'macOS';
    if (p == 'linux') return 'Linux';
    return platform.isNotEmpty ? platform : 'Không rõ HĐH';
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(deviceSessionsProvider);
    final format = DateFormat('HH:mm - dd/MM/yyyy');
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    // Sync local copy when provider delivers fresh data
    sessionsAsync.whenData((rows) {
      if (_localSessions == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _localSessions = List.of(rows));
        });
      }
    });

    return AppPage(
      appBarTitle: 'Thiết bị & Phiên đăng nhập',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.cardBorder(), width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: context.textSecondary(),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Dưới đây là danh sách các thiết bị đang đăng nhập tài khoản của bạn. Bạn có thể đăng xuất khỏi các phiên không nhận diện.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: context.textSecondary(),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Use local sessions if available (optimistic), else fall back to provider
          if (_localSessions != null)
            _buildSessionList(
              context,
              _localSessions!,
              format,
              isDark,
              colorScheme,
            )
          else
            sessionsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 8),
                      const Text('Không thể tải danh sách phiên đăng nhập.'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(deviceSessionsProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (rows) =>
                  _buildSessionList(context, rows, format, isDark, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    List<DeviceSession> rows,
    DateFormat format,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('Không có phiên đăng nhập nào.'),
        ),
      );
    }

    final hasOtherSessions = rows.any((s) => !s.isCurrent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) ...[
          _buildSessionCard(context, row, format, isDark, colorScheme),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (hasOtherSessions) ...[
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _revoke(null),
            icon: const Icon(Icons.phonelink_erase_rounded, size: 18),
            label: const Text('Đăng xuất các thiết bị khác'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextButton.icon(
          onPressed: _busy
              ? null
              : () {
                  setState(() => _localSessions = null);
                  ref.invalidate(deviceSessionsProvider);
                },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Làm mới danh sách'),
        ),
      ],
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    DeviceSession row,
    DateFormat format,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: row.isCurrent
              ? AppColors.primary.withValues(alpha: 0.4)
              : context.cardBorder(),
          width: row.isCurrent ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: row.isCurrent
                      ? (isDark
                            ? const Color(0xFF143823)
                            : const Color(0xFFF0FDF4))
                      : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _deviceIcon(row.platform, row.deviceName),
                  color: row.isCurrent
                      ? const Color(0xFF16A34A)
                      : context.textSecondary(),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            row.deviceName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: context.textPrimary(),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (row.isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF14532D)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              'Thiết bị này',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatPlatform(row.platform)} • ${row.browser.isNotEmpty ? row.browser : 'Ứng dụng SKVI'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: context.cardBorder()),
          const SizedBox(height: AppSpacing.sm),
          // Info row: IP + last activity
          if (row.ip.isNotEmpty)
            Text(
              'IP: ${row.ip}',
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary(),
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (row.ip.isNotEmpty) const SizedBox(height: 2),
          Text(
            'Hoạt động: ${format.format(row.lastActiveAt.toLocal())}',
            style: TextStyle(
              fontSize: 11,
              color: context.textMuted(),
            ),
          ),
          if (!row.isCurrent) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _revoke(row),
                icon: const Icon(Icons.logout_rounded, size: 14),
                label: const Text('Đăng xuất'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
