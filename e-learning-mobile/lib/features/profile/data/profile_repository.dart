import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const _cacheKey = 'cached_user_profile_json';
  final ProfileApi _api;

  Future<Profile?> getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Profile.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheProfile(Profile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(profile.toJson()));
    } catch (_) {}
  }

  Future<Profile> getProfile() async {
    try {
      final profile = await _api.getProfile();
      await cacheProfile(profile);
      return profile;
    } catch (e) {
      final cached = await getCachedProfile();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Profile> updateProfile(UpdateProfileRequest request) async {
    final updated = await _api.updateProfile(request);
    await cacheProfile(updated);
    return updated;
  }

  Future<String> changePassword(ChangePasswordRequest request) {
    return _api.changePassword(request);
  }

  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileName,
  }) {
    return _api.uploadAvatar(bytes: bytes, fileName: fileName);
  }

  Future<String> deleteAccount() => _api.deleteAccount();
}
