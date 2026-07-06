class UserProfile {
  final int userId;
  final String displayId;
  final String name;
  final String email;
  final String? phone;
  final String? profilePic;
  final String role;
  final bool isEmailVerified;
  final DateTime createdAt;

  UserProfile({
    required this.userId,
    required this.displayId,
    required this.name,
    required this.email,
    this.phone,
    this.profilePic,
    required this.role,
    required this.isEmailVerified,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? 0,
      displayId: json['displayId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profilePic: json['profilePic'],
      role: json['role'] ?? 'STUDENT',
      isEmailVerified: json['isEmailVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayId': displayId,
    'name': name,
    'email': email,
    'phone': phone,
    'profilePic': profilePic,
    'role': role,
    'isEmailVerified': isEmailVerified,
    'createdAt': createdAt.toIso8601String(),
  };
}

class UpdateProfileRequest {
  final String? name;
  final String? phone;

  UpdateProfileRequest({this.name, this.phone});

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
  };
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  };
}