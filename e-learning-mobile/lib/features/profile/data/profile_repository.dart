import 'package:e_learning_mobile/features/profile/data/models/change_password_request.dart';
import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/data/models/update_profile_request.dart';
import 'package:e_learning_mobile/features/profile/data/profile_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(api: ref.read(profileApiProvider));
});

class ProfileRepository {
  const ProfileRepository({required ProfileApi api}) : _api = api;

  final ProfileApi _api;

  Future<Profile> getProfile() => _api.getProfile();

  Future<Profile> updateProfile(UpdateProfileRequest request) {
    return _api.updateProfile(request);
  }

  Future<String> changePassword(ChangePasswordRequest request) {
    return _api.changePassword(request);
  }
}
