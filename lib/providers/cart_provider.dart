import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';

class CartProvider extends ChangeNotifier {
  Cart? _cart;

  Cart? get cart => _cart;

  bool get hasCart => _cart != null;

  int get totalItems => _cart?.totalItems ?? 0;

  double get grandTotal => _cart?.grandTotal ?? 0.0;

  void createCart(int restaurantId, String restaurantName) {
    _cart = Cart(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );
    notifyListeners();
  }

  void addItem(MenuItem menuItem, int restaurantId, String restaurantName) {
    // If cart doesn't exist or different restaurant, create new cart
    if (_cart == null || _cart!.restaurantId != restaurantId) {
      _cart = Cart(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      );
    }

    _cart!.addItem(menuItem);
    notifyListeners();
  }

  void removeItem(int menuItemId) {
    if (_cart == null) return;
    _cart!.removeItem(menuItemId);
    
    if (_cart!.isEmpty) {
      _cart = null;
    }
    
    notifyListeners();
  }

  void increaseQuantity(int menuItemId) {
    if (_cart == null) return;
    _cart!.increaseQuantity(menuItemId);
    notifyListeners();
  }

  void decreaseQuantity(int menuItemId) {
    if (_cart == null) return;
    _cart!.decreaseQuantity(menuItemId);
    
    if (_cart!.isEmpty) {
      _cart = null;
    }
    
    notifyListeners();
  }

  void clearCart() {
    _cart = null;
    notifyListeners();
  }

  int getItemQuantity(int menuItemId) {
    if (_cart == null) return 0;
    
    try {
      final item = _cart!.items.firstWhere(
        (item) => item.menuItem.id == menuItemId,
      );
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  bool isInCart(int menuItemId) {
    if (_cart == null) return false;
    return _cart!.items.any((item) => item.menuItem.id == menuItemId);
  }
}
