class Restaurant {
  final int id;
  final String name;
  final String? description;
  final String address;
  final String? city;
  final String? state;
  final String? pincode;
  final String phone;
  final String email;
  final String cuisine;
  final double rating;
  final int? avgDeliveryTime;
  final double? deliveryFee;
  final bool isActive;
  final bool isOpen;
  final String openingTime;
  final String closingTime;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    this.city,
    this.state,
    this.pincode,
    required this.phone,
    required this.email,
    required this.cuisine,
    required this.rating,
    this.avgDeliveryTime,
    this.deliveryFee,
    required this.isActive,
    required this.isOpen,
    required this.openingTime,
    required this.closingTime,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Restaurant',
      description: json['description'],
      address: json['address'] ?? '',
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      cuisine: json['cuisine'] ?? 'Multi-cuisine',
      rating: (json['rating'] ?? 0.0).toDouble(),
      avgDeliveryTime: json['avgDeliveryTime'],
      deliveryFee: json['deliveryFee'] != null 
          ? (json['deliveryFee']).toDouble() 
          : null,
      isActive: json['isActive'] ?? true,
      isOpen: json['isOpen'] ?? false,
      openingTime: json['openingTime'] ?? '09:00:00',
      closingTime: json['closingTime'] ?? '23:00:00',
    );
  }
}
