import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/token_manager.dart';
import '../orders/order_tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int orderId;
  final double totalAmount;
  final String? razorpayOrderId;
  final String? razorpayKeyId;

  const PaymentScreen({
    Key? key,
    required this.orderId,
    required this.totalAmount,
    this.razorpayOrderId,
    this.razorpayKeyId,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  String _selectedPaymentMethod = 'ONLINE';
  bool _isProcessing = false;
  String? _razorpayOrderId;
  String? _razorpayKeyId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _razorpayOrderId = widget.razorpayOrderId;
    _razorpayKeyId = widget.razorpayKeyId;

    print('💳 PaymentScreen initialized with:');
    print('   OrderId: ${widget.orderId}');
    print('   Amount: ${widget.totalAmount}');
    print('   RazorpayOrderId: $_razorpayOrderId');
    print('   RazorpayKeyId: $_razorpayKeyId');
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ================================================================
  //  PROCESS PAYMENT — router
  // ================================================================
  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'CASH_ON_DELIVERY') {
      await _processCODPayment();
    } else {
      await _processOnlinePayment();
    }
  }

  // ================================================================
  //  ONLINE PAYMENT
  // ================================================================
  Future<void> _processOnlinePayment() async {
    setState(() => _isProcessing = true);

    try {
      final userName = await TokenManager.getUserName() ?? 'Customer';
      final userEmail = await TokenManager.getUserEmail() ?? '';
      final userPhone = await TokenManager.getUserPhone() ?? '';

      if (_razorpayOrderId != null && _razorpayKeyId != null) {
        print('✅ Using existing Razorpay order: $_razorpayOrderId');
        setState(() => _isProcessing = false);
        _openRazorpayCheckout(userName, userEmail, userPhone);
        return;
      }

      // Fallback — create new Razorpay order
      print('⚠️ Creating new Razorpay order (fallback)');
      final userId = await TokenManager.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final orderData = {
        'orderId': widget.orderId,
        'amount': widget.totalAmount,
        'currency': 'INR',
        'userId': userId,
        'customerName': userName,
        'customerEmail':
            userEmail.isNotEmpty ? userEmail : 'customer@example.com',
        'customerPhone': userPhone.isNotEmpty ? userPhone : '9876543210',
      };

      final response = await http
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}/api/payments/razorpay/create-order'),
            headers: {
              'Authorization': 'Bearer ${await TokenManager.getToken()}',
              'Content-Type': 'application/json',
            },
            body: json.encode(orderData),
          )
          .timeout(const Duration(seconds: 30));

      print(
          '📥 Create order response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          _razorpayOrderId = data['razorpayOrderId'];
          _razorpayKeyId = data['keyId'];
          _isProcessing = false;
        });
        _openRazorpayCheckout(userName, userEmail, userPhone);
      } else {
        throw Exception('Failed to create payment order: ${response.body}');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      print('❌ Error in payment: $e');
      _showErrorDialog('Failed to process payment. Please try again.');
    }
  }

  void _openRazorpayCheckout(
      String userName, String userEmail, String userPhone) {
    final options = {
      'key': _razorpayKeyId,
      'amount': (widget.totalAmount * 100).toInt(),
      'name': 'Food Delivery',
      'order_id': _razorpayOrderId,
      'description': 'Order #${widget.orderId}',
      'timeout': 300,
      'prefill': {
        'contact': userPhone.isNotEmpty ? userPhone : '9876543210',
        'email': userEmail.isNotEmpty ? userEmail : 'customer@example.com',
        'name': userName,
      },
      'theme': {'color': '#FF6B35'},
    };

    print('🎯 Opening Razorpay checkout: $options');

    try {
      _razorpay.open(options);
    } catch (e) {
      print('❌ Error opening Razorpay: $e');
      _showErrorDialog('Failed to open payment gateway');
    }
  }

  // ================================================================
  //  RAZORPAY CALLBACKS
  // ================================================================
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('✅ Payment Success!');
    print('   Payment ID: ${response.paymentId}');
    print('   Order ID: ${response.orderId}');
    print('   Signature: ${response.signature}');

    setState(() => _isProcessing = true);

    try {
      final verifyData = {
        'razorpayOrderId': response.orderId ?? _razorpayOrderId,
        'razorpayPaymentId': response.paymentId ?? '',
        'razorpaySignature': response.signature ?? '',
      };

      print('🔍 Verifying payment: $verifyData');

      final verifyResponse = await http
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}/api/payments/razorpay/verify-payment'),
            headers: {
              'Authorization': 'Bearer ${await TokenManager.getToken()}',
              'Content-Type': 'application/json',
            },
            body: json.encode(verifyData),
          )
          .timeout(const Duration(seconds: 30));

      print(
          '📥 Verify response: ${verifyResponse.statusCode} - ${verifyResponse.body}');

      setState(() => _isProcessing = false);

      if (verifyResponse.statusCode == 200) {
        final result = json.decode(verifyResponse.body);
        if (result['success'] == true) {
          _showSuccessDialog();
        } else {
          _showErrorDialog('Payment verification failed');
        }
      } else {
        _showErrorDialog('Payment verification failed');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      print('❌ Payment verification error: $e');
      _showErrorDialog('Payment verification error: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Error: ${response.code} - ${response.message}');
    _showErrorDialog('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('🔗 External Wallet: ${response.walletName}');
  }

  // ================================================================
  //  COD PAYMENT ✅ FULLY WORKING
  // ================================================================
  Future<void> _processCODPayment() async {
    setState(() => _isProcessing = true);

    try {
      print('💵 Processing COD for order: ${widget.orderId}');

      final response = await http
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}/api/payments/cod/${widget.orderId}'),
            headers: {
              'Authorization': 'Bearer ${await TokenManager.getToken()}',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print(
          '📥 COD response: ${response.statusCode} - ${response.body}');

      setState(() => _isProcessing = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        // ✅ Agar COD endpoint nahi hai backend pe — gracefully handle
        final body = json.decode(response.body);
        _showErrorDialog(
            body['message'] ?? 'Failed to process COD. Try again.');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      print('❌ COD payment error: $e');
      _showErrorDialog('Failed to process COD payment: $e');
    }
  }

  // ================================================================
  //  SUCCESS DIALOG — Track Order
  // ================================================================
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Animated check icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 64),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Placed! 🎉',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _selectedPaymentMethod == 'CASH_ON_DELIVERY'
                  ? 'Your order is confirmed.\nPay ₹${widget.totalAmount.toStringAsFixed(0)} on delivery.'
                  : 'Payment of ₹${widget.totalAmount.toStringAsFixed(0)} received.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Order #${widget.orderId}',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Primary — Track Order
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(
                        orderId: widget.orderId,
                      ),
                    ),
                    (route) => route.isFirst,
                  );
                },
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text(
                  'Track My Order',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ✅ Secondary — View All Orders
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/orders',
                    (route) => route.isFirst,
                  );
                },
                icon: Icon(Icons.receipt_long,
                    size: 18, color: AppTheme.primary),
                label: Text(
                  'View All Orders',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  //  ERROR DIALOG
  // ================================================================
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.error_outline, color: AppTheme.error, size: 64),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Failed',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _processPayment();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  //  BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    _selectedPaymentMethod == 'CASH_ON_DELIVERY'
                        ? 'Placing your order...'
                        : 'Processing payment...',
                    style: TextStyle(
                        fontSize: 16, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  _buildOrderSummary(),
                  const SizedBox(height: 16),
                  _buildPaymentMethods(),
                ],
              ),
            ),
      bottomNavigationBar: _isProcessing
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedPaymentMethod == 'CASH_ON_DELIVERY'
                        ? '🛵  Place Order (Cash on Delivery)'
                        : '💳  Pay ₹${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }

  // ================================================================
  //  ORDER SUMMARY
  // ================================================================
  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _summaryRow('Order ID', '#${widget.orderId}'),
          const Divider(height: 24),
          _summaryRow(
            'Total Amount',
            '₹${widget.totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  // ================================================================
  //  PAYMENT METHODS
  // ================================================================
  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPaymentOption(
            'ONLINE',
            'Online Payment',
            'UPI • Cards • Net Banking • Wallets',
            Icons.payment_outlined,
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            'CASH_ON_DELIVERY',
            'Cash on Delivery',
            'Pay ₹${widget.totalAmount.toStringAsFixed(0)} when order arrives',
            Icons.money,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppTheme.primary.withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primary : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) =>
                  setState(() => _selectedPaymentMethod = val!),
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
