import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../models/referral_models.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository(ref.read(apiClientProvider));
});

class ReferralRepository {
  ReferralRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserReferralModel> getMyReferral() async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      '/user/referral/my-referral',
    );
    return UserReferralModel.fromJson(data);
  }

  Future<UserReferralModel> generate() async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      '/user/referral/generate',
    );
    return UserReferralModel.fromJson(data);
  }
}
