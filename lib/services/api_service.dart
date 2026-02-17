import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_manager.dart';
import '../models/user.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add request/response interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenManager.getStoredToken();
          
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            if (ApiConfig.isDebugMode) {
              print('Token added to: ${options.path}');
            }
          }
          
          if (ApiConfig.isDebugMode) {
            print('Request: ${options.method} ${options.baseUrl}${options.path}');
          }
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (ApiConfig.isDebugMode) {
            print('Response: ${response.statusCode} from ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (ApiConfig.isDebugMode) {
            print('API Error: ${error.message}');
            print('Status Code: ${error.response?.statusCode}');
            print('URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
            
            if (error.response?.data != null) {
              print('Error Response: ${error.response?.data}');
            }
          }
          
          // Handle 401 Unauthorized - clear auth and redirect to login
          if (error.response?.statusCode == 401) {
            print('Unauthorized access - Clearing auth data');
            await TokenManager.clearAuthData();
            // Note: Navigation should be handled in UI layer, not here
          }
          
          return handler.next(error);
        },
      ),
    );
    
    if (ApiConfig.isDebugMode) {
      print('========================================');
      print('ApiService Initialized');
      print('Base URL: ${ApiConfig.baseUrl}');
      print('Connect Timeout: ${ApiConfig.connectTimeout.inSeconds}s');
      print('Receive Timeout: ${ApiConfig.receiveTimeout.inSeconds}s');
      print('========================================');
    }
  }

  // Extract user-friendly error messages
  String _extractErrorMessage(dynamic error, String defaultMessage) {
    if (error is DioException) {
      if (ApiConfig.isDebugMode) {
        print('Error Details:');
        print('Type: ${error.type}');
        print('Message: ${error.message}');
        print('Status: ${error.response?.statusCode}');
      }

      // Check backend JSON response
      if (error.response?.data != null) {
        final data = error.response!.data;
        
        if (data is Map<String, dynamic>) {
          if (data['message'] != null) return data['message'].toString();
          if (data['error'] != null) return data['error'].toString();
        }
        
        if (data is String) return data;
      }
      
      // Network-specific errors
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout. Check if backend is running on ${ApiConfig.baseUrl}';
        case DioExceptionType.receiveTimeout:
          return 'Server not responding. Please try again later.';
        case DioExceptionType.connectionError:
          return 'Cannot connect to server. Check your network and backend status.';
        case DioExceptionType.badResponse:
          return _handleStatusCodeError(error.response?.statusCode);
        default:
          break;
      }
    }
    
    return defaultMessage;
  }

  // Handle HTTP status code errors
  String _handleStatusCodeError(int? statusCode) {
    if (statusCode == null) return 'Unknown error occurred';
    
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied. You do not have permission.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict. This resource already exists.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        if (statusCode >= 500) return 'Server error. Please try again later.';
        if (statusCode >= 400) return 'Request failed. Please try again.';
        return 'An error occurred. Please try again.';
    }
  }

  // Get all restaurants
  Future<List<dynamic>> getRestaurants() async {
    try {
      print('Fetching restaurants...');
      final response = await _dio.get('/api/restaurants');
      print('Restaurants fetched: ${response.data.length}');
      return response.data;
    } on DioException catch (e) {
      print('Failed to fetch restaurants: ${e.message}');
      throw Exception(_extractErrorMessage(e, 'Failed to load restaurants. Please try again.'));
    }
  }

  Future<List<dynamic>> getAllRestaurants() async {
    return await getRestaurants();
  }

  // Get restaurant by ID
  Future<Map<String, dynamic>> getRestaurantById(int id) async {
    try {
      print('Fetching restaurant: $id');
      final response = await _dio.get('/api/restaurants/$id');
      return response.data;
    } catch (e) {
      print('Failed to fetch restaurant: $e');
      throw Exception(_extractErrorMessage(e, 'Failed to load restaurant details.'));
    }
  }

  // Get menu items for a restaurant
  Future<List<dynamic>> getMenuItems(int restaurantId) async {
    try {
      print('Fetching menu for restaurant $restaurantId...');
      final response = await _dio.get('/api/menu/restaurant/$restaurantId/available');
      print('Menu items fetched: ${response.data.length}');
      return response.data;
    } on DioException catch (e) {
      print('Failed to fetch menu: ${e.message}');
      throw Exception(_extractErrorMessage(e, 'Failed to load menu. Please try again.'));
    }
  }

  // Search restaurants
  Future<List<dynamic>> searchRestaurants(String query) async {
    try {
      print('Searching restaurants: $query');
      final response = await _dio.get(
        '/api/restaurants/search',
        queryParameters: {'query': query},
      );
      return response.data;
    } catch (e) {
      print('Search failed: $e');
      throw Exception(_extractErrorMessage(e, 'Failed to search restaurants.'));
    }
  }

  // Get restaurants by cuisine
  Future<List<dynamic>> getRestaurantsByCuisine(String cuisine) async {
    try {
      print('Fetching restaurants by cuisine: $cuisine');
      final response = await _dio.get('/api/restaurants/cuisine/$cuisine');
      return response.data;
    } catch (e) {
      print('Failed to fetch by cuisine: $e');
      throw Exception(_extractErrorMessage(e, 'Failed to load restaurants.'));
    }
  }

  // Register new user
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
          'username': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': 'CUSTOMER',
        },
      );

      print('Registration successful');

      // Handle different response formats from backend
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
      throw Exception(_extractErrorMessage(e, 'Registration failed. Please try again.'));
    }
  }

  // Get current user profile
  Future<User> getCurrentUser() async {
    try {
      print('Fetching current user profile...');
      final response = await _dio.get('/api/users/profile');
      
      if (response.data != null) {
        print('User profile fetched successfully');
        return User.fromJson(response.data);
      } else {
        throw Exception('Invalid profile response');
      }
    } on DioException catch (e) {
      print('Failed to fetch user profile: ${e.message}');
      throw Exception(_extractErrorMessage(e, 'Failed to load profile. Please try again.'));
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      print('Updating user profile...');
      print('Name: $name');
      print('Phone: $phone');
      
      final response = await _dio.put(
        '/api/users/profile',
        data: {
          'name': name,
          'phone': phone,
        },
      );
      
      if (response.statusCode == 200) {
        print('Profile updated successfully');
        
        await TokenManager.updateUserData(
          userName: name,
          userPhone: phone,
        );
      } else {
        throw Exception('Failed to update profile');
      }
    } on DioException catch (e) {
      print('Failed to update profile: ${e.message}');
      throw Exception(_extractErrorMessage(e, 'Failed to update profile. Please try again.'));
    }
  }

  // Logout user
  Future<void> logout() async {
    await TokenManager.clearAuthData();
    print('Logged out successfully');
  }
}
