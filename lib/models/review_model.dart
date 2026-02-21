class ReviewModel {
  final int id;
  final int userId;
  final String userName;
  final int restaurantId;
  final String restaurantName;
  final int? orderId;
  final int? menuItemId;
  final String? menuItemName;
  final double rating;
  final String? comment;
  final String? restaurantReply;
  final int helpfulCount;
  final int reportCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.restaurantId,
    required this.restaurantName,
    this.orderId,
    this.menuItemId,
    this.menuItemName,
    required this.rating,
    this.comment,
    this.restaurantReply,
    required this.helpfulCount,
    required this.reportCount,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'] ?? 'Anonymous',
      restaurantId: json['restaurantId'],
      restaurantName: json['restaurantName'] ?? '',
      orderId: json['orderId'],
      menuItemId: json['menuItemId'],
      menuItemName: json['menuItemName'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'],
      restaurantReply: json['restaurantReply'],
      helpfulCount: json['helpfulCount'] ?? 0,
      reportCount: json['reportCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
}

class CreateReviewRequest {
  final int userId;
  final String userName;
  final int restaurantId;
  final String restaurantName;
  final int? orderId;
  final int? menuItemId;
  final String? menuItemName;
  final double rating;
  final String? comment;

  CreateReviewRequest({
    required this.userId,
    required this.userName,
    required this.restaurantId,
    required this.restaurantName,
    this.orderId,
    this.menuItemId,
    this.menuItemName,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'orderId': orderId,
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'rating': rating,
      'comment': comment,
    };
  }
}

class RatingStatsModel {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  RatingStatsModel({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory RatingStatsModel.fromJson(Map<String, dynamic> json) {
    return RatingStatsModel(
      averageRating: (json['averageRating'] as num).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(json['ratingDistribution'] ?? {}),
    );
  }
}
