import 'package:flutter/foundation.dart';

class OrderStatusHistory {
  final String id;
  final String orderId;
  final String status;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  OrderStatusHistory({
    required this.id,
    required this.orderId,
    required this.status,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'status': status,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  OrderStatusHistory copyWith({
    String? id,
    String? orderId,
    String? status,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return OrderStatusHistory(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'OrderStatusHistory(id: $id, orderId: $orderId, status: $status, '
        'notes: $notes, createdBy: $createdBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is OrderStatusHistory &&
      other.id == id &&
      other.orderId == orderId &&
      other.status == status &&
      other.notes == notes &&
      other.createdBy == createdBy &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      orderId.hashCode ^
      status.hashCode ^
      notes.hashCode ^
      createdBy.hashCode ^
      createdAt.hashCode;
  }
}