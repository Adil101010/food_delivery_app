// lib/models/payment_order_request.dart

class PaymentOrderRequest {
  final int orderId;
  final double amount;
  final String currency;

  PaymentOrderRequest({
    required this.orderId,
    required this.amount,
    this.currency = 'INR',
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
    };
  }
}
