import 'package:flutter/foundation.dart';

class Order {
  final String id;
  final String? userId;
  final double? totalAmount;
  final String status;
  final dynamic items;
  final DateTime? createdAt;
  final String? deliveryAddress;
  final String? deliveryZoneId;
  final double? deliveryFee;
  final String? deliveryNotes;
  final String? deliveryPersonId;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final String? qrCode;
  final DateTime? updatedAt;

  Order({
    required this.id,
    this.userId,
    this.totalAmount,
    required this.status,
    this.items,
    this.createdAt,
    this.deliveryAddress,
    this.deliveryZoneId,
    this.deliveryFee,
    this.deliveryNotes,
    this.deliveryPersonId,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.qrCode,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      totalAmount: json['total_amount'] != null 
          ? (json['total_amount'] as num).toDouble() 
          : null,
      status: json['status'] as String? ?? 'pending',
      items: json['items'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryZoneId: json['delivery_zone_id'] as String?,
      deliveryFee: json['delivery_fee'] != null 
          ? (json['delivery_fee'] as num).toDouble() 
          : null,
      deliveryNotes: json['delivery_notes'] as String?,
      deliveryPersonId: json['delivery_person_id'] as String?,
      estimatedDeliveryTime: json['estimated_delivery_time'] != null 
          ? DateTime.parse(json['estimated_delivery_time'] as String) 
          : null,
      actualDeliveryTime: json['actual_delivery_time'] != null 
          ? DateTime.parse(json['actual_delivery_time'] as String) 
          : null,
      qrCode: json['qr_code'] as String?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'status': status,
      'items': items,
      'created_at': createdAt?.toIso8601String(),
      'delivery_address': deliveryAddress,
      'delivery_zone_id': deliveryZoneId,
      'delivery_fee': deliveryFee,
      'delivery_notes': deliveryNotes,
      'delivery_person_id': deliveryPersonId,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
      'qr_code': qrCode,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    double? totalAmount,
    String? status,
    dynamic items,
    DateTime? createdAt,
    String? deliveryAddress,
    String? deliveryZoneId,
    double? deliveryFee,
    String? deliveryNotes,
    String? deliveryPersonId,
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    String? qrCode,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryZoneId: deliveryZoneId ?? this.deliveryZoneId,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      qrCode: qrCode ?? this.qrCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isDelivered => status == 'delivered';
  bool get isInTransit => status == 'out_for_delivery';
  bool get isCancelled => status == 'cancelled';
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReadyForPickup => status == 'ready_for_pickup';

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'En préparation';
      case 'ready_for_pickup': return 'Prête pour livraison';
      case 'out_for_delivery': return 'En cours de livraison';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return 'Inconnu';
    }
  }

  @override
  String toString() {
    return 'Order(id: $id, status: $status, totalAmount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Order &&
      other.id == id &&
      other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      status.hashCode;
  }
}