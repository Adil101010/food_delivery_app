// lib/models/payment_order_response.dart

class PaymentOrderResponse {
  final String razorpayOrderId;
  final String razorpayKey;
  final double amount;
  final String currency;

  PaymentOrderResponse({
    required this.razorpayOrderId,
    required this.razorpayKey,
    required this.amount,
    required this.currency,
  });

  factory PaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    return PaymentOrderResponse(
      razorpayOrderId: json['razorpayOrderId'],
      razorpayKey: json['razorpayKey'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'INR',
    );
  }
}
