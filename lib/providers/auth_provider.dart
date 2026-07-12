import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourhome/services/websocket_manager.dart';
import 'package:yourhome/services/fcm_service.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../providers/chat_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  AuthData? _user;
  bool _isLoading = false;
  String? _error;
  String? _localProfileImagePath;

  AuthData? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  String? get profileImage {
    if (_user?.profileImage != null && _user!.profileImage!.isNotEmpty) {
      return _user!.profileImage;
    }
    return _localProfileImagePath;
  }

  String getUserInitial() {
    if (_user == null) return 'U';
    final name = _user!.name.isNotEmpty ? _user!.name : _user!.email;
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String getUserDisplayName() {
    if (_user == null) return 'Guest';
    return _user!.name.isNotEmpty ? _user!.name : _user!.email.split('@').first;
  }

  String getUserEmail() {
    return _user?.email ?? '';
  }

  String? get accessToken => _user?.accessToken;
  String? get token => _user?.accessToken;

  Future<String?> getAccessToken() async {
    return await _storage.getAccessToken();
  }

  Future<String?> getRefreshToken() async {
    return await _storage.getRefreshToken();
  }

  Future<String?> getProfileImageFromStorage() async {
    return await _storage.getProfileImage();
  }

  Future<void> setProfileImage(String imageUrl) async {
    await _storage.setProfileImage(imageUrl);
    if (_user != null) {
      _user = _user!.copyWith(profileImage: imageUrl);
      notifyListeners();
    }
  }

  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  // ✅ FIXED: CORRECT REGISTER METHOD - NO EXTRA PARAMETER
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? profileImage,
    String? referralCode,
  }) async {
    _setLoading(true);
    _clearError();

    final request = RegisterRequest(
      name: name,
      email: email,
      password: password,
      phone: phone ?? '',
      referralCode: referralCode,
    );
    
    final response = await _authService.register(request);
    
    if (response.success && response.data != null) {
      _user = response.data;
      if (profileImage != null) {
        await saveLocalProfileImage(profileImage);
      }
      await _saveUserData(_user!);
      _setLoading(false);
      return true;
    } else {
      _error = response.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading(true);
    _clearError();

    final request = VerifyOtpRequest(email: email, otp: otp);
    final response = await _authService.verifyOtp(request);

    if (response.success && response.data != null) {
      _user = response.data;
      await _saveUserData(_user!);

      try {
        WebSocketManager().connect(
          token: _user!.accessToken,
          userId: _user!.userId,
        );
        print('✅ WebSocket connect triggered after OTP verify');
      } catch (e) {
        print('❌ Error connecting WebSocket after OTP verify: $e');
      }

      try {
        await FcmService.syncToken();
      } catch (e) {
        print('❌ Error syncing FCM token after OTP verify: $e');
      }

      _setLoading(false);
      return true;
    } else {
      _error = response.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    final request = LoginRequest(email: email, password: password);
    final response = await _authService.login(request);

    if (response.success && response.data != null) {
      _user = response.data;
      await _saveUserData(_user!);
      await loadLocalProfileImage();

      try {
        WebSocketManager().connect(
          token: _user!.accessToken,
          userId: _user!.userId,
        );
        print('✅ WebSocket connect triggered after login');
      } catch (e) {
        print('❌ Error connecting WebSocket after login: $e');
      }

      try {
        await FcmService.syncToken();
      } catch (e) {
        print('❌ Error syncing FCM token after login: $e');
      }

      _setLoading(false);
      return true;
    } else {
      _error = response.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resendOtp(String email, {String type = 'REGISTER'}) async {
    _setLoading(true);
    _clearError();

    final response = await _authService.resendOtp(email, type: type);

    if (response.success) {
      _setLoading(false);
      return true;
    } else {
      _error = response.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    final response = await _authService.forgotPassword(email);

    if (response.success) {
      _setLoading(false);
      return true;
    } else {
      _error = response.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    _setLoading(true);
    _clearError();

    final request = ResetPasswordRequest(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
    final response = await _authService.resetPassword(request);

    if (response.success) {
      _setLoading(false);
      return true;
    } else {
      _error = response.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfileImage(String imageUrl) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      _user = _user!.copyWith(profileImage: imageUrl);
      await _saveUserData(_user!);
      await _storage.setProfileImage(imageUrl);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> saveLocalProfileImage(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_profile_image', imagePath);
      _localProfileImagePath = imagePath;
      notifyListeners();
    } catch (e) {
      print('❌ Error saving local profile image: $e');
    }
  }

  Future<void> loadLocalProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('local_profile_image');
      if (path != null && path.isNotEmpty) {
        _localProfileImagePath = path;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading local profile image: $e');
    }
  }

  Future<void> loadLocalProfileImagePublic() async {
    await loadLocalProfileImage();
  }

  Future<void> clearProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_profile_image');
      _localProfileImagePath = null;
      notifyListeners();
    } catch (e) {
      print('❌ Error clearing profile image: $e');
    }
  }

  Future<void> _saveUserData(AuthData user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', user.toJson().toString());
      await _storage.saveTokens(user.accessToken, user.refreshToken);
      await _storage.setUserId(user.userId);
      await _storage.setUserRole(user.role);
      await _storage.setUserEmail(user.email);
      await _storage.setUserName(user.name);
      await _storage.setLoggedIn(true);
      if (user.profileImage != null && user.profileImage!.isNotEmpty) {
        await _storage.setProfileImage(user.profileImage!);
      }
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _storage.isLoggedIn();
    if (isLoggedIn) {
      final userId = await _storage.getUserId();
      final userRole = await _storage.getUserRole();
      final userEmail = await _storage.getUserEmail();
      final userName = await _storage.getUserName();
      final profileImage = await _storage.getProfileImage();
      
      if (userId != null && userRole != null && userEmail != null) {
        final accessToken = await _storage.getAccessToken() ?? '';
        _user = AuthData(
          accessToken: accessToken,
          refreshToken: await _storage.getRefreshToken() ?? '',
          tokenType: 'Bearer',
          role: userRole,
          userId: userId,
          displayId: 'NST-${userId.toString().padLeft(6, '0')}',
          name: userName ?? '',
          email: userEmail,
          isEmailVerified: true,
          profileImage: profileImage,
        );
        await loadLocalProfileImage();

        if (accessToken.isNotEmpty) {
          try {
            WebSocketManager().connect(
              token: accessToken,
              userId: userId,
            );
            print('✅ WebSocket connect triggered on cold start (checkAuthStatus)');
          } catch (e) {
            print('❌ Error connecting WebSocket on cold start: $e');
          }

          try {
            await FcmService.syncToken();
          } catch (e) {
            print('❌ Error syncing FCM token on cold start: $e');
          }
        }

        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await FcmService.clearToken();
    } catch (e) {
      print('❌ Error clearing FCM token on logout: $e');
    }

    await _authService.logout();
    await clearProfileImage();
    
    try {
      final wsManager = WebSocketManager();
      wsManager.disconnect();
      print('✅ WebSocket disconnected on logout');
    } catch (e) {
      print('❌ Error disconnecting WebSocket: $e');
    }
    
    _user = null;
    _localProfileImagePath = null;
    _setLoading(false);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}