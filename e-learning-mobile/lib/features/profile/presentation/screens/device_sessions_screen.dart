import '../../../auth/data/models/logout_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../shared/widgets/app_page.dart';
import '../../data/device_sessions_repository.dart';

class DeviceSessionsScreen extends ConsumerStatefulWidget {
  const DeviceSessionsScreen({super.key});
  @override
  ConsumerState<DeviceSessionsScreen> createState() => _DeviceSessionsScreenState();
}

class _DeviceSessionsScreenState extends ConsumerState<DeviceSessionsScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _revoke(DeviceSession? session) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Đăng xuất thiết bị?'),
      content: Text(session == null ? 'Đăng xuất tất cả thiết bị khác?' : 'Đăng xuất ${session.deviceName}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất'))],
    ));
    if (confirmed != true || !mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (session?.isCurrent == true) {
        final current = ref.read(sessionControllerProvider).session;
        await ref.read(authRepositoryProvider).logout(LogoutRequest(refreshToken: current?.refreshToken));
        await ref.read(sessionControllerProvider.notifier).clearSession();
      } else {
        final repository = ref.read(deviceSessionsRepositoryProvider);
        if (session == null) { await repository.revokeOthers(); } else { await repository.revoke(session.id); }
        ref.invalidate(deviceSessionsProvider);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể đăng xuất thiết bị. Vui lòng thử lại.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(sessionControllerProvider.select((s) => s.session?.role));
    if (role == 'ADMIN') return const AppPage(appBarTitle: 'Thiết bị đăng nhập', child: Text('Quản lý phiên admin trên web.'));
    final sessions = ref.watch(deviceSessionsProvider);
    final format = DateFormat('dd/MM/yyyy HH:mm');
    return AppPage(appBarTitle: 'Thiết bị đăng nhập', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        sessions.when(loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => TextButton(onPressed: () => ref.invalidate(deviceSessionsProvider), child: const Text('Không thể tải danh sách. Thử lại')),
          data: (rows) => Column(children: [
            if (rows.isEmpty) const Text('Không có phiên đăng nhập.'),
            for (final row in rows) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${row.deviceName}${row.isCurrent ? ' • Thiết bị này' : ''}', style: Theme.of(context).textTheme.titleMedium),
                Text('${row.platform} • ${row.browser}\nIP: ${row.ip}'),
                Text('Đăng nhập: ${format.format(row.loginTime.toLocal())}\nHoạt động: ${format.format(row.lastActiveAt.toLocal())}'),
                TextButton(onPressed: _busy ? null : () => _revoke(row), child: const Text('Đăng xuất')),
              ],
            ))),
            if (rows.any((s) => !s.isCurrent)) OutlinedButton(onPressed: _busy ? null : () => _revoke(null),
              child: const Text('Đăng xuất các thiết bị khác')),
            TextButton(onPressed: _busy ? null : () => ref.invalidate(deviceSessionsProvider), child: const Text('Làm mới')),
          ])),
      ],
    ));
  }
}
