import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

 
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasNotifications => _notifications.isNotEmpty;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  List<NotificationModel> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  
  List<NotificationModel> get readNotifications => 
      _notifications.where((n) => n.isRead).toList();

  /// Load user notifications
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('NotificationProvider: Loading notifications...');
      
      _notifications = await _notificationService.getUserNotifications();
      
      // Sort by date 
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('NotificationProvider: Loaded ${_notifications.length} notifications');
      print('NotificationProvider: Unread count: $unreadCount');
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('NotificationProvider: Error loading notifications - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get notification by ID
  Future<NotificationModel?> getNotificationById(int notificationId) async {
    try {
      print('NotificationProvider: Fetching notification $notificationId');
      
      final notification = await _notificationService.getNotificationById(notificationId);
      
      if (notification != null) {
        // Update local list
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = notification;
          notifyListeners();
        }
      }
      
      return notification;
    } catch (e) {
      print('NotificationProvider: Error fetching notification - $e');
      return null;
    }
  }

  /// Get order notifications
  Future<List<NotificationModel>> getOrderNotifications(int orderId) async {
    try {
      print('NotificationProvider: Fetching notifications for order $orderId');
      
      return await _notificationService.getOrderNotifications(orderId);
    } catch (e) {
      print('NotificationProvider: Error fetching order notifications - $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      print('NotificationProvider: Marking notification $notificationId as read');
      
      final success = await _notificationService.markAsRead(notificationId);
      
      if (success) {
        // Update local list
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: _notifications[index].id,
            userId: _notifications[index].userId,
            title: _notifications[index].title,
            message: _notifications[index].message,
            type: _notifications[index].type,
            orderId: _notifications[index].orderId,
            restaurantId: _notifications[index].restaurantId,
            isRead: true,
            createdAt: _notifications[index].createdAt,
          );
          notifyListeners();
        }
        
        print('NotificationProvider: Notification marked as read');
      }
      
      return success;
    } catch (e) {
      print('NotificationProvider: Error marking as read - $e');
      return false;
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      print('NotificationProvider: Marking all notifications as read');
      
      final unread = unreadNotifications;
      
      for (var notification in unread) {
        await markAsRead(notification.id);
      }
      
      print('NotificationProvider: All notifications marked as read');
    } catch (e) {
      print('NotificationProvider: Error marking all as read - $e');
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      print('NotificationProvider: Deleting notification $notificationId');
      
      final success = await _notificationService.deleteNotification(notificationId);
      
      if (success) {
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
        print('NotificationProvider: Notification deleted');
      }
      
      return success;
    } catch (e) {
      print('NotificationProvider: Error deleting notification - $e');
      return false;
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      print('NotificationProvider: Clearing all notifications');
      
      for (var notification in _notifications) {
        await _notificationService.deleteNotification(notification.id);
      }
      
      _notifications.clear();
      notifyListeners();
      
      print('NotificationProvider: All notifications cleared');
    } catch (e) {
      print('NotificationProvider: Error clearing notifications - $e');
    }
  }

  /// Get notifications by type
  List<NotificationModel> getByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Print summary
  void printSummary() {
    print('═══════════════════════════════════');
    print('NOTIFICATION SUMMARY');
    print('═══════════════════════════════════');
    print('Total: ${_notifications.length}');
    print('Unread: $unreadCount');
    print('Read: ${_notifications.length - unreadCount}');
    print('═══════════════════════════════════');
  }
}
