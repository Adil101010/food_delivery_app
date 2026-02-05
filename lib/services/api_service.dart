import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  late Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Interceptor for JWT Token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }
  
  // Login API
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {
          'emailOrPhone': email,
          'password': password,
        },
      );
      
      if (response.data != null && response.data['accessToken'] != null) {
        final token = response.data['accessToken'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        await prefs.setInt('user_id', response.data['userId']);
        await prefs.setString('email', response.data['email']);
        await prefs.setString('phone', response.data['phone'] ?? '');
        
        return {
          'success': true,
          'data': response.data,
        };
      }
      
      return {
        'success': false,
        'message': 'Login failed',
      };
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  // Register API
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String phone,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.registerEndpoint,
        data: {
          'email': email,
          'password': password,
          'phone': phone,
          'role': 'CUSTOMER',
        },
      );
      
      return response.data;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  // Get All Restaurants
  Future<List<dynamic>> getAllRestaurants() async {
    try {
      final response = await _dio.get('/api/restaurants');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch restaurants: $e');
    }
  }
  
  // Search Restaurants by City
  Future<List<dynamic>> getRestaurantsByCity(String city) async {
    try {
      final response = await _dio.get('/api/restaurants/city/$city');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch restaurants: $e');
    }
  }
  
  // Search by Cuisine
  Future<List<dynamic>> searchRestaurants(String cuisine) async {
    try {
      final response = await _dio.get('/api/restaurants/search?cuisine=$cuisine');
      return response.data;
    } catch (e) {
      throw Exception('Failed to search restaurants: $e');
    }
  }
  
  // Create Order API
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _dio.post(
        AppConstants.ordersEndpoint,
        data: orderData,
      );
      
      return response.data;
    } catch (e) {
      throw Exception('Order creation failed: $e');
    }
  }
  
  // Get User Orders
  Future<List<dynamic>> getUserOrders(int userId) async {
    try {
      final response = await _dio.get('${AppConstants.ordersEndpoint}/user/$userId');
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }
  
  // Get Order Details
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final response = await _dio.get('${AppConstants.ordersEndpoint}/$orderId');
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }
  
  // Verify Payment
  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> paymentData) async {
    try {
      final response = await _dio.post(
        '${AppConstants.paymentsEndpoint}/verify',
        data: paymentData,
      );
      
      return response.data;
    } catch (e) {
      throw Exception('Payment verification failed: $e');
    }
  }
  
  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

   // Get Menu Items by Restaurant
Future<List<dynamic>> getMenuItems(int restaurantId) async {
  try {
    final response = await _dio.get('/api/menu/restaurant/$restaurantId/available');
    return response.data;
  } catch (e) {
    throw Exception('Failed to fetch menu items: $e');
  }
}


}
