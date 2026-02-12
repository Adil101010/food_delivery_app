import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/app_theme.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final dynamic orderId;
  final Map<String, dynamic> orderData;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
    required this.orderData,
  }) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderData['order'] as Map<String, dynamic>?;
    final payment = widget.orderData['payment'] as Map<String, dynamic>?;

    if (order == null) {
      return _buildSimpleSuccess();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Order Confirmed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildConfettiBackground(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildSuccessAnimation(),
                  const SizedBox(height: 32),
                  _buildSuccessMessage(),
                  const SizedBox(height: 24),
                  _buildOrderIdCard(),
                  const SizedBox(height: 24),
                  _buildOrderDetailsCard(order, payment),
                  const SizedBox(height: 20),
                  if (order['estimatedDeliveryTime'] != null)
                    _buildDeliveryTimeCard(order),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _ConfettiPainter(_animationController.value),
          );
        },
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppTheme.success.withOpacity(0.2),
              AppTheme.success.withOpacity(0.1),
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.success.withOpacity(0.3),
                AppTheme.success.withOpacity(0.2),
              ],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          const Text(
            '🎉 Order Placed Successfully!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your delicious food is on its way',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderIdCard() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withOpacity(0.1),
              AppTheme.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, color: AppTheme.primary, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${widget.orderId}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(Map<String, dynamic> order, Map<String, dynamic>? payment) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 1.5),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Restaurant Info - FIXED
            _buildInfoTile(
              icon: Icons.restaurant_rounded,
              iconColor: AppTheme.primary,
              title: 'Restaurant',
              subtitle: order['restaurantName'] ?? 'Restaurant',
              trailing: Text(
                '${(order['items'] as List?)?.length ?? 0} items',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            _buildDivider(),
            
            // Delivery Address
            _buildInfoTile(
              icon: Icons.location_on,
              iconColor: Colors.red,
              title: 'Delivery Address',
              subtitle: order['deliveryAddress'] ?? 'N/A',
            ),
            _buildDivider(),
            
            // Order Status
            _buildInfoTile(
              icon: Icons.schedule_rounded,
              iconColor: Colors.orange,
              title: 'Order Status',
              subtitle: '',
              trailing: _buildStatusBadge(order['orderStatus'] ?? 'PENDING'),
            ),
            
            if (payment != null) ...[
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.payment,
                iconColor: Colors.blue,
                title: 'Payment Method',
                subtitle: (order['paymentMethod'] ?? 'CASH_ON_DELIVERY')
                    .replaceAll('_', ' '),
                trailing: _buildPaymentBadge(payment['status'] ?? 'PENDING'),
              ),
            ],
            
            _buildDivider(),
            
            // Total Amount
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${(order['totalAmount'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'PENDING' ? Colors.orange : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    final color = status == 'PENDING' ? Colors.orange : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade200,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildDeliveryTimeCard(Map<String, dynamic> order) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 2),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.access_time_rounded,
                color: Colors.green.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Delivery',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(order['estimatedDeliveryTime']),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 2.5),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/orders');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSuccess() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSuccessAnimation(),
              const SizedBox(height: 32),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Order ID: #${widget.orderId}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();

      if (dateTime.day == now.day &&
          dateTime.month == now.month &&
          dateTime.year == now.year) {
        return 'Today, ${_formatTime(dateTime)}';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${_formatTime(dateTime)}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// Confetti Painter for celebration effect
class _ConfettiPainter extends CustomPainter {
  final double animationValue;

  _ConfettiPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue < 0.3) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = (animationValue - 0.3) * size.height * 2 +
          (random.nextDouble() * 100 - 50);

      if (y < size.height) {
        paint.color = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.pink,
        ][i % 6].withOpacity(0.7);

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(random.nextDouble() * math.pi * 2);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 12),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
