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
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  String _eta = 'Calculating...';
  double _distance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  @override
  void dispose() {
    _trackingService.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadTrackingData() async {
    try {
      final tracking = await _trackingService.getDeliveryTracking(widget.orderId);
      
      setState(() {
        _tracking = tracking;
        _isLoading = false;
      });

      _updateMapMarkers();
      _calculateETA();
      
      // Start live tracking
      if (tracking.status == 'PICKED_UP' || tracking.status == 'OUT_FOR_DELIVERY') {
        _trackingService.startLiveTracking(
          tracking.partnerId,
          (location) {
            setState(() {
              _tracking = DeliveryTracking(
                deliveryId: tracking.deliveryId,
                orderId: tracking.orderId,
                partnerId: tracking.partnerId,
                partnerName: tracking.partnerName,
                partnerPhone: tracking.partnerPhone,
                status: tracking.status,
                currentLocation: location,
                pickupLocation: tracking.pickupLocation,
                dropLocation: tracking.dropLocation,
                estimatedDeliveryTime: tracking.estimatedDeliveryTime,
                actualDeliveryTime: tracking.actualDeliveryTime,
                statusHistory: tracking.statusHistory,
              );
            });
            _updateMapMarkers();
            _calculateETA();
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tracking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMapMarkers() {
    if (_tracking == null) return;

    final markers = <Marker>{};

    // Restaurant marker
    markers.add(
      Marker(
        markerId: const MarkerId('restaurant'),
        position: LatLng(
          _tracking!.pickupLocation.latitude,
          _tracking!.pickupLocation.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Restaurant'),
      ),
    );

    // Delivery location marker
    markers.add(
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(
          _tracking!.dropLocation.latitude,
          _tracking!.dropLocation.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Delivery Location'),
      ),
    );

    // Delivery partner marker (if available)
    if (_tracking!.currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('partner'),
          position: LatLng(
            _tracking!.currentLocation!.latitude,
            _tracking!.currentLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: _tracking!.partnerName),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    // Move camera to show all markers
    if (_mapController != null && markers.isNotEmpty) {
      _fitMapToMarkers();
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
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // padding
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

      setState(() {
        _distance = result['distance'] ?? 0.0;
        final duration = result['duration'] ?? 0;
        _eta = '$duration mins';
      });
    } catch (e) {
      print('Error calculating ETA: $e');
    }
  }

  Future<void> _makePhoneCall() async {
    if (_tracking == null) return;
    
    final Uri phoneUri = Uri(scheme: 'tel', path: _tracking!.partnerPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Tracking'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_tracking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Tracking'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Failed to load tracking information'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map View
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _tracking!.currentLocation?.latitude ?? _tracking!.pickupLocation.latitude,
                  _tracking!.currentLocation?.longitude ?? _tracking!.pickupLocation.longitude,
                ),
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitMapToMarkers();
              },
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),

          // Tracking Info
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
                  // Drag Handle
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
                          // Status Timeline
                          _buildStatusTimeline(),

                          const SizedBox(height: 24),

                          // ETA Card
                          _buildETACard(),

                          const SizedBox(height: 20),

                          // Delivery Partner Info
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

  Widget _buildStatusTimeline() {
    final statuses = [
      {'status': 'PENDING', 'label': 'Order Placed', 'icon': Icons.receipt},
      {'status': 'ASSIGNED', 'label': 'Partner Assigned', 'icon': Icons.person},
      {'status': 'PICKED_UP', 'label': 'Food Picked Up', 'icon': Icons.shopping_bag},
      {'status': 'OUT_FOR_DELIVERY', 'label': 'Out for Delivery', 'icon': Icons.delivery_dining},
      {'status': 'DELIVERED', 'label': 'Delivered', 'icon': Icons.check_circle},
    ];

    final currentIndex = statuses.indexWhere((s) => s['status'] == _tracking!.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(statuses.length, (index) {
          final isActive = index <= currentIndex;
          final status = statuses[index];

          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  if (index < statuses.length - 1)
                    Container(
                      width: 2,
                      height: 30,
                      color: isActive ? AppTheme.primary : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    status['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? AppTheme.textPrimary : Colors.grey,
                    ),
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
              const Icon(Icons.access_time, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                _eta,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'ETA',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white30,
          ),
          Column(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                '${_distance.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Distance',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primary,
            child: Text(
              _tracking!.partnerName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                const Text(
                  'Delivery Partner',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _makePhoneCall,
            icon: const Icon(Icons.phone),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
