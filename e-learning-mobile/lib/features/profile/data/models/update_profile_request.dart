class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
  });

  final String fullName;
  final String? phone;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fullName': fullName,
    'phone': phone,
    'avatarUrl': avatarUrl,
  };
}
