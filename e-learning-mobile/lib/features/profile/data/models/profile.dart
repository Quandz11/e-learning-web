import 'package:e_learning_mobile/core/errors/app_failure.dart';

class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.status,
    required this.avatarUrl,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isTwoFactorEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final fullName = json['fullName'];
    final phone = json['phone'];
    final role = json['role'];
    final status = json['status'];
    final avatarUrl = json['avatarUrl'];
    final isEmailVerified = json['isEmailVerified'];
    final isPhoneVerified = json['isPhoneVerified'];
    final isTwoFactorEnabled = json['isTwoFactorEnabled'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];

    if (id is! String ||
        email is! String ||
        fullName is! String ||
        role is! String ||
        status is! String ||
        isEmailVerified is! bool ||
        isPhoneVerified is! bool ||
        isTwoFactorEnabled is! bool ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const AppFailure(
        type: AppFailureType.malformedResponse,
        message: 'The server returned an invalid profile response.',
      );
    }

    final created = DateTime.tryParse(createdAt)?.toUtc();
    final updated = DateTime.tryParse(updatedAt)?.toUtc();
    if (created == null || updated == null) {
      throw const AppFailure(
        type: AppFailureType.malformedResponse,
        message: 'The server returned an invalid profile response.',
      );
    }

    return Profile(
      id: id,
      email: email.trim(),
      fullName: fullName.trim(),
      phone: phone is String && phone.trim().isNotEmpty ? phone.trim() : null,
      role: role.trim(),
      status: status.trim(),
      avatarUrl: avatarUrl is String && avatarUrl.trim().isNotEmpty
          ? avatarUrl.trim()
          : null,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      isTwoFactorEnabled: isTwoFactorEnabled,
      createdAt: created,
      updatedAt: updated,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String status;
  final String? avatarUrl;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isTwoFactorEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
}
