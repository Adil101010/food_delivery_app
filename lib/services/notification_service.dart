// lib/services/notification_service.dart

import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'token_manager.dart';

class NotificationService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.connectTimeout,
  ));

  NotificationService() {
    print(' NotificationService initialized');
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenManager.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print(' NOTIFICATION REQUEST[${options.method}] => ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print(' NOTIFICATION RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print(' NOTIFICATION ERROR[${error.response?.statusCode}] => ${error.requestOptions.path}');
        print('   Error: ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

  /// Get user notifications
  Future<List<NotificationModel>> getUserNotifications() async {
    try {
      final userId = await TokenManager.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      print(' Fetching notifications for user: $userId');

      final response = await _dio.get('/api/notifications/user/$userId');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        final notifications = data
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        
        print(' Fetched ${notifications.length} notifications');
        return notifications;
      }

      return [];
    } on DioException catch (e) {
      print(' Failed to fetch notifications: ${e.message}');
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception('Failed to fetch notifications');
    }
  }

  /// Get notification by ID
  Future<NotificationModel?> getNotificationById(int notificationId) async {
    try {
      print(' Fetching notification: $notificationId');

      final response = await _dio.get('/api/notifications/$notificationId');

      if (response.statusCode == 200 && response.data != null) {
        return NotificationModel.fromJson(response.data);
      }

      return null;
    } on DioException catch (e) {
      print(' Failed to fetch notification: ${e.message}');
      return null;
    }
  }

  /// Get order notifications
  Future<List<NotificationModel>> getOrderNotifications(int orderId) async {
    try {
      print(' Fetching notifications for order: $orderId');

      final response = await _dio.get('/api/notifications/order/$orderId');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print(' Failed to fetch order notifications: ${e.message}');
      return [];
    }
  }

  /// Send notification (admin only)
  Future<NotificationModel?> sendNotification(
    SendNotificationRequest request,
  ) async {
    try {
      print(' Sending notification to user: ${request.userId}');

      final response = await _dio.post(
        '/api/notifications/send',
        data: request.toJson(),
      );

      if (response.statusCode == 201 && response.data != null) {
        print(' Notification sent successfully');
        return NotificationModel.fromJson(response.data);
      }

      return null;
    } on DioException catch (e) {
      print(' Failed to send notification: ${e.message}');
      throw Exception('Failed to send notification');
    }
  }

  /// Mark notification as read (for future use)
  Future<bool> markAsRead(int notificationId) async {
    try {
      print(' Marking notification as read: $notificationId');

      final response = await _dio.put(
        '/api/notifications/$notificationId/read',
      );

      if (response.statusCode == 200) {
        print(' Notification marked as read');
        return true;
      }

      return false;
    } on DioException catch (e) {
      print(' Failed to mark notification as read: ${e.message}');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      print(' Deleting notification: $notificationId');

      final response = await _dio.delete(
        '/api/notifications/$notificationId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print(' Notification deleted');
        return true;
      }

      return false;
    } on DioException catch (e) {
      print(' Failed to delete notification: ${e.message}');
      return false;
    }
  }
}
