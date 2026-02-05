import 'menu_item_model.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get totalPrice => menuItem.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItem.id,
      'quantity': quantity,
      'price': menuItem.price,
    };
  }
}

class Cart {
  final List<CartItem> items = [];
  final int restaurantId;
  final String restaurantName;

  Cart({
    required this.restaurantId,
    required this.restaurantName,
  });

  void addItem(MenuItem menuItem) {
    // Check if item already exists
    final existingIndex = items.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );

    if (existingIndex >= 0) {
      // Increase quantity
      items[existingIndex].quantity++;
    } else {
      // Add new item
      items.add(CartItem(menuItem: menuItem));
    }
  }

  void removeItem(int menuItemId) {
    items.removeWhere((item) => item.menuItem.id == menuItemId);
  }

  void increaseQuantity(int menuItemId) {
    final item = items.firstWhere(
      (item) => item.menuItem.id == menuItemId,
    );
    item.quantity++;
  }

  void decreaseQuantity(int menuItemId) {
    final item = items.firstWhere(
      (item) => item.menuItem.id == menuItemId,
    );
    
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      removeItem(menuItemId);
    }
  }

  void clear() {
    items.clear();
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(
        0,
        (sum, item) => sum + item.totalPrice,
      );

  double get deliveryFee => 40.0; // Fixed for now

  double get taxes => subtotal * 0.05; // 5% tax

  double get grandTotal => subtotal + deliveryFee + taxes;

  bool get isEmpty => items.isEmpty;
}
