import 'package:flutter/foundation.dart';

class DeliveryZone {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final double deliveryFee;
  final int? minDeliveryTime;
  final int? maxDeliveryTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryZone({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.deliveryFee,
    this.minDeliveryTime,
    this.maxDeliveryTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 2000.0,
      minDeliveryTime: json['min_delivery_time'] as int?,
      maxDeliveryTime: json['max_delivery_time'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'delivery_fee': deliveryFee,
      'min_delivery_time': minDeliveryTime,
      'max_delivery_time': maxDeliveryTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DeliveryZone copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    double? deliveryFee,
    int? minDeliveryTime,
    int? maxDeliveryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryZone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minDeliveryTime: minDeliveryTime ?? this.minDeliveryTime,
      maxDeliveryTime: maxDeliveryTime ?? this.maxDeliveryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getDeliveryTimeRange() {
    if (minDeliveryTime == null || maxDeliveryTime == null) {
      return 'Délai variable';
    }
    return '$minDeliveryTime-$maxDeliveryTime min';
  }

  @override
  String toString() {
    return 'DeliveryZone(id: $id, name: $name, isActive: $isActive, '
        'deliveryFee: $deliveryFee, timeRange: ${getDeliveryTimeRange()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is DeliveryZone &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.isActive == isActive &&
      other.deliveryFee == deliveryFee &&
      other.minDeliveryTime == minDeliveryTime &&
      other.maxDeliveryTime == maxDeliveryTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      isActive.hashCode ^
      deliveryFee.hashCode ^
      minDeliveryTime.hashCode ^
      maxDeliveryTime.hashCode;
  }
}