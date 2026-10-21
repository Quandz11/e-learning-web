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

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'phone': phone,
    'role': role,
    'status': status,
    'avatarUrl': avatarUrl,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'isTwoFactorEnabled': isTwoFactorEnabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Profile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    String? status,
    String? avatarUrl,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isTwoFactorEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
