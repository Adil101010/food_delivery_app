import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../config/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../orders/order_confirmation_screen.dart';
import '../../services/token_manager.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  final _paymentService = PaymentService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedPaymentMethod = 'CASH_ON_DELIVERY';
  bool _isProcessing = false;

 
  late Razorpay _razorpay;

 
  Map<String, dynamic>? _currentOrderData;
  Map<String, dynamic>? _currentPaymentData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initRazorpay();
  }

 
  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  
  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    print('  Payment Success: ${response.paymentId}');
    print('   Order ID: ${response.orderId}');
    print('   Signature: ${response.signature}');

    setState(() => _isProcessing = true);

    try {
     
      final orderId = _currentOrderData?['id'];

      final verifyResponse = await _paymentService.verifyPayment(
        orderId: orderId,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      print(' Payment verified: $verifyResponse');

      
      if (mounted) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        await cartProvider.clearCart();
      }

      setState(() => _isProcessing = false);

      if (!mounted) return;

      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(
            orderId: orderId ?? 0,
            orderData: _currentPaymentData ?? {},
          ),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      print(' Verification failed: $e');
      if (!mounted) return;
      _showSnack('Payment verification failed. Please contact support.', isError: true);
    }
  }

  
  void _onPaymentError(PaymentFailureResponse response) {
    print(' Payment Failed: ${response.code} - ${response.message}');
    setState(() => _isProcessing = false);

    _showSnack(
      'Payment failed: ${response.message ?? "Please try again"}',
      isError: true,
    );

    
    final orderId = _currentOrderData?['id'];
    if (orderId != null) {
      _orderService.cancelOrder(orderId).catchError((e) {
        print('Cancel order error: $e');
      });
    }
  }

 
  void _onExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
  }

 
  Future<void> _loadUserData() async {
    final userName = await TokenManager.getUserName();
    final userPhone = await TokenManager.getUserPhone();
    if (!mounted) return;
    setState(() {
      _nameController.text = userName ?? '';
      _phoneController.text = userPhone ?? '';
    });
  }

 
  Future<void> _placeOrder() async {
   
    final isLoggedIn = await TokenManager.isLoggedIn();
    if (!isLoggedIn) {
      _showSnack('Please login to place order', isError: true);
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final userId = await TokenManager.getUserId();
    final userEmail = await TokenManager.getUserEmail();

    if (userId == null) {
      _showSnack('Session expired. Please login again.', isError: true);
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.isEmpty) {
      _showSnack('Cart is empty', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final orderData = {
        'userId': userId,
        'restaurantId': cartProvider.restaurantId ?? 1,
        'restaurantName': cartProvider.restaurantName ?? 'Restaurant',
        'customerName': _nameController.text.trim(),
        'customerPhone': _phoneController.text.trim(),
        'customerEmail': userEmail ?? '',
        'deliveryAddress': _addressController.text.trim(),
        'deliveryInstructions': _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        'subtotal': cartProvider.subtotal,
        'deliveryFee': cartProvider.deliveryFee,
        'tax': cartProvider.tax,
        'discount': cartProvider.discount,
        'totalAmount': cartProvider.total,
        'paymentMethod': _selectedPaymentMethod,
        'items': cartProvider.items.map((item) => {
          'menuItemId': item.menuItemId,
          'itemName': item.itemName,
          'price': item.price,
          'quantity': item.quantity,
          'totalPrice': item.totalPrice,
        }).toList(),
      };

      
      final response = await _orderService.createOrder(orderData);
      final data = response['data'];
      final orderInfo = data['order'];
      final paymentInfo = data['payment'];

      print(' Order created: ${orderInfo['id']} — Status: ${orderInfo['orderStatus']}');

  
      _currentOrderData = orderInfo;
      _currentPaymentData = data;

      
      if (_selectedPaymentMethod == 'CASH_ON_DELIVERY') {
        await _processCOD(orderInfo['id'], userId);
      } else {
        
        _openRazorpay(paymentInfo, orderInfo, userEmail ?? '');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      print(' Order Error: $e');
      if (!mounted) return;

      final msg = e.toString().replaceAll('Exception: ', '');
      _showSnack(msg, isError: true);
    }
  }

  Future<void> _processCOD(int orderId, int userId) async {
    try {
      print('🚗 Processing COD for order: $orderId');

      
      await _paymentService.processCOD(
        orderId: orderId,
        userId: userId,
      );

      print(' COD confirmed');

      
      if (mounted) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        await cartProvider.clearCart();
      }

      setState(() => _isProcessing = false);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(
            orderId: orderId,
            orderData: _currentPaymentData ?? {},
          ),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      print(' COD Error: $e');
      _showSnack('COD processing failed. Please try again.', isError: true);
    }
  }

  
  void _openRazorpay(
    Map<String, dynamic>? paymentInfo,
    Map<String, dynamic> orderInfo,
    String userEmail,
  ) {
    setState(() => _isProcessing = false);

    if (paymentInfo == null) {
      _showSnack('Payment initialization failed. Please try again.', isError: true);
      return;
    }

    final options = {
      'key': paymentInfo['keyId'],
      'amount': ((orderInfo['totalAmount'] as num) * 100).toInt(),
      'currency': 'INR',
      'name': 'Food Delivery',
      'description': 'Order #${orderInfo['id']}',
      'order_id': paymentInfo['razorpayOrderId'],
      'prefill': {
        'name': _nameController.text.trim(),
        'email': userEmail,
        'contact': _phoneController.text.trim(),
      },
      'theme': {'color': '#FF6B35'},
    };

    print(' Opening Razorpay: $options');

    try {
      _razorpay.open(options);
    } catch (e) {
      print(' Razorpay open error: $e');
      _showSnack('Could not open payment. Please try again.', isError: true);
    }
  }

 
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.isEmpty) {
              return const Center(child: Text('Cart is empty'));
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        _buildHeaderSection(cartProvider, cartProvider.total),
                        const SizedBox(height: 8),
                        _buildDeliveryForm(),
                        const SizedBox(height: 8),
                        _buildPaymentSection(),
                        const SizedBox(height: 8),
                        _buildBillSummary(
                          cartProvider.subtotal,
                          cartProvider.deliveryFee,
                          cartProvider.tax,
                          cartProvider.total,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeaderSection(CartProvider cartProvider, double grandTotal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ordering from',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(
            cartProvider.restaurantName ?? 'Restaurant',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${cartProvider.totalItems} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: AppTheme.textLight)),
              const SizedBox(width: 8),
              Text(
                'Rs ${grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter phone number';
                if (v.trim().length != 10) return 'Must be 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Delivery Address',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter address' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _instructionsController,
              label: 'Delivery Instructions (Optional)',
              icon: Icons.note_outlined,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _PaymentOption(
            title: 'Cash on Delivery',
            icon: Icons.money,
            value: 'CASH_ON_DELIVERY',
            groupValue: _selectedPaymentMethod,
            onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
          ),
          const SizedBox(height: 8),
          _PaymentOption(
            title: 'Razorpay (UPI, Card, Wallet)',
            icon: Icons.payment,
            value: 'RAZORPAY',
            groupValue: _selectedPaymentMethod,
            onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSummary(
      double subtotal, double deliveryFee, double tax, double grandTotal) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _billRow('Item Total', subtotal),
          const SizedBox(height: 12),
          _billRow('Delivery Fee', deliveryFee),
          const SizedBox(height: 12),
          _billRow('Taxes & Charges (5%)', tax),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppTheme.border, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('To Pay',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              Text(
                'Rs ${grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        Text('Rs ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_isProcessing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, boxShadow: AppTheme.bottomSheetShadow),
        child: SafeArea(
          top: false,
          child: SizedBox(
              height: 56,
              child:
                  Center(child: CircularProgressIndicator(color: AppTheme.primary))),
        ),
      );
    }

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, boxShadow: AppTheme.bottomSheetShadow),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Place Order',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(width: 8),
                    Text('• Rs ${cartProvider.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


class _PaymentOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.title,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color:
              isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
