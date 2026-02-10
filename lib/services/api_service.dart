import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_manager.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenManager.getStoredToken();
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            if (ApiConfig.isDebugMode) {
              print(' Token added to: ${options.path}');
            }
          }
          
          if (ApiConfig.isDebugMode) {
            print('Request: ${options.method} ${options.baseUrl}${options.path}');
          }
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (ApiConfig.isDebugMode) {
            print(' Response: ${response.statusCode} from ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (ApiConfig.isDebugMode) {
            print('   API Error: ${error.message}');
            print('   Status Code: ${error.response?.statusCode}');
            print('   URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
          }
          
          if (error.response?.statusCode == 401) {
            print('Unauthorized - Clearing auth data');
            await TokenManager.clearAuthData();
          }
          
          return handler.next(error);
        },
      ),
    );
    
    if (ApiConfig.isDebugMode) {
      print('════════════════════════════════════════');
      print('   ApiService Initialized');
      print('   Base URL: ${ApiConfig.baseUrl}');
      print('   Connect Timeout: ${ApiConfig.connectTimeout.inSeconds}s');
      print('   Receive Timeout: ${ApiConfig.receiveTimeout.inSeconds}s');
      print('════════════════════════════════════════');
    }
  }

  // Extract error message helper
  String _extractErrorMessage(dynamic error, String defaultMessage) {
    if (error is DioException) {
      // Log detailed error for debugging
      if (ApiConfig.isDebugMode) {
        print('   Error Details:');
        print('   Type: ${error.type}');
        print('   Message: ${error.message}');
        print('   Status: ${error.response?.statusCode}');
      }

      // Check backend response
      if (error.response?.data != null) {
        final data = error.response!.data;
        
        // JSON response with message
        if (data is Map<String, dynamic> && data['message'] != null) {
          return data['message'].toString();
        }
        
        // Plain string response
        if (data is String) {
          return data;
        }
      }
      
      // Network errors with better messages
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'Connection timeout. Check if backend is running on ${ApiConfig.baseUrl}';
      }
      if (error.type == DioExceptionType.receiveTimeout) {
        return 'Server not responding. Please try again later.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot connect to ${ApiConfig.baseUrl}. Check your network and backend server.';
      }
      
      // Status code errors
      if (error.response?.statusCode != null) {
        final statusCode = error.response!.statusCode!;
        
        if (statusCode >= 500) {
          return 'Server error. Please try again later.';
        }
        if (statusCode == 404) {
          return 'Resource not found.';
        }
        if (statusCode == 403) {
          return 'Access denied.';
        }
        if (statusCode == 401) {
          return 'Session expired. Please login again.';
        }
      }
    }
    
    return defaultMessage;
  }

  // Get Restaurants
  Future<List<dynamic>> getRestaurants() async {
    try {
      print('Fetching restaurants...');
      final response = await _dio.get('/api/restaurants');
      print('Restaurants fetched: ${response.data.length}');
      return response.data;
    } on DioException catch (e) {
      print('Failed to fetch restaurants: ${e.message}');
      throw Exception(_extractErrorMessage(
        e,
        'Failed to load restaurants. Please try again.',
      ));
    }
  }

  Future<List<dynamic>> getAllRestaurants() async {
    return await getRestaurants();
  }

  // Get Restaurant by ID
  Future<Map<String, dynamic>> getRestaurantById(int id) async {
    try {
      print('Fetching restaurant: $id');
      final response = await _dio.get('/api/restaurants/$id');
      return response.data;
    } catch (e) {
      print('Failed to fetch restaurant: $e');
      throw Exception(_extractErrorMessage(
        e,
        'Failed to load restaurant details.',
      ));
    }
  }

  // Get Menu Items
  Future<List<dynamic>> getMenuItems(int restaurantId) async {
    try {
      print('Fetching menu for restaurant $restaurantId...');
      final response = await _dio.get('/api/menu/restaurant/$restaurantId/available');
      print('Menu items fetched: ${response.data.length}');
      return response.data;
    } on DioException catch (e) {
      print('Failed to fetch menu: ${e.message}');
      throw Exception(_extractErrorMessage(
        e,
        'Failed to load menu. Please try again.',
      ));
    }
  }

  // Search Restaurants
  Future<List<dynamic>> searchRestaurants(String query) async {
    try {
      print('🔍 Searching restaurants: $query');
      final response = await _dio.get(
        '/api/restaurants/search',
        queryParameters: {'query': query},
      );
      return response.data;
    } catch (e) {
      print('Search failed: $e');
      throw Exception(_extractErrorMessage(
        e,
        'Failed to search restaurants.',
      ));
    }
  }

  // Get Restaurants by Cuisine
  Future<List<dynamic>> getRestaurantsByCuisine(String cuisine) async {
    try {
      print('Fetching restaurants by cuisine: $cuisine');
      final response = await _dio.get('/api/restaurants/cuisine/$cuisine');
      return response.data;
    } catch (e) {
      print('Failed to fetch by cuisine: $e');
      throw Exception(_extractErrorMessage(
        e,
        'Failed to load restaurants.',
      ));
    }
  }

  // Register User
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    try {
      print('Register attempt: $email');

      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'username': name,  // Backend expects 'username'
          'email': email,
          'password': password,
          'phone': phone,
          'role': 'CUSTOMER',
        },
      );

      print('Registration successful');

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
          userName: user['username'] ?? user['name'],
          userEmail: user['email'],
          userPhone: user['phone'],
        );

        return response.data;
      } else {
        throw Exception('Invalid registration response format');
      }
    } on DioException catch (e) {
      print('Registration error: ${e.message}');
      throw Exception(_extractErrorMessage(
        e,
        'Registration failed. Please try again.',
      ));
    }
  }

  // Logout
  Future<void> logout() async {
    await TokenManager.clearAuthData();
    print('Logged out successfully');
  }
}
