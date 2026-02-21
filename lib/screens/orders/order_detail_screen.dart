import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../orders/order_tracking_screen.dart';

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

  
  Widget _buildBottomBar(BuildContext context) {
    final order = _order!;
    final isTrackable = [
      'PENDING', 'CONFIRMED', 'PREPARING',
      'ASSIGNED', 'PICKED_UP', 'OUT_FOR_DELIVERY',
    ].contains(order.status.toUpperCase());

    
    if (!isTrackable && order.canCancel) {
      return _CancelBottomBar(
        orderId: order.id,
        onCancelled: () => Navigator.pop(context),
      );
    }

    if (isTrackable && !order.canCancel) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(orderId: order.id),
                ),
              ),
              icon: const Icon(Icons.location_on, size: 18),
              label: const Text(
                'Track Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (isTrackable && order.canCancel) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () =>
                        _showCancelDialogFromDetail(context, order.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderTrackingScreen(orderId: order.id),
                      ),
                    ),
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text(
                      'Track Order',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

   
    return const SizedBox.shrink();
  }

  void _showCancelDialogFromDetail(BuildContext context, int orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            onPressed: () => Navigator.pop(ctx),
            child: Text('No, Keep it',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
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
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Failed: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Yes, Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
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
                            const SizedBox(height: 8),
                            if (!(_order!.canCancel))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _order!.status.toUpperCase() ==
                                            'CANCELLED'
                                        ? 'This order has already been cancelled.'
                                        : _order!.status.toUpperCase() ==
                                                'DELIVERED'
                                            ? 'Order delivered successfully! '
                                            : 'You can no longer cancel this order.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _order!.status.toUpperCase() ==
                                              'DELIVERED'
                                          ? AppTheme.success
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
      ),
      bottomNavigationBar:
          _order != null ? _buildBottomBar(context) : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppTheme.error),
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
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrderDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


//  STATUS CARD

class _StatusCard extends StatelessWidget {
  final Order order;

  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      fontSize: 12, color: AppTheme.textSecondary),
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
      case 'PENDING':       return Icons.schedule;
      case 'CONFIRMED':     return Icons.check_circle_outline;
      case 'PREPARING':     return Icons.restaurant;
      case 'ASSIGNED':      return Icons.person;
      case 'PICKED_UP':     return Icons.shopping_bag;
      case 'OUT_FOR_DELIVERY': return Icons.delivery_dining;
      case 'DELIVERED':     return Icons.check_circle;
      case 'CANCELLED':     return Icons.cancel_outlined;
      default:              return Icons.info_outline;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':       return 'Waiting for restaurant confirmation';
      case 'CONFIRMED':     return 'Restaurant has confirmed your order';
      case 'PREPARING':     return 'Your food is being prepared';
      case 'ASSIGNED':      return 'Delivery partner assigned';
      case 'PICKED_UP':     return 'Food picked up from restaurant';
      case 'OUT_FOR_DELIVERY': return 'Your order is on the way!';
      case 'DELIVERED':     return 'Delivered! Enjoy your meal ';
      case 'CANCELLED':     return 'This order has been cancelled';
      default:              return 'Processing your order';
    }
  }
}


//  RESTAURANT INFO

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
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
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
                  '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//  ORDER ITEMS

class _OrderItems extends StatelessWidget {
  final Order order;

  const _OrderItems({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long,
                  size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Items',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
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
                          endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary),
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(0)}',
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


//  DELIVERY INFO

class _DeliveryInfo extends StatelessWidget {
  final Order order;

  const _DeliveryInfo({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on, color: AppTheme.error, size: 24),
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
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  order.deliveryAddress,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


//  PRICE SUMMARY

class _PriceSummary extends StatelessWidget {
  final Order order;

  const _PriceSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final deliveryFee = order.deliveryFee ?? 40.0;
    final tax = order.tax ?? 0.0;
    final subtotal =
        order.subtotal ?? (order.totalAmount - deliveryFee - tax);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Details',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Item Total', subtotal),
          const SizedBox(height: 12),
          _buildPriceRow('Delivery Fee',
              deliveryFee == 0 ? null : deliveryFee,
              freeLabel: deliveryFee == 0),
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
                    color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildPriceRow(String label, double? amount,
      {bool freeLabel = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary)),
        freeLabel
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FREE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              )
            : Text(
                '₹${amount?.toStringAsFixed(0) ?? '0'}',
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


//  CANCEL BOTTOM BAR

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
          height: 50,
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            onPressed: () => Navigator.pop(ctx),
            child: Text('No, Keep it',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _cancelOrder(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Yes, Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
                'Failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
