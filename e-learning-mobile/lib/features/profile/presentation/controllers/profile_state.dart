import 'package:e_learning_mobile/features/profile/data/models/profile.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.message,
  });

  final ProfileStatus status;
  final Profile? profile;
  final String? message;

  bool get isLoading => status == ProfileStatus.loading && profile == null;

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    bool clearProfile = false,
    String? message,
    bool clearMessage = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
