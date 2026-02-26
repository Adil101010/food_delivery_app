import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (ApiConfig.isDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('🌐 $obj'),
      ));

      print('  AuthService initialized');
      print('   Base URL: ${ApiConfig.baseUrl}');
      print('   Environment: ${ApiConfig.environment}');
      print('   Timeout: ${ApiConfig.connectTimeout.inSeconds}s');
    }
  }


  // LOGIN
  
  Future<Map<String, dynamic>> login(
      String emailOrPhone, String password) async {
    try {
      print(' Login attempt: $emailOrPhone');

      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'emailOrPhone': emailOrPhone,
          'password': password,
        },
      );

      print(' Login successful');

      if (ApiConfig.isDebugMode) {
        print('========================================');
        print('LOGIN RESPONSE DEBUG');
        print('Full response: ${response.data}');
        print('Response keys: ${response.data.keys.toList()}');
        print('========================================');
      }

      // Format 1: accessToken top-level 
      if (response.data != null &&
          response.data['accessToken'] != null) {
        final token = response.data['accessToken'] as String;
        final refreshToken =
            response.data['refreshToken'] as String? ?? ''; 
        final userId = response.data['userId'];
        final email = response.data['email'] as String?;
        final phone = response.data['phone'] as String? ?? '';
        final userName = email?.split('@')[0] ?? 'User';

        if (ApiConfig.isDebugMode) {
          print('  Format 1 detected');
          print('   UserId: $userId');
          print('   Token: ✅');
          print('   RefreshToken: ${refreshToken.isNotEmpty ? "✅" : "❌"}');
        }

        await TokenManager.saveAuthData(
          token: token,
          refreshToken: refreshToken, 
          userId: userId,
          userName: userName,
          userEmail: email ?? '',
          userPhone: phone,
        );

        _printVerification();
        return response.data;
      }

      // Format 2: success + data wrapper 
      else if (response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'] as String? ??
            data['accessToken'] as String? ?? '';
        final refreshToken =
            data['refreshToken'] as String? ?? ''; 
        final user = data['user'];

        if (ApiConfig.isDebugMode) {
          print('📦 Format 2 detected');
          print('   UserId: ${user['id']}');
          print('   Token: ✅');
          print('   RefreshToken: ${refreshToken.isNotEmpty ? "✅" : "❌"}');
        }

        await TokenManager.saveAuthData(
          token: token,
          refreshToken: refreshToken, 
          userId: user['id'],
          userName: user['name'] ?? '',
          userEmail: user['email'] ?? '',
          userPhone: user['phone'] ?? '',
        );

        _printVerification();
        return response.data;
      } else {
        throw Exception('Invalid login response format');
      }
    } on DioException catch (e) {
      print(' Login DioError: ${e.type}');
      _handleDioError(e);
    } catch (e) {
      print(' Unexpected error: $e');
      rethrow;
    }
    throw Exception('Login failed');
  }

  
  // REGISTER
  
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    try {
      print(' Register attempt: $email');

      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': 'CUSTOMER',
        },
      );

      print(' Registration successful');

      //  Format 1 
      if (response.data != null &&
          response.data['accessToken'] != null) {
        final token = response.data['accessToken'] as String;
        final refreshToken =
            response.data['refreshToken'] as String? ?? ''; 
        final userId = response.data['userId'];

        await TokenManager.saveAuthData(
          token: token,
          refreshToken: refreshToken, 
          userId: userId,
          userName: name,
          userEmail: email,
          userPhone: phone,
        );

        return response.data;
      }

      //  Format 2 
      else if (response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'] as String? ??
            data['accessToken'] as String? ?? '';
        final refreshToken =
            data['refreshToken'] as String? ?? ''; 
        final user = data['user'];

        await TokenManager.saveAuthData(
          token: token,
          refreshToken: refreshToken, 
          userId: user['id'],
          userName: user['name'] ?? name,
          userEmail: user['email'] ?? email,
          userPhone: user['phone'] ?? phone,
        );

        return response.data;
      } else {
        throw Exception('Invalid registration response format');
      }
    } on DioException catch (e) {
      print(' Registration error: ${e.message}');
      _handleDioError(e);
    } catch (e) {
      print(' Unexpected registration error: $e');
      rethrow;
    }
    throw Exception('Registration failed');
  }

 
  // REFRESH TOKEN  Naya
  
  Future<String?> refreshToken() async {
    try {
      final storedRefreshToken = await TokenManager.getRefreshToken();
      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        print(' No refresh token found');
        return null;
      }

      final response = await _dio.post(
        '/api/auth/refresh-token',
        data: {'refreshToken': storedRefreshToken},
      );

      if (response.data['success'] == true) {
        final newToken = response.data['data']['accessToken'] as String;
        await TokenManager.updateAccessToken(newToken);
        print(' Token refreshed successfully');
        return newToken;
      }
      return null;
    } catch (e) {
      print(' Token refresh failed: $e');
      return null;
    }
  }

  
  // IS LOGGED IN
  
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');

    print('  Auth Check:');
    print('   Token exists: ${token != null}');
    print('   User ID: $userId');

    return token != null && userId != null;
  }

 
  // LOGOUT
  
  Future<void> logout() async {
    try {
      final refreshToken = await TokenManager.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        // Backend ko bhi logout notify kra
        await _dio.post(
          '/api/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (e) {
      // Silent fail  local logout toh hoga hi
      print(' Backend logout failed: $e');
    } finally {
      await TokenManager.clearAuthData();
      print(' Logged out successfully');
    }
  }


  // PRIVATE HELPERS
 
  Future<void> _printVerification() async {
    if (!ApiConfig.isDebugMode) return;
    final savedUserId = await TokenManager.getUserId();
    final savedToken = await TokenManager.getStoredToken();
    final savedRefresh = await TokenManager.getRefreshToken();
    print('========================================');
    print('VERIFICATION AFTER SAVE');
    print('   Saved userId: $savedUserId');
    print('   Access token: ${savedToken != null ? "✅" : "❌"}');
    print('   Refresh token: ${savedRefresh != null && savedRefresh.isNotEmpty ? "✅" : "❌"}');
    print('========================================');
  }

  Never _handleDioError(DioException e) {
    if (e.response != null) {
      throw Exception(
          e.response?.data['message'] ?? 'Request failed');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      throw Exception(
        'Connection timeout (${ApiConfig.connectTimeout.inSeconds}s).\n'
        'Backend: ${ApiConfig.baseUrl}\n'
        'Check if server is running and phone is on same WiFi.',
      );
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw Exception(
        'Server response timeout (${ApiConfig.receiveTimeout.inSeconds}s).\n'
        'Server is taking too long to respond.',
      );
    } else if (e.type == DioExceptionType.connectionError) {
      throw Exception(
        'Cannot connect to server.\n'
        'URL: ${ApiConfig.baseUrl}\n'
        'Check network and firewall settings.',
      );
    } else {
      throw Exception('Network error: ${e.message}');
    }
  }
}
