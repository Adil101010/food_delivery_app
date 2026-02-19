// lib/screens/cart/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../providers/cart_provider.dart';
import '../../services/token_manager.dart';
import '../../services/promo_service.dart';
import '../payment/payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessingOrder = false;
  bool _isBillExpanded = false; // ✅ Bill collapse/expand

  final _couponController = TextEditingController();
  String _couponCode = '';
  double _discountAmount = 0.0;
  bool _couponApplied = false;
  bool _isValidating = false;
  String _couponMessage = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CartProvider>().loadCart());
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _couponMessage = 'Please enter a coupon code');
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    final userId = await TokenManager.getUserId();

    setState(() => _isValidating = true);

    final result = await PromoService.validateCoupon(
      couponCode: code,
      orderAmount: cart.subtotal + cart.deliveryFee + cart.tax,
      userId: userId ?? 0,
      restaurantId: cart.restaurantId ?? 1,
    );

    setState(() {
      _isValidating = false;
      if (result['valid'] == true) {
        _couponApplied = true;
        _couponCode = code;
        _discountAmount = double.parse(result['discountAmount'].toString());
        _couponMessage = result['message'] ?? 'Coupon applied!';
      } else {
        _couponApplied = false;
        _discountAmount = 0.0;
        _couponMessage = result['message'] ?? 'Invalid coupon';
      }
    });
  }

  void _removeCoupon() {
    setState(() {
      _couponApplied = false;
      _discountAmount = 0.0;
      _couponCode = '';
      _couponMessage = '';
      _couponController.clear();
    });
  }

  Future<void> _proceedToCheckout() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    setState(() => _isProcessingOrder = true);

    try {
      final userId = await TokenManager.getUserId();
      final userEmail = await TokenManager.getUserEmail() ?? '';
      final userPhone = await TokenManager.getUserPhone() ?? '';
      final userName = await TokenManager.getUserName() ?? '';

      if (userId == null) throw Exception('User not logged in');

      final finalAmount =
          cart.subtotal + cart.deliveryFee + cart.tax - _discountAmount;

      final orderData = {
        'userId': userId,
        'restaurantId': cart.restaurantId,
        'restaurantName': cart.restaurantName,
        'items': cart.items
            .map((item) => {
                  'menuItemId': item.menuItemId,
                  'itemName': item.itemName,
                  'quantity': item.quantity,
                  'price': item.price,
                })
            .toList(),
        'deliveryFee': cart.deliveryFee,
        'discount': _discountAmount,
        'couponCode': _couponApplied ? _couponCode : null,
        'totalAmount': finalAmount,
        'paymentMethod': 'CASH_ON_DELIVERY',
        'deliveryAddress': 'Default Address, New Delhi, India',
        'deliveryInstructions': 'Please call before delivery',
        'customerPhone': userPhone,
        'customerName': userName,
        'customerEmail': userEmail,
      };

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/orders'),
            headers: {
              'Authorization': 'Bearer ${await TokenManager.getToken()}',
              'Content-Type': 'application/json',
            },
            body: json.encode(orderData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final orderResponse = json.decode(response.body);

        int? orderId;
        String? razorpayOrderId;
        String? razorpayKeyId;

        if (orderResponse['data']?['order']?['id'] != null) {
          orderId = orderResponse['data']['order']['id'];
          if (orderResponse['data']['payment'] != null) {
            razorpayOrderId =
                orderResponse['data']['payment']['razorpayOrderId'];
            razorpayKeyId = orderResponse['data']['payment']['keyId'];
          }
        } else if (orderResponse['data']?['id'] != null) {
          orderId = orderResponse['data']['id'];
        } else if (orderResponse['id'] != null) {
          orderId = orderResponse['id'];
        }

        if (orderId == null) throw Exception('Order ID not found in response');

        setState(() => _isProcessingOrder = false);

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              orderId: orderId!,
              totalAmount: finalAmount,
              razorpayOrderId: razorpayOrderId,
              razorpayKeyId: razorpayKeyId,
            ),
          ),
        );

        if (result == true) {
          cart.clearCart();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Order placed successfully!'),
              ]),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
            Navigator.pushReplacementNamed(context, '/orders');
          }
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      setState(() => _isProcessingOrder = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Failed to create order: $e')),
          ]),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true, // ✅ keyboard ke saath scroll hoga
      appBar: _buildAppBar(),
      body: _isProcessingOrder
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text('Creating your order...',
                      style: TextStyle(
                          fontSize: 16, color: AppTheme.textSecondary)),
                ],
              ),
            )
          : Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary));
                }
                if (cart.error != null) return _buildErrorState(cart);
                if (cart.isEmpty) return _buildEmptyState();

                return Column(
                  children: [
                    // ✅ Items + Coupon scroll hoga
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          children: [
                            _buildRestaurantHeader(cart),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              itemCount: cart.items.length,
                              itemBuilder: (context, index) {
                                return _CartItemCard(
                                    item: cart.items[index], index: index);
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildCouponSection(),
                            const SizedBox(height: 100), // bottom bar space
                          ],
                        ),
                      ),
                    ),

                    // ✅ Bill details + Checkout button — hamesha niche fixed
                    _buildBottomBillBar(cart),
                  ],
                );
              },
            ),
    );
  }

  // ✅ Bottom Bar — Collapsed by default, tap se expand
  Widget _buildBottomBillBar(CartProvider cart) {
    final finalTotal =
        cart.subtotal + cart.deliveryFee + cart.tax - _discountAmount;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Tap karo to expand/collapse
            InkWell(
              onTap: () => setState(() => _isBillExpanded = !_isBillExpanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long,
                            color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Bill Details',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('${cart.totalItems} items',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('₹${finalTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary)),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _isBillExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(Icons.keyboard_arrow_up,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Expandable Bill Rows
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  children: [
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 10),
                    _BillRow(
                        label: 'Item Total',
                        value: '₹${cart.subtotal.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    _BillRow(
                      label: 'Delivery Fee',
                      value: cart.deliveryFee > 0
                          ? '₹${cart.deliveryFee.toStringAsFixed(0)}'
                          : 'FREE',
                      isPositive: cart.deliveryFee == 0,
                    ),
                    const SizedBox(height: 8),
                    _BillRow(
                        label: 'GST (5%)',
                        value: '₹${cart.tax.toStringAsFixed(0)}'),
                    if (_couponApplied && _discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      _BillRow(
                        label: 'Discount ($_couponCode)',
                        value: '- ₹${_discountAmount.toStringAsFixed(0)}',
                        isDiscount: true,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('To Pay',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary)),
                        Text('₹${finalTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _isBillExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            // ✅ Checkout Button — hamesha visible
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Proceed to Checkout',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(width: 8),
                      Text('• ₹${finalTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎟️ Apply Coupon',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  enabled: !_couponApplied,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    prefixIcon: const Icon(Icons.local_offer_outlined,
                        color: Colors.orange, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.border)),
                    disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.green.shade300)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _couponApplied ? _removeCoupon : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _couponApplied ? Colors.red : AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _isValidating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _couponApplied ? 'Remove' : 'Apply',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                ),
              ),
            ],
          ),
          if (_couponMessage.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  _couponApplied
                      ? Icons.check_circle
                      : Icons.error_outline,
                  color: _couponApplied ? Colors.green : AppTheme.error,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(_couponMessage,
                      style: TextStyle(
                          color: _couponApplied
                              ? Colors.green
                              : AppTheme.error,
                          fontSize: 12)),
                ),
              ],
            ),
          ],
          if (_couponApplied && _discountAmount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🎉 $_couponCode Applied',
                      style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text('- ₹${_discountAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
          if (!_couponApplied) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CouponChip(
                    code: 'SAVE20',
                    desc: '20% off',
                    onTap: () => setState(
                        () => _couponController.text = 'SAVE20'),
                  ),
                  const SizedBox(width: 8),
                  _CouponChip(
                    code: 'FLAT50',
                    desc: '₹50 off',
                    onTap: () => setState(
                        () => _couponController.text = 'FLAT50'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('My Cart',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary)),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            if (cart.items.isEmpty) return const SizedBox();
            return IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              tooltip: 'Clear cart',
              onPressed: () => _showClearCartDialog(context),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRestaurantHeader(CartProvider cart) {
    if (cart.restaurantName == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant,
                color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cart.restaurantName!,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(
                    '${cart.totalItems} items • ₹${cart.subtotal.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CartProvider cart) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle),
              child:
                  Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            ),
            const SizedBox(height: 24),
            const Text('Oops! Something went wrong',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(cart.error ?? 'Unknown error',
                style:
                    TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => cart.loadCart(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.shopping_cart_outlined,
                  size: 80, color: AppTheme.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 32),
            const Text('Your cart is empty',
                style: TextStyle(
                    fontSize: 24,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Add delicious items to get started!',
                style:
                    TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse Restaurants'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.delete_outline,
                  color: AppTheme.error, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Clear Cart?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ],
        ),
        content: const Text(
            'Are you sure you want to remove all items from your cart?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<CartProvider>().clearCart();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(children: const [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Cart cleared successfully'),
                      ]),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}

// ─── Cart Item Card ───────────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final int index;
  const _CartItemCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(item.imageUrl!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _PlaceholderImage())
                        : const _PlaceholderImage(),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4)
                        ],
                      ),
                      child: Text('${item.quantity}x',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.itemName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('₹${item.price.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary)),
                        Text(' × ${item.quantity}',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => context
                                    .read<CartProvider>()
                                    .decrementQuantity(item.id),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.remove,
                                        size: 16, color: Colors.white)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Text('${item.quantity}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                              InkWell(
                                onTap: () => context
                                    .read<CartProvider>()
                                    .incrementQuantity(item.id),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.add,
                                        size: 16, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                        Text('₹${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Placeholder Image ────────────────────────────────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.fastfood_outlined,
          size: 40, color: AppTheme.textLight),
    );
  }
}

// ─── Coupon Chip ──────────────────────────────────────────────────────────────
class _CouponChip extends StatelessWidget {
  final String code;
  final String desc;
  final VoidCallback onTap;

  const _CouponChip(
      {required this.code, required this.desc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer, size: 12, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text('$code • $desc',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700)),
          ],
        ),
      ),
    );
  }
}

// ─── Bill Row ─────────────────────────────────────────────────────────────────
class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;
  final bool isDiscount;

  const _BillRow({
    required this.label,
    required this.value,
    this.isPositive = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color:
                    isDiscount ? Colors.green : AppTheme.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                color: isDiscount
                    ? Colors.green
                    : isPositive
                        ? AppTheme.success
                        : AppTheme.textPrimary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
