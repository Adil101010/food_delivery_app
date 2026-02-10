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

  final TokenManager _tokenManager = TokenManager();

  CartService() {
    print('CartService initialized');
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenManager.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('CART REQUEST[${options.method}] => ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('CART RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('CART ERROR[${error.response?.statusCode}] => ${error.requestOptions.path}');
        print('   Error: ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

  Future<List<CartItem>> getCartItems() async {
    try {
      print('Fetching cart items...');
      
      final userId = await TokenManager.getUserId();
      
      if (userId == null) {
        print('No userId found');
        return [];
      }
      
      print('Fetching cart for user: $userId');
      
      final response = await _dio.get('/api/cart/user/$userId');
      
      print('Cart response status: ${response.statusCode}');
      print('Cart response data: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          
          if (data['items'] != null && data['items'] is List) {
            final items = (data['items'] as List)
                .map((json) => CartItem.fromJson(json))
                .toList();
            
            print('Cart items fetched: ${items.length}');
            return items;
          }
        } else if (response.data is List) {
          final items = (response.data as List)
              .map((json) => CartItem.fromJson(json))
              .toList();
          
          print('Cart items fetched: ${items.length}');
          return items;
        }
      }
      
      return [];
    } on DioException catch (e) {
      print('Failed to fetch cart: ${e.message}');
      print('Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 404) {
        return [];
      }
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
      print('Adding to cart: $itemName x$quantity');
      
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

      print('Cart data: $data');

      final response = await _dio.post(
        '/api/cart/add',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Item added to cart');
      }
    } on DioException catch (e) {
      print('Failed to add to cart: ${e.response?.data ?? e.message}');
      throw Exception('Failed to add item to cart');
    }
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    try {
      print('Updating cart item $cartItemId to qty: $quantity');
      
      final userId = await TokenManager.getUserId();
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      await _dio.put(
        '/api/cart/user/$userId/item/$cartItemId',
        data: {'quantity': quantity},
      );
      
      print('Cart item quantity updated');
    } on DioException catch (e) {
      print('Failed to update cart: ${e.message}');
      throw Exception('Failed to update quantity');
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    try {
      print('Removing cart item: $cartItemId');
      
      final userId = await TokenManager.getUserId();
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      await _dio.delete('/api/cart/user/$userId/item/$cartItemId');
      
      print('Item removed from cart');
    } on DioException catch (e) {
      print('Failed to remove from cart: ${e.message}');
      throw Exception('Failed to remove item');
    }
  }

  Future<void> clearCart() async {
    try {
      print('Clearing entire cart...');
      
      final userId = await TokenManager.getUserId();
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      await _dio.delete('/api/cart/user/$userId');
      
      print('Cart cleared');
    } on DioException catch (e) {
      print('Failed to clear cart: ${e.message}');
      throw Exception('Failed to clear cart');
    }
  }

  Future<double> getCartTotal() async {
    try {
      final userId = await TokenManager.getUserId();
      
      if (userId == null) {
        return 0.0;
      }
      
      final response = await _dio.get('/api/cart/user/$userId');
      
      if (response.statusCode == 200 && response.data is Map) {
        return (response.data['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }
      
      return 0.0;
    } catch (e) {
      print('Failed to get cart total: $e');
      return 0.0;
    }
  }
}
