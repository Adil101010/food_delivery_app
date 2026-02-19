class DeliveryTracking {
  final int deliveryId;
  final int orderId;
  final int partnerId;
  final String partnerName;
  final String partnerPhone;
  final String status;
  final DeliveryLocation? currentLocation;
  final DeliveryLocation pickupLocation;
  final DeliveryLocation dropLocation;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final List<String> statusHistory;

  DeliveryTracking({
    required this.deliveryId,
    required this.orderId,
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhone,
    required this.status,
    this.currentLocation,
    required this.pickupLocation,
    required this.dropLocation,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    required this.statusHistory,
  });

  // ✅ copyWith add kiya
  DeliveryTracking copyWith({
    DeliveryLocation? currentLocation,
    String? status,
    DateTime? estimatedDeliveryTime,
  }) {
    return DeliveryTracking(
      deliveryId: deliveryId,
      orderId: orderId,
      partnerId: partnerId,
      partnerName: partnerName,
      partnerPhone: partnerPhone,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      pickupLocation: pickupLocation,
      dropLocation: dropLocation,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime,
      statusHistory: statusHistory,
    );
  }

  factory DeliveryTracking.fromJson(Map<String, dynamic> json) {
    return DeliveryTracking(
      deliveryId: json['deliveryId'] ?? json['delivery_id'] ?? 0,
      orderId: json['orderId'] ?? json['order_id'] ?? 0,
      partnerId: json['partnerId'] ?? json['partner_id'] ?? 0,
      partnerName: json['partnerName'] ?? json['partner_name'] ?? 'Delivery Partner',
      partnerPhone: json['partnerPhone'] ?? json['partner_phone'] ?? '',
      status: json['status'] ?? 'PENDING',
      currentLocation: json['currentLocation'] != null || json['current_location'] != null
          ? DeliveryLocation.fromJson(
              json['currentLocation'] ?? json['current_location'])
          : null,
      pickupLocation: DeliveryLocation.fromJson(
        json['pickupLocation'] ?? json['pickup_location'] ?? {},
      ),
      dropLocation: DeliveryLocation.fromJson(
        json['dropLocation'] ?? json['drop_location'] ?? {},
      ),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : (json['estimated_delivery_time'] != null
              ? DateTime.parse(json['estimated_delivery_time'])
              : null),
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.parse(json['actualDeliveryTime'])
          : null,
      statusHistory: json['statusHistory'] != null
          ? List<String>.from(json['statusHistory'])
          : (json['status_history'] != null
              ? List<String>.from(json['status_history'])
              : []),
    );
  }
}

class DeliveryLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime? timestamp;

  DeliveryLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.timestamp,
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0.0).toDouble(),
      address: json['address'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }
}
