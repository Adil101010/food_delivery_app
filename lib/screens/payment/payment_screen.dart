// lib/screens/payment/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/token_manager.dart';

class PaymentScreen extends StatefulWidget {
  final int orderId;
  final double totalAmount;
  final String? razorpayOrderId;  // Add this
  final String? razorpayKeyId;    // Add this

  const PaymentScreen({
    Key? key,
    required this.orderId,
    required this.totalAmount,
    this.razorpayOrderId,  // Add this
    this.razorpayKeyId,    // Add this
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
    
    // Set razorpay details from order creation response
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

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'CASH_ON_DELIVERY') {
      _processCODPayment();
    } else {
      _processOnlinePayment();
    }
  }

  Future<void> _processOnlinePayment() async {
    setState(() => _isProcessing = true);

    try {
      // Get user details
      final userName = await TokenManager.getUserName() ?? 'Customer';
      final userEmail = await TokenManager.getUserEmail() ?? '';
      final userPhone = await TokenManager.getUserPhone() ?? '';

      // If razorpay details already available, directly open checkout
      if (_razorpayOrderId != null && _razorpayKeyId != null) {
        print('✅ Using existing Razorpay order: $_razorpayOrderId');
        setState(() => _isProcessing = false);
        _openRazorpayCheckout(userName, userEmail, userPhone);
        return;
      }

      // Otherwise create new razorpay order (fallback - shouldn't happen)
      print('⚠️ Creating new Razorpay order (fallback)');
      
      final userId = await TokenManager.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print('💳 Creating Razorpay order with user details:');
      print('   UserId: $userId');
      print('   UserName: $userName');
      print('   UserEmail: $userEmail');
      print('   UserPhone: $userPhone');

      final orderData = {
        'orderId': widget.orderId,
        'amount': widget.totalAmount,
        'currency': 'INR',
        'userId': userId,
        'customerName': userName,
        'customerEmail': userEmail.isNotEmpty ? userEmail : 'customer@example.com',
        'customerPhone': userPhone.isNotEmpty ? userPhone : '9876543210',
      };

      print('💳 Creating Razorpay order: $orderData');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/razorpay/create-order'),
        headers: {
          'Authorization': 'Bearer ${await TokenManager.getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode(orderData),
      ).timeout(const Duration(seconds: 30));

      print('📥 Create order response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        setState(() {
          _razorpayOrderId = data['razorpayOrderId'];
          _razorpayKeyId = data['keyId'];
          _isProcessing = false;
        });

        print('✅ Razorpay order created: $_razorpayOrderId');
        
        // Open Razorpay checkout
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

  void _openRazorpayCheckout(String userName, String userEmail, String userPhone) {
    var options = {
      'key': _razorpayKeyId,
      'amount': (widget.totalAmount * 100).toInt(), // Convert to paise
      'name': 'Food Delivery',
      'order_id': _razorpayOrderId,
      'description': 'Order #${widget.orderId}',
      'timeout': 300, // 5 minutes
      'prefill': {
        'contact': userPhone.isNotEmpty ? userPhone : '9876543210',
        'email': userEmail.isNotEmpty ? userEmail : 'customer@example.com',
        'name': userName,
      },
      'theme': {
        'color': '#FF6B35'
      }
    };

    print('🎯 Opening Razorpay checkout with options: $options');

    try {
      _razorpay.open(options);
    } catch (e) {
      print('❌ Error opening Razorpay: $e');
      _showErrorDialog('Failed to open payment gateway');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('✅ Payment Success!');
    print('   Payment ID: ${response.paymentId}');
    print('   Order ID: ${response.orderId}');
    print('   Signature: ${response.signature}');

    setState(() => _isProcessing = true);

    try {
      // Verify payment on backend
      final verifyData = {
        'razorpayOrderId': response.orderId ?? _razorpayOrderId,
        'razorpayPaymentId': response.paymentId ?? '',
        'razorpaySignature': response.signature ?? '',
      };

      print('🔍 Verifying payment: $verifyData');

      final verifyResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/razorpay/verify'),
        headers: {
          'Authorization': 'Bearer ${await TokenManager.getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode(verifyData),
      ).timeout(const Duration(seconds: 30));

      print('📥 Verify response: ${verifyResponse.statusCode} - ${verifyResponse.body}');

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
    print('❌ Payment Error!');
    print('   Code: ${response.code}');
    print('   Message: ${response.message}');
    
    _showErrorDialog('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('🔗 External Wallet: ${response.walletName}');
    _showErrorDialog('External wallet selected: ${response.walletName}');
  }

  Future<void> _processCODPayment() async {
    setState(() => _isProcessing = true);

    try {
      print('💵 Processing COD payment for order: ${widget.orderId}');

      // Update payment status to COD
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/cod/${widget.orderId}'),
        headers: {
          'Authorization': 'Bearer ${await TokenManager.getToken()}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 COD response: ${response.statusCode} - ${response.body}');

      setState(() => _isProcessing = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to process COD payment');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      print('❌ COD payment error: $e');
      _showErrorDialog('Failed to process COD payment: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your order has been placed successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to cart with success
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'View My Orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: AppTheme.error,
                size: 64,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Payment Failed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _processPayment();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Retry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text(
                    'Processing payment...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildOrderSummary(),
                  SizedBox(height: 16),
                  _buildPaymentMethods(),
                  SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: _isProcessing
          ? null
          : Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedPaymentMethod == 'CASH_ON_DELIVERY'
                        ? 'Place Order (COD)'
                        : 'Pay ₹${widget.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildSummaryRow('Order ID', '#${widget.orderId}'),
          Divider(height: 24),
          _buildSummaryRow(
            'Total Amount',
            '₹${widget.totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
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

  Widget _buildPaymentMethods() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildPaymentOption(
            'ONLINE',
            'Online Payment',
            'Pay using UPI, Card, Net Banking',
            Icons.payment,
          ),
          SizedBox(height: 12),
          _buildPaymentOption(
            'CASH_ON_DELIVERY',
            'Cash on Delivery',
            'Pay when your order arrives',
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
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.1)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
