import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      return ProfileController(ref.read(profileRepositoryProvider));
    });

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (state.status == ProfileStatus.loading) {
      return;
    }

    state = ProfileState(
      status: ProfileStatus.loading,
      profile: refresh ? state.profile : null,
    );

    try {
      final profile = await _repository.getProfile();
      state = ProfileState(status: ProfileStatus.success, profile: profile);
    } catch (error) {
      state = ProfileState(
        status: ProfileStatus.failure,
        profile: state.profile,
        message: error.toString(),
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  void updateProfile(Profile profile) {
    state = ProfileState(status: ProfileStatus.success, profile: profile);
  }
}
