import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'userName';
  static const String _userEmailKey = 'userEmail';
  static const String _userPhoneKey = 'userPhone';

  // Save authentication data
  static Future<void> saveAuthData({
    required String token,
    required int userId,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail);
    await prefs.setString(_userPhoneKey, userPhone);
    
    print('✅ Auth data saved successfully');
    print('   User: $userName');
    print('   Email: $userEmail');
    print('   Phone: $userPhone');
  }

  // Get stored token
  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get token (alias for compatibility)
  static Future<String?> getToken() async {
    return await getStoredToken();
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Get user phone
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  // Get user data
  static Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userName': prefs.getString(_userNameKey) ?? '',
      'userEmail': prefs.getString(_userEmailKey) ?? '',
      'userPhone': prefs.getString(_userPhoneKey) ?? '',
    };
  }

  // Update user data in SharedPreferences
  static Future<void> updateUserData({
    String? userName,
    String? userPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (userName != null) {
      await prefs.setString(_userNameKey, userName);
      print('✅ Updated userName in storage: $userName');
    }
    
    if (userPhone != null) {
      await prefs.setString(_userPhoneKey, userPhone);
      print('✅ Updated userPhone in storage: $userPhone');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getStoredToken();
    final isLoggedIn = token != null && token.isNotEmpty;
    print('🔐 Login status: $isLoggedIn');
    return isLoggedIn;
  }

  // Clear token (logout)
  static Future<void> clearToken() async {
    await clearAuthData();
  }

  // Clear all authentication data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    print('🗑️ Auth data cleared');
  }
}
