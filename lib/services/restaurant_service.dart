import 'package:dio/dio.dart';
import 'token_manager.dart';

class RestaurantService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  RestaurantService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenManager.getToken();
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔑 Token added to request');
          }
          
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await TokenManager.clearAuthData();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getAllRestaurants() async {
    try {
      final response = await _dio.get('/api/restaurants');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to load restaurants');
    }
  }

  Future<Map<String, dynamic>> getRestaurantById(int id) async {
    try {
      final response = await _dio.get('/api/restaurants/$id');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load restaurant details');
    }
  }
}
