class CartItem {
  final int id;
  final int menuItemId;
  final String itemName;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String? specialInstructions;
  final int? restaurantId;
  final String? restaurantName;

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.itemName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.restaurantId,
     this.specialInstructions, 
    this.restaurantName,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({
    int? id,
    int? menuItemId,
    String? itemName,
    double? price,
    int? quantity,
    String? imageUrl,
    int? restaurantId,
    String? restaurantName,
  }) {
    return CartItem(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      menuItemId: json['menuItemId'] ?? json['menu_item_id'] ?? 0,
      itemName: json['itemName'] ?? json['item_name'] ?? json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['imageUrl'] ?? json['image_url'],
      restaurantId: json['restaurantId'] ?? json['restaurant_id'],
       specialInstructions: json['specialInstructions'],
      restaurantName: json['restaurantName'] ?? json['restaurant_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'itemName': itemName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
    };
  }
}
