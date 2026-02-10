import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  int get totalItems => itemCount;
  
  bool get hasCart => _items.isNotEmpty;
  
  double get totalAmount => _items.fold(
    0.0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  bool get isEmpty => _items.isEmpty;

  int getItemQuantity(int menuItemId) {
    try {
      final item = _items.firstWhere((item) => item.menuItemId == menuItemId);
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  Future<void> loadCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('CartProvider: Loading cart...');
      _items = await _cartService.getCartItems();
      _error = null;
      print('CartProvider: Cart loaded with ${_items.length} items');
    } catch (e) {
      _error = e.toString();
      print('CartProvider: Failed to load cart - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem({
    required int menuItemId,
    required String itemName,
    required double price,
    int quantity = 1,
    String? specialInstructions,
    String? imageUrl,
    int? restaurantId,
    String? restaurantName,
  }) async {
    try {
      print('CartProvider: Adding $itemName to cart');
      
      await _cartService.addToCart(
        menuItemId: menuItemId,
        itemName: itemName,
        price: price,
        quantity: quantity,
        specialInstructions: specialInstructions,
        imageUrl: imageUrl,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      );
      
      await loadCart();
      print('CartProvider: Item added successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      print('CartProvider: Failed to add item - $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(cartItemId);
      return;
    }

    try {
      print('CartProvider: Updating quantity to $newQuantity');
      
      await _cartService.updateQuantity(cartItemId, newQuantity);
      await loadCart();
      
      print('CartProvider: Quantity updated');
    } catch (e) {
      _error = e.toString();
      print('CartProvider: Failed to update quantity - $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> incrementQuantity(int cartItemId) async {
    final item = _items.firstWhere((item) => item.id == cartItemId);
    await updateQuantity(cartItemId, item.quantity + 1);
  }

  Future<void> decrementQuantity(int cartItemId) async {
    final item = _items.firstWhere((item) => item.id == cartItemId);
    if (item.quantity > 1) {
      await updateQuantity(cartItemId, item.quantity - 1);
    } else {
      await removeItem(cartItemId);
    }
  }

  Future<void> increaseQuantity(int menuItemId) async {
    try {
      final item = _items.firstWhere((item) => item.menuItemId == menuItemId);
      await incrementQuantity(item.id);
    } catch (e) {
      print('Item not found in cart');
    }
  }

  Future<void> decreaseQuantity(int menuItemId) async {
    try {
      final item = _items.firstWhere((item) => item.menuItemId == menuItemId);
      await decrementQuantity(item.id);
    } catch (e) {
      print('Item not found in cart');
    }
  }

  Future<void> removeItem(int cartItemId) async {
    try {
      print('CartProvider: Removing item $cartItemId');
      
      await _cartService.removeFromCart(cartItemId);
      await loadCart();
      
      print('CartProvider: Item removed');
    } catch (e) {
      _error = e.toString();
      print('CartProvider: Failed to remove item - $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      print('CartProvider: Clearing cart...');
      
      await _cartService.clearCart();
      _items = [];
      
      print('CartProvider: Cart cleared');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('CartProvider: Failed to clear cart - $e');
      notifyListeners();
      rethrow;
    }
  }
}
