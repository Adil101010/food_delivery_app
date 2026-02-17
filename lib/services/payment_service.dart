// lib/services/payment_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';
import '../models/payment_order_request.dart';
import '../models/payment_order_response.dart';
import '../models/payment_verification_request.dart';
import 'token_manager.dart';

class PaymentService {
  final String baseUrl = ApiConfig.baseUrl;
  late Razorpay _razorpay;

  PaymentService() {
    _razorpay = Razorpay();
  }

  Future<PaymentOrderResponse> createRazorpayOrder({
    required int orderId,
    required double amount,
  }) async {
    try {
      final token = await TokenManager.getToken();

      final request = PaymentOrderRequest(
        orderId: orderId,
        amount: amount,
      );

      print('Creating Razorpay order: ${request.toJson()}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/razorpay/create-order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));

      print('Create order response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentOrderResponse.fromJson(data['data']);
      } else {
        throw Exception('Failed to create payment order: ${response.body}');
      }
    } catch (e) {
      print('Error creating Razorpay order: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final token = await TokenManager.getToken();

      final request = PaymentVerificationRequest(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

      print('Verifying payment: ${request.toJson()}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/razorpay/verify-payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));

      print('Verify payment response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['verified'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }

  void openRazorpayCheckout({
    required PaymentOrderResponse paymentOrder,
    required String userEmail,
    required String userPhone,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
  }) {
    var options = {
      'key': paymentOrder.razorpayKey,
      'amount': (paymentOrder.amount * 100).toInt(), // Amount in paise
      'currency': paymentOrder.currency,
      'name': 'Food Delivery',
      'description': 'Order Payment',
      'order_id': paymentOrder.razorpayOrderId,
      'prefill': {
        'email': userEmail,
        'contact': userPhone,
      },
      'theme': {
        'color': '#FF6B35'
      }
    };

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      print('Payment Success: ${response.paymentId}');
      onSuccess(response);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      print('Payment Error: ${response.code} - ${response.message}');
      onFailure(response);
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      print('External Wallet: ${response.walletName}');
    });

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error opening Razorpay: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
