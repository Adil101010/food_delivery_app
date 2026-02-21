import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import 'order_detail_screen.dart';
import '../orders/order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _filters = ['All', 'Ongoing', 'Completed', 'Cancelled'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _orderService.getUserOrders();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<Order> get _filteredOrders {
    switch (_selectedFilter) {
      case 'Ongoing':
        return _orders.where((o) {
          final s = o.status.toUpperCase();
          return s == 'PENDING' ||
              s == 'CONFIRMED' ||
              s == 'PREPARING' ||
              s == 'ASSIGNED' ||
              s == 'PICKED_UP' ||
              s == 'OUT_FOR_DELIVERY';
        }).toList();
      case 'Completed':
        return _orders
            .where((o) => o.status.toUpperCase() == 'DELIVERED')
            .toList();
      case 'Cancelled':
        return _orders
            .where((o) => o.status.toUpperCase() == 'CANCELLED')
            .toList();
      default:
        return _orders;
    }
  }

  void _navigateToOrderDetail(Order order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: order.id),
      ),
    );
    _loadOrders();
  }

  void _navigateToTracking(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(orderId: order.id),
      ),
    );
  }

 
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildErrorState()
              : _orders.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: AppTheme.primary,
                      child: Column(
                        children: [
                          _buildHeaderAndFilters(filtered.length),
                          const SizedBox(height: 4),
                          Expanded(
                            child: filtered.isEmpty
                                ? _buildFilterEmptyState()
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 16),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final order = filtered[index];
                                      return _OrderCard(
                                        order: order,
                                        onTap: () =>
                                            _navigateToOrderDetail(order),
                                        onTrack: () =>
                                            _navigateToTracking(order),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
    );
  }

 
  //  HEADER + FILTERS
  
  Widget _buildHeaderAndFilters(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count Order${count != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                onPressed: _loadOrders,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final isSelected = _selectedFilter == f;

               
                int badgeCount = 0;
                if (f == 'Ongoing') {
                  badgeCount = _orders.where((o) {
                    final s = o.status.toUpperCase();
                    return s == 'PENDING' ||
                        s == 'CONFIRMED' ||
                        s == 'PREPARING' ||
                        s == 'ASSIGNED' ||
                        s == 'PICKED_UP' ||
                        s == 'OUT_FOR_DELIVERY';
                  }).length;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                         
                          if (f == 'Ongoing' && badgeCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.3)
                                    : AppTheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
              'Failed to Load Orders',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
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
            Icon(Icons.receipt_long_outlined,
                size: 100, color: AppTheme.textLight),
            const SizedBox(height: 24),
            Text(
              'No orders yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Start ordering delicious food!',
              style:
                  TextStyle(fontSize: 14, color: AppTheme.textLight),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse Restaurants',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off,
              size: 60, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'No $_selectedFilter orders',
            style: TextStyle(
                fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}


class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final VoidCallback onTrack;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onTrack,
  });

  bool get _isTrackable {
    final s = order.status.toUpperCase();
    return s == 'PENDING' ||
        s == 'CONFIRMED' ||
        s == 'PREPARING' ||
        s == 'ASSIGNED' ||
        s == 'PICKED_UP' ||
        s == 'OUT_FOR_DELIVERY';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
        
          color: _isTrackable
              ? AppTheme.primary.withOpacity(0.4)
              : AppTheme.border,
          width: _isTrackable ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
         
              if (_isTrackable)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active Order',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.restaurant_rounded,
                        color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Order #${order.id}',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: order.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: order.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      order.statusDisplay,
                      style: TextStyle(
                        color: order.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Items + Time
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fastfood_outlined,
                        size: 15, color: AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.access_time,
                        size: 15, color: AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(order.createdAt),
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Row — Price + Buttons
              Row(
                children: [
                  // Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  //  Track button — only for active orders
                  if (_isTrackable) ...[
                    ElevatedButton.icon(
                      onPressed: onTrack,
                      icon: const Icon(Icons.location_on, size: 15),
                      label: const Text(
                        'Track',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // View Details button
                  OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      side: BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Details',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final h = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
      final m = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $h:$m $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
