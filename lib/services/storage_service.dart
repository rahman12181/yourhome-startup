import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyProfileImage = 'profile_image'; // ✅ ADDED
  static const String _keyLocalProfileImage = 'local_profile_image'; // ✅ ADDED
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyUserData = 'user_data'; // ✅ ADDED - For full user data

  final SharedPreferences? _prefs;

  StorageService() : _prefs = null;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  // ==================== TOKENS ====================
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await _instance;
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  Future<void> setAccessToken(String token) async {
    final prefs = await _instance;
    await prefs.setString(_keyAccessToken, token);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _instance;
    return prefs.getString(_keyAccessToken);
  }

  Future<void> setRefreshToken(String token) async {
    final prefs = await _instance;
    await prefs.setString(_keyRefreshToken, token);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _instance;
    return prefs.getString(_keyRefreshToken);
  }

  // ==================== USER ID ====================
  Future<void> setUserId(int userId) async {
    final prefs = await _instance;
    await prefs.setInt(_keyUserId, userId);
  }

  Future<int?> getUserId() async {
    final prefs = await _instance;
    return prefs.getInt(_keyUserId);
  }

  // ==================== USER ROLE ====================
  Future<void> setUserRole(String role) async {
    final prefs = await _instance;
    await prefs.setString(_keyUserRole, role);
  }

  Future<String?> getUserRole() async {
    final prefs = await _instance;
    return prefs.getString(_keyUserRole);
  }

  // ==================== USER EMAIL ====================
  Future<void> setUserEmail(String email) async {
    final prefs = await _instance;
    await prefs.setString(_keyUserEmail, email);
  }

  Future<String?> getUserEmail() async {
    final prefs = await _instance;
    return prefs.getString(_keyUserEmail);
  }

  // ==================== USER NAME ====================
  Future<void> setUserName(String name) async {
    final prefs = await _instance;
    await prefs.setString(_keyUserName, name);
  }

  Future<String?> getUserName() async {
    final prefs = await _instance;
    return prefs.getString(_keyUserName);
  }

  // ==================== PROFILE IMAGE (Server URL) ====================
  Future<void> setProfileImage(String imageUrl) async {
    final prefs = await _instance;
    await prefs.setString(_keyProfileImage, imageUrl);
  }

  Future<String?> getProfileImage() async {
    final prefs = await _instance;
    return prefs.getString(_keyProfileImage);
  }

  Future<void> removeProfileImage() async {
    final prefs = await _instance;
    await prefs.remove(_keyProfileImage);
  }

  // ==================== LOCAL PROFILE IMAGE (Local Path) ====================
  Future<void> setLocalProfileImage(String imagePath) async {
    final prefs = await _instance;
    await prefs.setString(_keyLocalProfileImage, imagePath);
  }

  Future<String?> getLocalProfileImage() async {
    final prefs = await _instance;
    return prefs.getString(_keyLocalProfileImage);
  }

  Future<void> removeLocalProfileImage() async {
    final prefs = await _instance;
    await prefs.remove(_keyLocalProfileImage);
  }

  // ==================== USER DATA (Full Object) ====================
  Future<void> setUserData(String userDataJson) async {
    final prefs = await _instance;
    await prefs.setString(_keyUserData, userDataJson);
  }

  Future<String?> getUserData() async {
    final prefs = await _instance;
    return prefs.getString(_keyUserData);
  }

  Future<void> removeUserData() async {
    final prefs = await _instance;
    await prefs.remove(_keyUserData);
  }

  // ==================== LOGIN STATUS ====================
  Future<void> setLoggedIn(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_keyIsLoggedIn, value);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _instance;
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // ==================== THEME ====================
  Future<void> setThemeMode(String mode) async {
    final prefs = await _instance;
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await _instance;
    return prefs.getString(_keyThemeMode);
  }

  // ==================== SAVE ALL USER DATA ====================
  Future<void> saveUserData({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String role,
    required String email,
    required String name,
    String? profileImage,
  }) async {
    final prefs = await _instance;
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserName, name);
    if (profileImage != null && profileImage.isNotEmpty) {
      await prefs.setString(_keyProfileImage, profileImage);
    }
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  // ==================== CLEAR ALL ====================
  Future<void> clearAll() async {
    final prefs = await _instance;
    await prefs.clear();
  }

  // ==================== CLEAR USER DATA (Keep Theme) ====================
  Future<void> clearUserData() async {
    final prefs = await _instance;
    final themeMode = await getThemeMode();
    await prefs.clear();
    if (themeMode != null) {
      await prefs.setString(_keyThemeMode, themeMode);
    }
  }

  // ==================== CHECK IF USER DATA EXISTS ====================
  Future<bool> hasUserData() async {
    final prefs = await _instance;
    return prefs.containsKey(_keyAccessToken) && 
           prefs.containsKey(_keyUserId) &&
           prefs.getBool(_keyIsLoggedIn) == true;
  }
}