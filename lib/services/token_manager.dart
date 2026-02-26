import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  //  Keys 
  static const String _tokenKey        = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token'; 
  static const String _userIdKey       = 'user_id';
  static const String _userNameKey     = 'userName';
  static const String _userEmailKey    = 'userEmail';
  static const String _userPhoneKey    = 'userPhone';

  //  Save 
  static Future<void> saveAuthData({
    required String token,
     String refreshToken = '',
    required int userId,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken); 
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail);
    await prefs.setString(_userPhoneKey, userPhone);

    print('  Auth data saved');
    print('   UserId: $userId | User: $userName');
    print('   Email: $userEmail | Phone: $userPhone');
    print('   Access Token:   | Refresh Token: ${refreshToken.isNotEmpty ? "✅" : "❌"}');
  }

  //  Get Access Token 
  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getToken() async => getStoredToken();

  //  Get Refresh Token  Naya
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  //  Update Access Token Only  Naya
  static Future<void> updateAccessToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
    print(' Access token updated');
  }

  //  Get User Fields 
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  //  Get All User Data 
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final userId    = prefs.getInt(_userIdKey);
    final userName  = prefs.getString(_userNameKey)  ?? '';
    final userEmail = prefs.getString(_userEmailKey) ?? '';
    final userPhone = prefs.getString(_userPhoneKey) ?? '';

    print('  Retrieved user data:');
    print('   UserId: $userId | Name: $userName');
    print('   Email: $userEmail | Phone: $userPhone');

    return {
      'userId':    userId,
      'userName':  userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
    };
  }

  //  Update Profile Fields
  static Future<void> updateUserData({
    String? userName,
    String? userPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null) {
      await prefs.setString(_userNameKey, userName);
      print(' Updated userName: $userName');
    }
    if (userPhone != null) {
      await prefs.setString(_userPhoneKey, userPhone);
      print(' Updated userPhone: $userPhone');
    }
  }

  //  Login Check 
  static Future<bool> isLoggedIn() async {
    final token  = await getStoredToken();
    final userId = await getUserId();
    final status = token != null && token.isNotEmpty && userId != null;
    print('🔍 Login status: $status');
    return status;
  }

  // Logout / Clear 
  static Future<void> clearToken() async => clearAuthData();

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey); 
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    print('🗑️ Auth data cleared');
  }
}
