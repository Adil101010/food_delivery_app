import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';

  static Future<void> saveAuthData({
    required String token,
    required int userId,
    required String userName,
    required String userEmail,
    String? userPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail);
    if (userPhone != null) {
      await prefs.setString(_userPhoneKey, userPhone);
    }
    
    print('TokenManager: Auth data saved');
    print('   Token length: ${token.length}');
    print('   User ID: $userId');
    print('   User Email: $userEmail');
  }

  Future<String?> getToken() async {
    return await TokenManager.getStoredToken();
  }

  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token != null) {
      print('TokenManager: Token retrieved (${token.length} chars)');
    } else {
      print('TokenManager: No token found');
    }
    
    return token;
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getStoredToken();
    final isValid = token != null && token.isNotEmpty;
    
    print('TokenManager: Is logged in? $isValid');
    
    return isValid;
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    
    print('TokenManager: Auth data cleared');
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'token': prefs.getString(_tokenKey),
      'userId': prefs.getInt(_userIdKey),
      'userName': prefs.getString(_userNameKey),
      'userEmail': prefs.getString(_userEmailKey),
      'userPhone': prefs.getString(_userPhoneKey),
    };
  }
}
