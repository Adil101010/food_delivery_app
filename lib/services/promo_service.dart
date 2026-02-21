import 'dart:convert';
import 'package:http/http.dart' as http;

class PromoService {
  
  static const String _baseUrl = 'http://192.168.0.124:8092/api/coupons';

  static Future<Map<String, dynamic>> validateCoupon({
    required String couponCode,
    required double orderAmount,
    required int userId,
    required int restaurantId,
  }) async {
    try {
      print(' Validating coupon: $couponCode');
      print(' URL: $_baseUrl/validate');
      print(' Amount: $orderAmount, UserId: $userId');

      final response = await http.post(
        Uri.parse('$_baseUrl/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'couponCode': couponCode,
          'orderAmount': orderAmount,
          'userId': userId,
          'restaurantId': restaurantId,
        }),
      );

      print(' Promo Response: ${response.statusCode}');
      print(' Promo Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print(' Promo Error: $e');
      return {'valid': false, 'message': 'Network error: $e'};
    }
  }
}
