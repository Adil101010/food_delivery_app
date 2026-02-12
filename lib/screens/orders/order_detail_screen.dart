import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  Order? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final order = await _orderService.getOrderById(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = _order?.canCancel ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                ),
              )
            : _error != null
                ? _buildErrorState()
                : _order == null
                    ? Center(
                        child: Text(
                          'Order not found',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            _StatusCard(order: _order!),
                            const SizedBox(height: 8),
                            _RestaurantInfo(order: _order!),
                            const SizedBox(height: 8),
                            _OrderItems(order: _order!),
                            const SizedBox(height: 8),
                            _DeliveryInfo(order: _order!),
                            const SizedBox(height: 8),
                            _PriceSummary(order: _order!),
                            const SizedBox(height: 16),
                            if (!canCancel)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _order!.status.toUpperCase() == 'CANCELLED'
                                        ? 'This order has already been cancelled.'
                                        : 'You can no longer cancel this order.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
      ),
      bottomNavigationBar: _order != null && _order!.canCancel
          ? _CancelBottomBar(
              orderId: _order!.id,
              onCancelled: () {
                Navigator.pop(context);
              },
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Order',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrderDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Order order;

  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Order id + created date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (order.formattedCreatedAt != null)
                Text(
                  order.formattedCreatedAt!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(order.status),
                  size: 26,
                  color: order.statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.statusDisplay,
                      style: TextStyle(
                        color: order.statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusMessage(order.status),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.schedule;
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'PREPARING':
        return Icons.restaurant;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Your order is waiting for restaurant confirmation';
      case 'CONFIRMED':
        return 'Restaurant has confirmed your order';
      case 'PREPARING':
        return 'Your delicious food is being prepared';
      case 'OUT_FOR_DELIVERY':
        return 'Your order is on the way';
      case 'DELIVERED':
        return 'Your order has been delivered. Enjoy your meal!';
      case 'CANCELLED':
        return 'This order has been cancelled';
      default:
        return 'Processing your order';
    }
  }
}

class _RestaurantInfo extends StatelessWidget {
  final Order order;

  const _RestaurantInfo({required this.order});

  @override
  Widget build(BuildContext context) {
    final initial = order.restaurantName.isNotEmpty
        ? order.restaurantName[0].toUpperCase()
        : 'R';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.restaurantName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Restaurant • ${order.items.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItems extends StatelessWidget {
  final Order order;

  const _OrderItems({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: order.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (index > 0)
                      Divider(
                        color: AppTheme.border,
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'Rs ${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryInfo extends StatelessWidget {
  final Order order;

  const _DeliveryInfo({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on,
              color: AppTheme.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.deliveryAddress,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final Order order;

  const _PriceSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final deliveryFee = order.deliveryFee ?? 40.0;
    final tax = order.tax ?? 0.0;
    final subtotal = order.subtotal ?? (order.totalAmount - deliveryFee - tax);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Item Total', subtotal),
          const SizedBox(height: 12),
          _buildPriceRow('Delivery Fee', deliveryFee),
          if (tax > 0) ...[
            const SizedBox(height: 12),
            _buildPriceRow('Taxes & Charges', tax),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppTheme.border, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rs ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          'Rs ${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CancelBottomBar extends StatelessWidget {
  final int orderId;
  final VoidCallback onCancelled;

  const _CancelBottomBar({
    required this.orderId,
    required this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showCancelDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: BorderSide(color: AppTheme.error, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel Order',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            const SizedBox(width: 12),
            const Text('Cancel Order?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No, Keep it',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelOrder(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context) async {
    try {
      await OrderService().cancelOrder(orderId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order cancelled successfully'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        onCancelled();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to cancel: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
