class AuthResponse {
  final bool success;
  final String message;
  final AuthData? data;

  AuthResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
    );
  }
}

// ✅ AUTH DATA - COMPLETE
class AuthData {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String role;
  final int userId;
  final String displayId;
  final String name;
  final String email;
  final String? phone; // ✅ ADDED - Phone from API
  final bool isEmailVerified;
  final String? profileImage; // Profile image URL from server

  AuthData({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.role,
    required this.userId,
    required this.displayId,
    required this.name,
    required this.email,
    this.phone,
    required this.isEmailVerified,
    this.profileImage,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      tokenType: json['tokenType'] ?? '',
      role: json['role'] ?? '',
      userId: json['userId'] ?? 0,
      displayId: json['displayId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'], // ✅ ADDED
      isEmailVerified: json['isEmailVerified'] ?? false,
      profileImage: json['profilePic'] ?? json['profileImage'] ?? json['profile_image'], // ✅ Support all formats
    );
  }

  // ✅ COPYWITH - FIXED
  AuthData copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    String? role,
    int? userId,
    String? displayId,
    String? name,
    String? email,
    String? phone,
    bool? isEmailVerified,
    String? profileImage,
  }) {
    return AuthData(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      displayId: displayId ?? this.displayId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  // ✅ TOJSON - FIXED
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'tokenType': tokenType,
    'role': role,
    'userId': userId,
    'displayId': displayId,
    'name': name,
    'email': email,
    'phone': phone,
    'isEmailVerified': isEmailVerified,
    'profileImage': profileImage,
  };
}

// ✅ REGISTER REQUEST
// ✅ FIND THIS CLASS
class RegisterRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String? referralCode; // ✅ YEH LINE ADD KARO

  RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.referralCode, // ✅ YEH LINE ADD KARO
  });

  Map<String, dynamic> toJson() {
    final data = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };
    
    // ✅ YEH IF BLOCK ADD KARO
    if (referralCode != null && referralCode!.isNotEmpty) {
      data['referralCode'] = referralCode!;
    }
    
    return data;
  }
}

// ✅ LOGIN REQUEST
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

// ✅ VERIFY OTP REQUEST
class VerifyOtpRequest {
  final String email;
  final String otp;

  VerifyOtpRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'otp': otp,
  };
}

// ✅ RESET PASSWORD REQUEST
class ResetPasswordRequest {
  final String email;
  final String otp;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'otp': otp,
    'newPassword': newPassword,
  };
}

// ✅ FORGOT PASSWORD REQUEST
class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
  };
}

// ✅ UPDATE PROFILE REQUEST
class UpdateProfileRequest {
  final String? name;
  final String? phone;
  final String? profileImage;

  UpdateProfileRequest({
    this.name,
    this.phone,
    this.profileImage,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
    if (profileImage != null) 'profileImage': profileImage,
  };
}

// ✅ CHANGE PASSWORD REQUEST
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