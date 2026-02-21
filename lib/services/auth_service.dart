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
      
      print('   AuthService initialized');
      print('   Base URL: ${ApiConfig.baseUrl}');
      print('   Environment: ${ApiConfig.environment}');
      print('   Timeout: ${ApiConfig.connectTimeout.inSeconds}s');
    }
  }

  Future<Map<String, dynamic>> login(String emailOrPhone, String password) async {
    try {
      print(' Login attempt: $emailOrPhone');

      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'emailOrPhone': emailOrPhone,
          'password': password,
        },
      );

      print('Login successful');
      
    
      if (ApiConfig.isDebugMode) {
        print('========================================');
        print('LOGIN RESPONSE DEBUG');
        print('========================================');
        print('Full response: ${response.data}');
        print('Response type: ${response.data.runtimeType}');
        if (response.data is Map) {
          print('Response keys: ${response.data.keys.toList()}');
        }
        print('========================================');
      }

      if (response.data != null && response.data['accessToken'] != null) {
        final token = response.data['accessToken'];
        final userId = response.data['userId'];
        final email = response.data['email'];
        final phone = response.data['phone'];
        final userName = email?.split('@')[0] ?? 'User';

        print('========================================');
        print('EXTRACTED DATA');
        print('========================================');
        print('UserId: $userId');
        print('Token exists: ${token != null}');
        print('UserName: $userName');
        print('Email: $email');
        print('Phone: $phone');
        print('========================================');

        await TokenManager.saveAuthData(
          token: token,
          userId: userId,
          userName: userName,
          userEmail: email,
          userPhone: phone,
        );
        
        // Verify saved data
        final savedUserId = await TokenManager.getUserId();
        final savedToken = await TokenManager.getStoredToken();
        
        print('========================================');
        print('VERIFICATION AFTER SAVE');
        print('========================================');
        print('Saved userId: $savedUserId');
        print('Saved token exists: ${savedToken != null}');
        print('========================================');

        return response.data;
      } else if (response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'];
        final user = data['user'];

        print('========================================');
        print('EXTRACTED DATA (Format 2)');
        print('========================================');
        print('UserId: ${user['id']}');
        print('Token exists: ${token != null}');
        print('UserName: ${user['name']}');
        print('========================================');

        await TokenManager.saveAuthData(
          token: token,
          userId: user['id'],
          userName: user['name'],
          userEmail: user['email'],
          userPhone: user['phone'],
        );
        
        // Verify saved data
        final savedUserId = await TokenManager.getUserId();
        final savedToken = await TokenManager.getStoredToken();
        
        print('========================================');
        print('VERIFICATION AFTER SAVE');
        print('========================================');
        print('Saved userId: $savedUserId');
        print('Saved token exists: ${savedToken != null}');
        print('========================================');

        return response.data;
      } else {
        throw Exception('Invalid login response format');
      }
    } on DioException catch (e) {
      print(' Login DioError: ${e.type}');
      print('   Message: ${e.message}');
      
      if (e.response != null) {
        print('   Response: ${e.response?.data}');
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
          'Connection timeout (${ApiConfig.connectTimeout.inSeconds}s).\n'
          'Backend: ${ApiConfig.baseUrl}\n'
          'Check if server is running and phone is on same WiFi.'
        );
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Server response timeout (${ApiConfig.receiveTimeout.inSeconds}s).\n'
          'Server is taking too long to respond.'
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to server.\n'
          'URL: ${ApiConfig.baseUrl}\n'
          'Check network and firewall settings.'
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print(' Unexpected error: $e');
      rethrow;
    }
  }

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

      if (response.data != null && response.data['accessToken'] != null) {
        final token = response.data['accessToken'];
        final userId = response.data['userId'];

        await TokenManager.saveAuthData(
          token: token,
          userId: userId,
          userName: name,
          userEmail: email,
          userPhone: phone,
        );

        return response.data;
      } else if (response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'];
        final user = data['user'];

        await TokenManager.saveAuthData(
          token: token,
          userId: user['id'],
          userName: user['name'],
          userEmail: user['email'],
          userPhone: user['phone'],
        );

        return response.data;
      } else {
        throw Exception('Invalid registration response format');
      }
    } on DioException catch (e) {
      print(' Registration error: ${e.message}');
      
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Check backend connection.');
      } else {
        throw Exception('Network error. Check your connection.');
      }
    } catch (e) {
      print(' Unexpected registration error: $e');
      rethrow;
    }
  }

  // Future<bool> isLoggedIn() async {
  //   return await TokenManager.isLoggedIn();
  // }

   Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final userId = prefs.getInt('user_id');
  
  print(' Auth Check:');
  print('   Token exists: ${token != null}');
  print('   User ID: $userId');
  
  return token != null && userId != null;
}


  Future<void> logout() async {
    await TokenManager.clearAuthData();
    print(' Logged out successfully');
  }
}
