import 'package:flutter/foundation.dart';

class OrderTracking {
  final String id;
  final String orderId;
  final String? deliveryPersonId;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? estimatedDeliveryTime;
  final DateTime lastUpdatedAt;

  OrderTracking({
    required this.id,
    required this.orderId,
    this.deliveryPersonId,
    this.currentLatitude,
    this.currentLongitude,
    this.estimatedDeliveryTime,
    required this.lastUpdatedAt,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      deliveryPersonId: json['delivery_person_id'] as String?,
      currentLatitude: json['current_latitude'] != null 
          ? (json['current_latitude'] as num).toDouble() 
          : null,
      currentLongitude: json['current_longitude'] != null 
          ? (json['current_longitude'] as num).toDouble() 
          : null,
      estimatedDeliveryTime: json['estimated_delivery_time'] != null 
          ? DateTime.parse(json['estimated_delivery_time'] as String) 
          : null,
      lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'delivery_person_id': deliveryPersonId,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'last_updated_at': lastUpdatedAt.toIso8601String(),
    };
  }

  OrderTracking copyWith({
    String? id,
    String? orderId,
    String? deliveryPersonId,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? estimatedDeliveryTime,
    DateTime? lastUpdatedAt,
  }) {
    return OrderTracking(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  String toString() {
    return 'OrderTracking(id: $id, orderId: $orderId, deliveryPersonId: $deliveryPersonId, '
        'currentLatitude: $currentLatitude, currentLongitude: $currentLongitude, '
        'estimatedDeliveryTime: $estimatedDeliveryTime, lastUpdatedAt: $lastUpdatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is OrderTracking &&
      other.id == id &&
      other.orderId == orderId &&
      other.deliveryPersonId == deliveryPersonId &&
      other.currentLatitude == currentLatitude &&
      other.currentLongitude == currentLongitude &&
      other.estimatedDeliveryTime == estimatedDeliveryTime &&
      other.lastUpdatedAt == lastUpdatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      orderId.hashCode ^
      deliveryPersonId.hashCode ^
      currentLatitude.hashCode ^
      currentLongitude.hashCode ^
      estimatedDeliveryTime.hashCode ^
      lastUpdatedAt.hashCode;
  }
}