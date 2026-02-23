import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/order_model.dart';
import 'token_manager.dart';


class OrderService {
  final Dio _dio;
  final String _baseUrl;


  OrderService()
      : _baseUrl = ApiConfig.baseUrl,
        _dio = Dio(BaseOptions(
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        )) {
    print('🔧 OrderService initialized');
    print('   Base URL: $_baseUrl');
  }


 
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final token = await TokenManager.getStoredToken();

      if (token == null) {
        throw Exception('Please login to place order');
      }

      
      if (orderData['userId'] == null) {
        throw Exception('User ID is missing. Please logout and login again.');
      }

      print(' Creating order with userId: ${orderData['userId']}');
      print(' Order data: $orderData');

      final response = await _dio.post(
        '$_baseUrl/api/orders',
        data: orderData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Create order response status: ${response.statusCode}');
      print('Create order response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic> 
            ? response.data 
            : {'data': response.data};
      } else {
        throw Exception('Failed to create order');
      }
    } on DioException catch (e) {
      print(' Create order error: ${e.message}');
      print(' Error response: ${e.response?.data}');
      
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      
      if (e.response?.statusCode == 401) {
        await TokenManager.clearAuthData();
        throw Exception('Session expired. Please login again.');
      }
      
      throw Exception('Failed to create order. Please try again.');
    }
  }


  Future<List<Order>> getUserOrders({int page = 0, int size = 10}) async {
  try {
    final token = await TokenManager.getStoredToken();
    final userId = await TokenManager.getUserId();

    if (token == null || userId == null) {
      throw Exception('Please login to view orders');
    }

    final response = await _dio.get(
      '$_baseUrl/api/orders/user/$userId?page=$page&size=$size',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;

      if (data is Map && data['data'] != null) {
        final pageData = data['data'];

        if (pageData['content'] != null) {
          List<dynamic> ordersJson = pageData['content'];

          return ordersJson
              .map((json) => Order.fromJson(json))
              .toList();
        } else {
          throw Exception('Invalid pagination response format');
        }
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to fetch orders');
    }
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      await TokenManager.clearAuthData();
      throw Exception('Session expired. Please login again.');
    }
    throw Exception('Failed to load orders. Please try again.');
  }
}


  Future<Order> getOrderById(int orderId) async {
    try {
      final token = await TokenManager.getStoredToken();

      if (token == null) {
        throw Exception('Please login to view order details');
      }

      print(' Fetching order details: $orderId');

      final response = await _dio.get(
        '$_baseUrl/api/orders/$orderId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print(' Order detail response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data['data'] != null) {
          return Order.fromJson(Map<String, dynamic>.from(data['data']));
        } else if (data is Map) {
          return Order.fromJson(Map<String, dynamic>.from(data));
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch order details');
      }
    } on DioException catch (e) {
      print(' Error fetching order: ${e.message}');
      
      if (e.response?.statusCode == 401) {
        await TokenManager.clearAuthData();
        throw Exception('Session expired. Please login again.');
      }
      
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      
      throw Exception('Failed to load order details. Please try again.');
    }
  }


 
  Future<void> cancelOrder(int orderId) async {
    try {
      print(' Cancelling order: $orderId');
      
      final token = await TokenManager.getStoredToken();

      if (token == null) {
        throw Exception('Please login to cancel order');
      }

      print(' Token: ${token.substring(0, 20)}...');

      final response = await _dio.post(
        '$_baseUrl/api/orders/$orderId/cancel',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(' Cancel response status: ${response.statusCode}');
      print(' Cancel response data: ${response.data}');

      if (response.statusCode == 200) {
        print(' Order cancelled successfully');
      } else {
        throw Exception('Failed to cancel order');
      }
    } on DioException catch (e) {
      print(' Cancel error: ${e.message}');
      print(' Response: ${e.response?.data}');
      print(' Status code: ${e.response?.statusCode}');
      
      if (e.response?.data != null) {
        final data = e.response!.data;
        
        if (data is Map<String, dynamic>) {
          if (data['message'] != null) {
            throw Exception(data['message']);
          }
          if (data['error'] != null) {
            throw Exception(data['error']);
          }
        }
      }
      
      if (e.response?.statusCode == 401) {
        await TokenManager.clearAuthData();
        throw Exception('Session expired. Please login again.');
      }
      
      if (e.response?.statusCode == 403) {
        throw Exception('You are not authorized to cancel this order.');
      }
      
      if (e.response?.statusCode == 404) {
        throw Exception('Order not found.');
      }
      
      if (e.response?.statusCode == 400) {
        throw Exception('Order cannot be cancelled at this stage.');
      }
      
      throw Exception('Failed to cancel order. Please try again.');
    } catch (e) {
      print(' Unexpected error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }
}
