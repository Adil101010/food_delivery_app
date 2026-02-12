// lib/models/address.dart

class Address {
  final int? id;
  final int userId;
  final String label;
  final String fullAddress;
  final String? landmark;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Address({
    this.id,
    required this.userId,
    required this.label,
    required this.fullAddress,
    this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      userId: json['userId'],
      label: json['label'] ?? 'Home',
      fullAddress: json['fullAddress'] ?? '',
      landmark: json['landmark'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isDefault: json['isDefault'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'label': label,
      'fullAddress': fullAddress,
      if (landmark != null) 'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'isDefault': isDefault,
    };
  }

  Address copyWith({
    int? id,
    String? label,
    String? fullAddress,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      userId: this.userId,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get displayAddress {
    final parts = [
      fullAddress,
      if (landmark != null && landmark!.isNotEmpty) landmark,
      city,
      state,
      pincode,
    ];
    return parts.join(', ');
  }
}
