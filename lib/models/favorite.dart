// lib/models/favorite.dart

class Favorite {
  final int? id;
  final int userId;
  final int restaurantId;
  final DateTime createdAt;

  Favorite({
    this.id,
    required this.userId,
    required this.restaurantId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      userId: json['userId'],
      restaurantId: json['restaurantId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
    };
  }
}
