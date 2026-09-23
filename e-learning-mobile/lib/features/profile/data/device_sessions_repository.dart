import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';

class DeviceSession {
  DeviceSession.fromJson(Map<String, dynamic> json)
      : id = (json['sessionId'] ?? json['id'] ?? '').toString(),
        deviceName = (json['deviceName'] ?? 'Không rõ thiết bị').toString(),
        platform = (json['platform'] ?? '').toString(),
        browser = (json['browser'] ?? '').toString(),
        ip = (json['ipAddress'] ?? json['ip'] ?? '').toString(),
        isCurrent = json['isCurrentSession'] == true || json['isCurrent'] == true,
        loginTime = DateTime.tryParse(json['loginTime']?.toString() ?? '') ?? DateTime.now(),
        lastActiveAt = DateTime.tryParse((json['lastActiveAt'] ?? json['loginTime'])?.toString() ?? '') ?? DateTime.now();
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
    final response = await _api.get<dynamic>('/auth/sessions');
    final List<dynamic> rows;
    if (response is List) {
      rows = response;
    } else if (response is Map && response['data'] is List) {
      rows = response['data'] as List;
    } else {
      rows = [];
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map(DeviceSession.fromJson)
        .toList();
  }
  Future<void> revoke(String id) async {
    await _api.post<Object?>('/auth/sessions/revoke', data: {'sessionId': id});
  }
  Future<void> revokeOthers() async { await _api.post<Object?>('/auth/sessions/revoke-all'); }
}
