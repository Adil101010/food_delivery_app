class MenuItem {
  final int id;
  final int restaurantId;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isVegan;
  final bool isSpicy;
  final bool isBestseller;
  final int? preparationTime;
  final double? rating;
  final int? calories;
  final int spiceLevel;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.isVegetarian,
    required this.isVegan,
    required this.isSpicy,
    required this.isBestseller,
    this.preparationTime,
    this.rating,
    this.calories,
    required this.spiceLevel,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      name: json['name'] ?? 'Unknown Item',
      description: json['description'],
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'OTHER',
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      isVegetarian: json['isVegetarian'] ?? false,
      isVegan: json['isVegan'] ?? false,
      isSpicy: json['isSpicy'] ?? false,
      isBestseller: json['isBestseller'] ?? false,
      preparationTime: json['preparationTime'],
      rating: json['rating'] != null ? (json['rating']).toDouble() : null,
      calories: json['calories'],
      spiceLevel: json['spiceLevel'] ?? 0,
    );
  }
}
