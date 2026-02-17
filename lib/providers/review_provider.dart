// lib/providers/review_provider.dart

import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  
  List<ReviewModel> _reviews = [];
  RatingStatsModel? _restaurantStats;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ReviewModel> get reviews => _reviews;
  RatingStatsModel? get restaurantStats => _restaurantStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasReviews => _reviews.isNotEmpty;
  
  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold(0.0, (sum, review) => sum + review.rating);
    return total / _reviews.length;
  }

  /// Create review - ✅ UPDATED WITH orderId and type
  Future<ReviewModel?> createReview({
    required int restaurantId,
    required int orderId,        // ✅ REQUIRED
    required String type,         // ✅ REQUIRED (RESTAURANT, MENU_ITEM, DELIVERY)
    required double rating,
    String? comment,
    int? menuItemId,
  }) async {
    try {
      print('ReviewProvider: Creating review...');
      print('   Restaurant: $restaurantId');
      print('   Order: $orderId');
      print('   Type: $type');
      print('   Rating: $rating');
      
      final review = await _reviewService.createReview(
        restaurantId: restaurantId,
        orderId: orderId,          // ✅ PASS IT
        type: type,                // ✅ PASS IT
        rating: rating,
        comment: comment,
        menuItemId: menuItemId,
      );
      
      if (review != null) {
        _reviews.insert(0, review); // Add to beginning
        notifyListeners();
        print('ReviewProvider: Review created successfully');
        print('   Review ID: ${review.id}');
      }
      
      return review;
    } catch (e) {
      _error = e.toString();
      print('ReviewProvider: Error creating review - $e');
      notifyListeners();
      rethrow;  // ✅ Rethrow to show error in UI
    }
  }

  /// Load restaurant reviews
  Future<void> loadRestaurantReviews(int restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('ReviewProvider: Loading reviews for restaurant $restaurantId');
      
      _reviews = await _reviewService.getRestaurantReviews(restaurantId);
      
      // Sort by date (newest first)
      _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('ReviewProvider: Loaded ${_reviews.length} reviews');
      print('ReviewProvider: Average rating: ${averageRating.toStringAsFixed(1)}');
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('ReviewProvider: Error loading reviews - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user reviews
  Future<void> loadUserReviews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('ReviewProvider: Loading user reviews');
      
      _reviews = await _reviewService.getUserReviews();
      
      _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('ReviewProvider: Loaded ${_reviews.length} user reviews');
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('ReviewProvider: Error loading user reviews - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get review by order ID
  Future<ReviewModel?> getReviewByOrderId(int orderId) async {
    try {
      print('ReviewProvider: Fetching review for order $orderId');
      
      return await _reviewService.getReviewByOrderId(orderId);
    } catch (e) {
      print('ReviewProvider: Error fetching order review - $e');
      return null;
    }
  }

  /// Load menu item reviews
  Future<void> loadMenuItemReviews(int menuItemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('ReviewProvider: Loading reviews for menu item $menuItemId');
      
      _reviews = await _reviewService.getMenuItemReviews(menuItemId);
      
      _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('ReviewProvider: Loaded ${_reviews.length} menu item reviews');
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('ReviewProvider: Error loading menu item reviews - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load restaurant stats
  Future<void> loadRestaurantStats(int restaurantId) async {
    try {
      print('ReviewProvider: Loading stats for restaurant $restaurantId');
      
      _restaurantStats = await _reviewService.getRestaurantStats(restaurantId);
      
      if (_restaurantStats != null) {
        print('ReviewProvider: Stats loaded');
        print('   Average: ${_restaurantStats!.averageRating.toStringAsFixed(1)}');
        print('   Total Reviews: ${_restaurantStats!.totalReviews}');
        notifyListeners();
      }
    } catch (e) {
      print('ReviewProvider: Error loading restaurant stats - $e');
    }
  }

  /// Mark review as helpful
  Future<bool> markHelpful(int reviewId) async {
    try {
      print('ReviewProvider: Marking review $reviewId as helpful');
      
      final updatedReview = await _reviewService.markHelpful(reviewId);
      
      if (updatedReview != null) {
        // Update local list
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          _reviews[index] = updatedReview;
          notifyListeners();
        }
        
        print('ReviewProvider: Review marked as helpful');
        return true;
      }
      
      return false;
    } catch (e) {
      print('ReviewProvider: Error marking as helpful - $e');
      return false;
    }
  }

  /// Report review
  Future<bool> reportReview(int reviewId) async {
    try {
      print('ReviewProvider: Reporting review $reviewId');
      
      final updatedReview = await _reviewService.reportReview(reviewId);
      
      if (updatedReview != null) {
        print('ReviewProvider: Review reported');
        return true;
      }
      
      return false;
    } catch (e) {
      print('ReviewProvider: Error reporting review - $e');
      return false;
    }
  }

  /// Get reviews by rating
  List<ReviewModel> getByRating(int rating) {
    return _reviews.where((r) => r.rating.round() == rating).toList();
  }

  /// Get reviews with comments
  List<ReviewModel> get reviewsWithComments {
    return _reviews.where((r) => r.comment != null && r.comment!.isNotEmpty).toList();
  }

  /// Refresh reviews
  Future<void> refresh(int restaurantId) async {
    await loadRestaurantReviews(restaurantId);
    await loadRestaurantStats(restaurantId);
  }

  /// Clear reviews
  void clearReviews() {
    _reviews.clear();
    _restaurantStats = null;
    _error = null;
    notifyListeners();
  }

  /// Print summary
  void printSummary() {
    print('═══════════════════════════════════');
    print('REVIEW SUMMARY');
    print('═══════════════════════════════════');
    print('Total Reviews: ${_reviews.length}');
    print('Average Rating: ${averageRating.toStringAsFixed(1)} ⭐');
    print('5 Stars: ${getByRating(5).length}');
    print('4 Stars: ${getByRating(4).length}');
    print('3 Stars: ${getByRating(3).length}');
    print('2 Stars: ${getByRating(2).length}');
    print('1 Star: ${getByRating(1).length}');
    if (reviewsWithComments.isNotEmpty) {
      print('With Comments: ${reviewsWithComments.length}');
    }
    print('═══════════════════════════════════');
  }

  /// Check if user can review (has completed order)
  Future<bool> canUserReview(int orderId) async {
    try {
      final existingReview = await getReviewByOrderId(orderId);
      return existingReview == null; // Can review if no review exists
    } catch (e) {
      print('ReviewProvider: Error checking review eligibility - $e');
      return false;
    }
  }

  /// Get statistics for display
  Map<String, dynamic> getStatistics() {
    return {
      'total': _reviews.length,
      'average': averageRating,
      'fiveStar': getByRating(5).length,
      'fourStar': getByRating(4).length,
      'threeStar': getByRating(3).length,
      'twoStar': getByRating(2).length,
      'oneStar': getByRating(1).length,
      'withComments': reviewsWithComments.length,
    };
  }
}
