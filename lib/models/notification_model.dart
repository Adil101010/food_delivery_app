// lib/models/notification_model.dart

class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final int? orderId;
  final int? restaurantId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.orderId,
    this.restaurantId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'INFO',
      orderId: json['orderId'],
      restaurantId: json['restaurantId'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'orderId': orderId,
      'restaurantId': restaurantId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SendNotificationRequest {
  final int userId;
  final String title;
  final String message;
  final String type;
  final int? orderId;
  final int? restaurantId;

  SendNotificationRequest({
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.orderId,
    this.restaurantId,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'orderId': orderId,
      'restaurantId': restaurantId,
    };
  }
}
