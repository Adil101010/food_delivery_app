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
  
  bool get isEmpty => _items.isEmpty;

  // ✅ ADDED: Subtotal calculation
  double get subtotal => _items.fold(
    0.0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  // ✅ ADDED: Delivery fee (can be dynamic based on restaurant)
  double get deliveryFee {
    if (_items.isEmpty) return 0.0;
    if (subtotal >= 199) return 0.0; // Free delivery above ₹199
    return 40.0; // Default delivery fee
  }

  // ✅ ADDED: Tax calculation (5% GST)
  double get tax {
    return subtotal * 0.05;
  }

  // ✅ ADDED: Discount (can be from coupon code)
  double get discount => 0.0; // Add coupon logic later

  // ✅ UPDATED: Total amount with all calculations
  double get total {
    return subtotal + deliveryFee + tax - discount;
  }

  // ✅ LEGACY: Keep old totalAmount for backward compatibility
  double get totalAmount => total;

  // ✅ ADDED: Get restaurant info from cart
  String? get restaurantName {
    if (_items.isEmpty) return null;
    return _items.first.restaurantName;
  }

  int? get restaurantId {
    if (_items.isEmpty) return null;
    return _items.first.restaurantId;
  }

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
      print('CartProvider: Subtotal: ₹${subtotal.toStringAsFixed(2)}');
      print('CartProvider: Total: ₹${total.toStringAsFixed(2)}');
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
      
      // Check if cart has items from different restaurant
      if (_items.isNotEmpty && restaurantId != null) {
        final existingRestaurantId = _items.first.restaurantId;
        if (existingRestaurantId != null && existingRestaurantId != restaurantId) {
          _error = 'Cannot add items from different restaurants';
          notifyListeners();
          return false;
        }
      }
      
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

  // ✅ ADDED: Apply coupon code (for future use)
  Future<bool> applyCoupon(String couponCode) async {
    // TODO: Implement coupon logic with backend
    print('CartProvider: Applying coupon $couponCode');
    notifyListeners();
    return false;
  }

  // ✅ ADDED: Get cart summary
  Map<String, dynamic> getCartSummary() {
    return {
      'items': _items.length,
      'totalItems': totalItems,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'discount': discount,
      'total': total,
      'restaurantName': restaurantName,
      'restaurantId': restaurantId,
    };
  }

  // ✅ ADDED: Print cart summary for debugging
  void printSummary() {
    print('═══════════════════════════════════');
    print('CART SUMMARY');
    print('═══════════════════════════════════');
    print('Restaurant: $restaurantName');
    print('Items: ${_items.length}');
    print('Total Items: $totalItems');
    print('Subtotal: ₹${subtotal.toStringAsFixed(2)}');
    print('Delivery Fee: ₹${deliveryFee.toStringAsFixed(2)}');
    print('Tax (5%): ₹${tax.toStringAsFixed(2)}');
    print('Discount: ₹${discount.toStringAsFixed(2)}');
    print('Total: ₹${total.toStringAsFixed(2)}');
    print('═══════════════════════════════════');
  }
}
