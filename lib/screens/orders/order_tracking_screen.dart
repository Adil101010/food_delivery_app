import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../config/app_theme.dart';
import '../../models/delivery_tracking_model.dart';
import '../../services/tracking_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final TrackingService _trackingService = TrackingService();
  GoogleMapController? _mapController;

  DeliveryTracking? _tracking;
  bool _isLoading = true;
  String? _errorMessage;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  String _eta = 'Calculating...';
  double _distance = 0.0;

  // ✅ Status polling timer (refreshes every 30s)
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
    // ✅ Poll order status every 30 seconds
    _statusPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadTrackingData(silent: true),
    );
  }

  @override
  void dispose() {
    _trackingService.dispose();
    _mapController?.dispose();
    _statusPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrackingData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final tracking =
          await _trackingService.getDeliveryTracking(widget.orderId);

      if (!mounted) return;
      setState(() {
        _tracking = tracking;
        _isLoading = false;
        _errorMessage = null;
      });

      _updateMapMarkers();

      if (tracking.currentLocation != null) {
        _calculateETA();
      }

      // ✅ Start live tracking only for active deliveries
      if (tracking.status == 'PICKED_UP' ||
          tracking.status == 'OUT_FOR_DELIVERY') {
        _trackingService.startLiveTracking(tracking.partnerId, (location) {
          if (!mounted) return;
          setState(() {
            _tracking = _tracking!.copyWith(currentLocation: location);
          });
          _updateMapMarkers();
          _calculateETA();
        });
      } else {
        _trackingService.stopLiveTracking();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!silent) _errorMessage = e.toString();
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tracking not available: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMapMarkers() {
    if (_tracking == null) return;

    final markers = <Marker>{};

    markers.add(Marker(
      markerId: const MarkerId('restaurant'),
      position: LatLng(
        _tracking!.pickupLocation.latitude,
        _tracking!.pickupLocation.longitude,
      ),
      icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: const InfoWindow(title: '🍴 Restaurant'),
    ));

    markers.add(Marker(
      markerId: const MarkerId('delivery'),
      position: LatLng(
        _tracking!.dropLocation.latitude,
        _tracking!.dropLocation.longitude,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: '🏠 Your Location'),
    ));

    if (_tracking!.currentLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('partner'),
        position: LatLng(
          _tracking!.currentLocation!.latitude,
          _tracking!.currentLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: '🛵 ${_tracking!.partnerName}'),
      ));
    }

    if (mounted) setState(() => _markers = markers);

    if (_mapController != null && markers.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), _fitMapToMarkers);
    }
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (var marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.005, minLng - 0.005),
          northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        80,
      ),
    );
  }

  Future<void> _calculateETA() async {
    if (_tracking?.currentLocation == null) return;

    try {
      final result = await _trackingService.calculateETA(
        fromLat: _tracking!.currentLocation!.latitude,
        fromLng: _tracking!.currentLocation!.longitude,
        toLat: _tracking!.dropLocation.latitude,
        toLng: _tracking!.dropLocation.longitude,
      );

      if (!mounted) return;
      setState(() {
        _distance = (result['distance'] ?? 0.0).toDouble();
        final duration = result['duration'] ?? 0;
        _eta = '$duration mins';
      });
    } catch (e) {
      print('ETA error: $e');
    }
  }

  Future<void> _makePhoneCall() async {
    if (_tracking?.partnerPhone.isEmpty ?? true) return;
    final Uri phoneUri = Uri(scheme: 'tel', path: _tracking!.partnerPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  // ================================================================
  //  BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Nice error state — order still PENDING
    if (_tracking == null || _errorMessage != null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildPendingState(),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ✅ Status banner at top
          _buildStatusBanner(),

          // Map
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _tracking!.currentLocation?.latitude ??
                      _tracking!.pickupLocation.latitude,
                  _tracking!.currentLocation?.longitude ??
                      _tracking!.pickupLocation.longitude,
                ),
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapController = controller;
                Future.delayed(
                  const Duration(milliseconds: 500),
                  _fitMapToMarkers,
                );
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),

          // Bottom info panel
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusTimeline(),
                          const SizedBox(height: 20),
                          if (_tracking!.currentLocation != null) ...[
                            _buildETACard(),
                            const SizedBox(height: 16),
                          ],
                          _buildPartnerInfo(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Order #${widget.orderId}'),
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _loadTrackingData(),
        ),
      ],
    );
  }

  // ✅ Pending/No tracking state
  Widget _buildPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delivery_dining_outlined,
                size: 80,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Preparing Your Order',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your order is being prepared.\nTracking will be available once a delivery partner is assigned.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Auto refresh indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Auto-refreshing every 30s',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadTrackingData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Colored status banner
  Widget _buildStatusBanner() {
    final statusConfig = _getStatusConfig(_tracking!.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: statusConfig['color'] as Color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusConfig['icon'] as IconData,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            statusConfig['label'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'ASSIGNED':
        return {
          'label': 'Partner Assigned — Heading to Restaurant',
          'icon': Icons.person,
          'color': Colors.blue,
        };
      case 'PICKED_UP':
        return {
          'label': 'Food Picked Up!',
          'icon': Icons.shopping_bag,
          'color': Colors.orange,
        };
      case 'OUT_FOR_DELIVERY':
        return {
          'label': 'Out for Delivery — Almost There!',
          'icon': Icons.delivery_dining,
          'color': AppTheme.primary,
        };
      case 'DELIVERED':
        return {
          'label': '✅ Delivered Successfully!',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      default:
        return {
          'label': 'Order Confirmed',
          'icon': Icons.receipt,
          'color': Colors.grey,
        };
    }
  }

  Widget _buildStatusTimeline() {
    final statuses = [
      {'status': 'PENDING', 'label': 'Order Placed', 'icon': Icons.receipt},
      {'status': 'ASSIGNED', 'label': 'Partner Assigned', 'icon': Icons.person},
      {'status': 'PICKED_UP', 'label': 'Food Picked Up', 'icon': Icons.shopping_bag},
      {'status': 'OUT_FOR_DELIVERY', 'label': 'Out for Delivery', 'icon': Icons.delivery_dining},
      {'status': 'DELIVERED', 'label': 'Delivered', 'icon': Icons.check_circle},
    ];

    final currentIndex =
        statuses.indexWhere((s) => s['status'] == _tracking!.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...List.generate(statuses.length, (index) {
          final isActive = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final status = statuses[index];

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isCurrent ? AppTheme.primary : Colors.green)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(
                              color: AppTheme.primary.withOpacity(0.3),
                              width: 3)
                          : null,
                    ),
                    child: Icon(
                      status['icon'] as IconData,
                      color: isActive ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  ),
                  if (index < statuses.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: index < currentIndex
                          ? Colors.green
                          : Colors.grey.shade200,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: Row(
                    children: [
                      Text(
                        status['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : (isActive
                                  ? FontWeight.w500
                                  : FontWeight.normal),
                          color: isActive
                              ? AppTheme.textPrimary
                              : Colors.grey,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildETACard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(
                _eta,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('ETA',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Container(width: 1, height: 50, color: Colors.white30),
          Column(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(
                '${_distance.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Distance',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primary,
            child: Text(
              _tracking!.partnerName.isNotEmpty
                  ? _tracking!.partnerName[0].toUpperCase()
                  : 'D',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tracking!.partnerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Delivery Partner',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          // Call button
          if (_tracking!.partnerPhone.isNotEmpty)
            GestureDetector(
              onTap: _makePhoneCall,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone, color: Colors.white, size: 20),
              ),
            ),
          const SizedBox(width: 8),
          // Chat button placeholder
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
