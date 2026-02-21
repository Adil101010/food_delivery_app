import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/cart_item_model.dart';
import 'token_manager.dart';

class CartService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.connectTimeout,
  ));

  CartService() {
    print(' CartService initialized');
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenManager.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print(' CART REQUEST[${options.method}] => ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print(' CART RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print(' CART ERROR[${error.response?.statusCode}] => ${error.requestOptions.path}');
        print('   Error: ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

  /// Get complete cart data including restaurant info
  Future<Map<String, dynamic>?> getCart() async {
    try {
      final userId = await TokenManager.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print(' Fetching cart for user: $userId');

      final response = await _dio.get('/api/cart/user/$userId');
      
      print(' Cart response status: ${response.statusCode}');
      print(' Cart response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final cartData = response.data as Map<String, dynamic>;
          print('  Cart data fetched successfully');
          print('   Cart ID: ${cartData['id']}');
          print('   Restaurant ID: ${cartData['restaurantId']}');
          print('   Restaurant Name: ${cartData['restaurantName']}');
          print('   Items: ${(cartData['items'] as List?)?.length ?? 0}');
          return cartData;
        }
      }

      print(' Empty cart or invalid response');
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        print(' Cart not found (empty cart)');
        return null;
      }
      print(' Error fetching cart: ${e.message}');
      print('   Response: ${e.response?.data}');
      return null;
    } catch (e) {
      print(' Unexpected error fetching cart: $e');
      return null;
    }
  }

  /// Get cart items only (for backward compatibility)
  Future<List<CartItem>> getCartItems() async {
    try {
      print(' Fetching cart items...');
      
      final cartData = await getCart();
      
      if (cartData != null && cartData['items'] != null) {
        final itemsList = cartData['items'] as List<dynamic>;
        final items = itemsList.map((item) => CartItem.fromJson(item)).toList();
        print(' Cart items fetched: ${items.length}');
        return items;
      }
      
      print(' No cart items found');
      return [];
    } catch (e) {
      print(' Failed to fetch cart items: $e');
      throw Exception('Failed to fetch cart items');
    }
  }

  Future<void> addToCart({
    required int menuItemId,
    required String itemName,
    required double price,
    required int quantity,
    String? specialInstructions,
    String? imageUrl,
    int? restaurantId,
    String? restaurantName,
  }) async {
    try {
      print(' Adding to cart: $itemName x$quantity');
      
      final userId = await TokenManager.getUserId();
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final data = {
        'userId': userId,
        'menuItemId': menuItemId,
        'itemName': itemName,
        'price': price,
        'quantity': quantity,
      };

      if (restaurantId != null) {
        data['restaurantId'] = restaurantId;
      }

      if (restaurantName != null) {
        data['restaurantName'] = restaurantName;
      }

      if (specialInstructions != null) {
        data['specialInstructions'] = specialInstructions;
      }

      if (imageUrl != null) {
        data['imageUrl'] = imageUrl;
      }

      print(' Cart data: $data');

      final response = await _dio.post(
        '/api/cart/add',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(' Item added to cart');
      }
    } on DioException catch (e) {
      print(' Failed to add to cart: ${e.response?.data ?? e.message}');
      throw Exception('Failed to add item to cart');
    }
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    try {
      print(' Updating cart item $cartItemId to qty: $quantity');
      
      final userId = await TokenManager.getUserId();
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      await _dio.put(
        '/api/cart/user/$userId/item/$cartItemId',
        data: {'quantity': quantity},
      );
      
      print(' Cart item quantity updated');
    } on DioException catch (e) {
      print(' Failed to update cart: ${e.message}');
      throw Exception('Failed to update quantity');
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    try {
      print(' Removing cart item: $cartItemId');
      
      final userId = await TokenManager.getUserId();
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      await _dio.delete('/api/cart/user/$userId/item/$cartItemId');
      
      print(' Item removed from cart');
    } on DioException catch (e) {
      print(' Failed to remove from cart: ${e.message}');
      throw Exception('Failed to remove item');
    }
  }

  Future<void> clearCart() async {
    try {
      print(' Clearing entire cart...');
      
      final userId = await TokenManager.getUserId();
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      await _dio.delete('/api/cart/user/$userId');
      
      print(' Cart cleared');
    } on DioException catch (e) {
      print(' Failed to clear cart: ${e.message}');
      throw Exception('Failed to clear cart');
    }
  }

  Future<double> getCartTotal() async {
    try {
      final cartData = await getCart();
      
      if (cartData != null) {
        final total = (cartData['total'] as num?)?.toDouble() ?? 
                     (cartData['totalAmount'] as num?)?.toDouble() ?? 
                     0.0;
        print(' Cart total: ₹$total');
        return total;
      }
      
      return 0.0;
    } catch (e) {
      print(' Failed to get cart total: $e');
      return 0.0;
    }
  }

  /// Get restaurant info from cart
  Future<Map<String, dynamic>?> getRestaurantInfo() async {
    try {
      final cartData = await getCart();
      
      if (cartData != null) {
        return {
          'restaurantId': cartData['restaurantId'],
          'restaurantName': cartData['restaurantName'],
        };
      }
      
      return null;
    } catch (e) {
      print('❌ Failed to get restaurant info: $e');
      return null;
    }
  }

  /// Get cart summary
  Future<Map<String, dynamic>?> getCartSummary() async {
    try {
      final cartData = await getCart();
      
      if (cartData != null) {
        return {
          'id': cartData['id'],
          'restaurantId': cartData['restaurantId'],
          'restaurantName': cartData['restaurantName'],
          'itemCount': cartData['itemCount'] ?? 0,
          'subtotal': (cartData['subtotal'] as num?)?.toDouble() ?? 0.0,
          'discount': (cartData['discount'] as num?)?.toDouble() ?? 0.0,
          'total': (cartData['total'] as num?)?.toDouble() ?? 0.0,
        };
      }
      
      return null;
    } catch (e) {
      print('❌ Failed to get cart summary: $e');
      return null;
    }
  }
}
