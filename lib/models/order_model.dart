import 'package:flutter/material.dart';

class Order {
  final int id;
  final int userId;
  final int restaurantId;
  final String restaurantName;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final String? specialInstructions;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? estimatedDeliveryTime;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    this.specialInstructions,
    this.paymentMethod,
    required this.createdAt,
    this.updatedAt,
    this.estimatedDeliveryTime,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? json['orderId'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      restaurantId: json['restaurantId'] ?? json['restaurant_id'] ?? 0,
      restaurantName: json['restaurantName'] ?? json['restaurant_name'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? json['delivery_fee'] ?? 40.0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? json['orderStatus'] ?? 'PENDING',
      deliveryAddress: json['deliveryAddress'] ?? json['delivery_address'] ?? '',
      specialInstructions: json['specialInstructions'] ?? json['special_instructions'],
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : json['estimated_delivery_time'] != null
              ? DateTime.parse(json['estimated_delivery_time'])
              : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : [],
    );
  }

  // NEW: Formatted date getter
  String? get formattedCreatedAt {
    try {
      final now = DateTime.now();
      final diff = now.difference(createdAt);

      if (diff.inDays == 0) {
        final h = createdAt.hour > 12
            ? createdAt.hour - 12
            : (createdAt.hour == 0 ? 12 : createdAt.hour);
        final m = createdAt.minute.toString().padLeft(2, '0');
        final period = createdAt.hour >= 12 ? 'PM' : 'AM';
        return 'Today, $h:$m $period';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
      }
    } catch (e) {
      return null;
    }
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Order Placed';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Preparing';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PREPARING':
        return Colors.purple;
      case 'OUT_FOR_DELIVERY':
        return Colors.indigo;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool get canCancel {
    return status.toUpperCase() == 'PENDING' ||
        status.toUpperCase() == 'CONFIRMED';
  }
}

class OrderItem {
  final int id;
  final int menuItemId;
  final String itemName;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.menuItemId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] ?? 0).toDouble();
    final quantity = json['quantity'] ?? 1;

    return OrderItem(
      id: json['id'] ?? 0,
      menuItemId: json['menuItemId'] ?? json['menu_item_id'] ?? 0,
      itemName: json['itemName'] ?? json['item_name'] ?? json['name'] ?? '',
      quantity: quantity,
      price: price,
      totalPrice:
          (json['totalPrice'] ?? json['total_price'] ?? json['subtotal'] ?? (price * quantity))
              .toDouble(),
    );
  }
}
