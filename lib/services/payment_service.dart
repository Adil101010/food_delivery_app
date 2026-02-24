import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_manager.dart';

class PaymentService {
  late final Dio _dio;

  PaymentService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenManager.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('  PAYMENT[${options.method}] => ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('  RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('  PAYMENT ERROR[${error.response?.statusCode}] => ${error.message}');
        print('   Data: ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

 
  Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      print('  Verifying payment for order: $orderId');
      print('   Razorpay Order ID: $razorpayOrderId');
      print('   Razorpay Payment ID: $razorpayPaymentId');

      final response = await _dio.post(
        '/api/orders/verify-payment',
        data: {
          'orderId': orderId,
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
          'paymentStatus': 'PAID',
        },
      );

      print('  Payment verified successfully');
      return response.data;
    } on DioException catch (e) {
      print('  Verification failed: ${e.response?.data}');
      throw Exception(
        e.response?.data?['message'] ?? 'Payment verification failed',
      );
    }
  }

 
  Future<Map<String, dynamic>> processCOD({
    required int orderId,
    required int userId,
  }) async {
    try {
      print('  Processing COD for order: $orderId, user: $userId');

      final response = await _dio.post(
        '/api/payments/cod/$orderId',
        queryParameters: {'userId': userId},
      );

      print('  COD processed successfully');
      return response.data;
    } on DioException catch (e) {
      print('  COD failed: ${e.response?.data}');
      throw Exception(
        e.response?.data?['message'] ?? 'COD processing failed',
      );
    }
  }

  
  Future<Map<String, dynamic>?> getPaymentByOrderId(int orderId) async {
    try {
      final response = await _dio.get('/api/payments/order/$orderId');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      print('  Get payment failed: ${e.message}');
      return null;
    }
  }

 
  Future<List<dynamic>> getUserPayments(int userId) async {
    try {
      final response = await _dio.get('/api/payments/user/$userId');
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      print('  Get user payments failed: ${e.message}');
      return [];
    }
  }
}
