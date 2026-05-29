import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../models/wellness_ai_models.dart';

final wellnessAiRepositoryProvider = Provider<WellnessAiRepository>((ref) {
  return WellnessAiRepository(ref.read(apiClientProvider));
});

class WellnessAiRepository {
  WellnessAiRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getWellnessDashboard() async {
    return _apiClient.get<Map<String, dynamic>>('/wellness/dashboard');
  }

  Future<Map<String, dynamic>> upsertWellnessPlan(
    Map<String, dynamic> payload,
  ) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/wellness/plan',
      data: payload,
    );
  }

  Future<Map<String, dynamic>> getAiDashboard() async {
    return _apiClient.get<Map<String, dynamic>>('/ai/plan/dashboard');
  }

  Future<AiStatusModel> getAiStatus() async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      '/ai/settings/status',
    );
    return AiStatusModel.fromJson(data);
  }

  Future<Map<String, dynamic>> aiChat(String prompt) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/ai/chat',
      data: {'prompt': prompt},
    );
  }
}
