import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';

class DeviceSession {
  DeviceSession.fromJson(Map<String, dynamic> json)
      : id = json['sessionId'] as String, deviceName = json['deviceName'] as String? ?? 'Không rõ thiết bị',
        platform = json['platform'] as String? ?? '', browser = json['browser'] as String? ?? '',
        ip = json['ipAddress'] as String? ?? '', isCurrent = json['isCurrentSession'] == true,
        loginTime = DateTime.parse(json['loginTime'] as String),
        lastActiveAt = DateTime.parse((json['lastActiveAt'] ?? json['loginTime']) as String);
  final String id, deviceName, platform, browser, ip;
  final DateTime loginTime, lastActiveAt;
  final bool isCurrent;
}

final deviceSessionsRepositoryProvider = Provider((ref) => DeviceSessionsRepository(ref.watch(apiClientProvider)));
final deviceSessionsProvider = FutureProvider.autoDispose((ref) => ref.watch(deviceSessionsRepositoryProvider).list());

class DeviceSessionsRepository {
  const DeviceSessionsRepository(this._api);
  final ApiClient _api;
  Future<List<DeviceSession>> list() async {
    final rows = await _api.get<List<dynamic>>('/auth/sessions');
    return rows.map((row) => DeviceSession.fromJson(row as Map<String, dynamic>)).toList();
  }
  Future<void> revoke(String id) async {
    await _api.post<Object?>('/auth/sessions/revoke', data: {'sessionId': id});
  }
  Future<void> revokeOthers() async { await _api.post<Object?>('/auth/sessions/revoke-all'); }
}
