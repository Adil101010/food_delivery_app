// lib/providers/cart_provider.dart

import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;
  
  // Cart-level data from backend
  int? _cartId;
  int? _restaurantId;
  String? _restaurantName;
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _total = 0.0;

  // Getters
  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get cartId => _cartId;
  int? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get totalItems => itemCount;
  bool get hasCart => _items.isNotEmpty;
  bool get isEmpty => _items.isEmpty;

  // Financial calculations
  double get subtotal => _subtotal > 0 ? _subtotal : _items.fold(
    0.0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  double get deliveryFee {
    if (_items.isEmpty) return 0.0;
    if (subtotal >= 199) return 0.0;
    return 0.0; // Free delivery for now
  }

  double get tax => subtotal * 0.05;
  double get discount => _discount;
  
  double get total {
    double calculatedTotal = subtotal + deliveryFee + tax - discount;
    return _total > 0 ? _total : calculatedTotal;
  }

  double get totalAmount => total;

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
      
      // Get cart data from service (includes cart-level info)
      final cartData = await _cartService.getCart();
      
      if (cartData != null && cartData['items'] != null) {
        // Extract cart-level data
        _cartId = cartData['id'];
        _restaurantId = cartData['restaurantId'];
        _restaurantName = cartData['restaurantName'];
        _subtotal = (cartData['subtotal'] ?? 0.0).toDouble();
        _discount = (cartData['discount'] ?? 0.0).toDouble();
        _total = (cartData['total'] ?? 0.0).toDouble();
        
        // Parse items
        final itemsList = cartData['items'] as List<dynamic>;
        _items = itemsList.map((item) => CartItem.fromJson(item)).toList();
        
        print('CartProvider: Cart loaded with ${_items.length} items');
        print('CartProvider: Restaurant: $_restaurantName (ID: $_restaurantId)');
        print('CartProvider: Subtotal: ₹${subtotal.toStringAsFixed(2)}');
        print('CartProvider: Total: ₹${total.toStringAsFixed(2)}');
      } else {
        // Empty cart
        _items = [];
        _cartId = null;
        _restaurantId = null;
        _restaurantName = null;
        _subtotal = 0.0;
        _discount = 0.0;
        _total = 0.0;
        print('CartProvider: Cart is empty');
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('CartProvider: Failed to load cart - $e');
      
      // Reset on error
      _items = [];
      _cartId = null;
      _restaurantId = null;
      _restaurantName = null;
      _subtotal = 0.0;
      _discount = 0.0;
      _total = 0.0;
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
      if (_items.isNotEmpty && restaurantId != null && _restaurantId != null) {
        if (_restaurantId != restaurantId) {
          _error = 'Cannot add items from different restaurants. Please clear your cart first.';
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
      
      // Reset all data
      _items = [];
      _cartId = null;
      _restaurantId = null;
      _restaurantName = null;
      _subtotal = 0.0;
      _discount = 0.0;
      _total = 0.0;
      _error = null;
      
      print('CartProvider: Cart cleared');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('CartProvider: Failed to clear cart - $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> applyCoupon(String couponCode) async {
    print('CartProvider: Applying coupon $couponCode');
    // TODO: Implement coupon logic with backend
    notifyListeners();
    return false;
  }

  Map<String, dynamic> getCartSummary() {
    return {
      'cartId': _cartId,
      'items': _items.length,
      'totalItems': totalItems,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'discount': discount,
      'total': total,
      'restaurantName': _restaurantName,
      'restaurantId': _restaurantId,
    };
  }

  void printSummary() {
    print('═══════════════════════════════════');
    print('CART SUMMARY');
    print('═══════════════════════════════════');
    print('Cart ID: $_cartId');
    print('Restaurant: $_restaurantName (ID: $_restaurantId)');
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
