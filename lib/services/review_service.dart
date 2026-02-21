import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/review_model.dart';
import 'token_manager.dart';

class ReviewService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.connectTimeout,
  ));

  ReviewService() {
    print(' ReviewService initialized');
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenManager.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print(' REVIEW REQUEST[${options.method}] => ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print(' REVIEW RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print(' REVIEW ERROR[${error.response?.statusCode}] => ${error.requestOptions.path}');
        print('   Error: ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

  /// Create review 
  Future<ReviewModel?> createReview({
    required int restaurantId,
    required int orderId,        
    required String type,         
    required double rating,
    String? comment,
    int? menuItemId,
  }) async {
    try {
      print('   Creating review for restaurant: $restaurantId');
      print('   Order ID: $orderId');
      print('   Type: $type');
      print('   Rating: $rating');

      final Map<String, dynamic> data = {
        'restaurantId': restaurantId,
        'orderId': orderId,      
        'type': type,            
        'rating': rating,
      };

      if (comment != null && comment.isNotEmpty) {
        data['comment'] = comment;
      }

      if (menuItemId != null) {
        data['menuItemId'] = menuItemId;
      }

      print(' Review payload: $data');

      final response = await _dio.post(
        '/api/reviews',
        data: data,
      );

      if (response.statusCode == 201 && response.data != null) {
        print(' Review created successfully');
        return ReviewModel.fromJson(response.data);
      }

      return null;
    } on DioException catch (e) {
      print(' Failed to create review: ${e.message}');
      if (e.response != null) {
        print('   Response data: ${e.response?.data}');
      }
      throw Exception('Failed to create review: ${e.message}');
    }
  }

  /// Get restaurant reviews
  Future<List<ReviewModel>> getRestaurantReviews(int restaurantId) async {
    try {
      print(' Fetching reviews for restaurant: $restaurantId');

      final response = await _dio.get('/api/reviews/restaurant/$restaurantId');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        final reviews = data.map((json) => ReviewModel.fromJson(json)).toList();
        
        print(' Fetched ${reviews.length} reviews');
        return reviews;
      }

      return [];
    } on DioException catch (e) {
      print(' Failed to fetch restaurant reviews: ${e.message}');
      return [];
    }
  }

  /// Get user reviews
  Future<List<ReviewModel>> getUserReviews() async {
    try {
      final userId = await TokenManager.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print(' Fetching reviews for user: $userId');

      final response = await _dio.get('/api/reviews/user/$userId');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => ReviewModel.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print(' Failed to fetch user reviews: ${e.message}');
      return [];
    }
  }

  /// Get review by order ID
  Future<ReviewModel?> getReviewByOrderId(int orderId) async {
    try {
      print(' Fetching review for order: $orderId');

      final response = await _dio.get('/api/reviews/order/$orderId');

      if (response.statusCode == 200 && response.data != null) {
        return ReviewModel.fromJson(response.data);
      }

      return null;
    } on DioException catch (e) {
      print(' Failed to fetch order review: ${e.message}');
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to fetch order review');
    }
  }

  /// Get menu item reviews
  Future<List<ReviewModel>> getMenuItemReviews(int menuItemId) async {
    try {
      print(' Fetching reviews for menu item: $menuItemId');

      final response = await _dio.get('/api/reviews/menu-item/$menuItemId');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => ReviewModel.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print(' Failed to fetch menu item reviews: ${e.message}');
      return [];
    }
  }

  /// Get restaurant stats
  Future<RatingStatsModel?> getRestaurantStats(int restaurantId) async {
    try {
      print(' Fetching stats for restaurant: $restaurantId');

      final response = await _dio.get(
        '/api/reviews/restaurant/$restaurantId/stats',
      );

      if (response.statusCode == 200 && response.data != null) {
        return RatingStatsModel.fromJson(response.data);
      }

      return null;
    } on DioException catch (e) {
      print(' Failed to fetch restaurant stats: ${e.message}');
      return null;
    }
  }

  /// Mark review as helpful
  Future<ReviewModel?> markHelpful(int reviewId) async {
    try {
      print(' Marking review as helpful: $reviewId');

      final response = await _dio.post('/api/reviews/$reviewId/helpful');

      if (response.statusCode == 200 && response.data != null) {
        print(' Review marked as helpful');
        return ReviewModel.fromJson(response.data);
      }

      return null;
    } on DioException catch (e) {
      print(' Failed to mark review as helpful: ${e.message}');
      return null;
    }
  }

  /// Report review
  Future<ReviewModel?> reportReview(int reviewId) async {
    try {
      print(' Reporting review: $reviewId');

      final response = await _dio.post('/api/reviews/$reviewId/report');

      if (response.statusCode == 200 && response.data != null) {
        print(' Review reported');
        return ReviewModel.fromJson(response.data);
      }

      return null;
    } on DioException catch (e) {
      print(' Failed to report review: ${e.message}');
      return null;
    }
  }

  /// Add restaurant reply
  Future<ReviewModel?> addRestaurantReply(int reviewId, String reply) async {
    try {
      print(' Adding restaurant reply to review: $reviewId');

      final response = await _dio.post(
        '/api/reviews/$reviewId/reply',
        queryParameters: {'reply': reply},
      );

      if (response.statusCode == 200 && response.data != null) {
        print(' Restaurant reply added');
        return ReviewModel.fromJson(response.data);
      }

      return null;
    } on DioException catch (e) {
      print(' Failed to add restaurant reply: ${e.message}');
      return null;
    }
  }
}
