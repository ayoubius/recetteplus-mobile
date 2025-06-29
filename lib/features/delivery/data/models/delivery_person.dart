import 'package:flutter/foundation.dart';

class DeliveryPerson {
  final String id;
  final String userId;
  final bool isActive;
  final String? vehicleType;
  final String? licensePlate;
  final String currentStatus;
  final double rating;
  final int totalDeliveries;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryPerson({
    required this.id,
    required this.userId,
    required this.isActive,
    this.vehicleType,
    this.licensePlate,
    required this.currentStatus,
    required this.rating,
    required this.totalDeliveries,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryPerson.fromJson(Map<String, dynamic> json) {
    return DeliveryPerson(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      vehicleType: json['vehicle_type'] as String?,
      licensePlate: json['license_plate'] as String?,
      currentStatus: json['current_status'] as String? ?? 'available',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'is_active': isActive,
      'vehicle_type': vehicleType,
      'license_plate': licensePlate,
      'current_status': currentStatus,
      'rating': rating,
      'total_deliveries': totalDeliveries,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DeliveryPerson copyWith({
    String? id,
    String? userId,
    bool? isActive,
    String? vehicleType,
    String? licensePlate,
    String? currentStatus,
    double? rating,
    int? totalDeliveries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryPerson(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      vehicleType: vehicleType ?? this.vehicleType,
      licensePlate: licensePlate ?? this.licensePlate,
      currentStatus: currentStatus ?? this.currentStatus,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DeliveryPerson(id: $id, userId: $userId, isActive: $isActive, '
        'vehicleType: $vehicleType, licensePlate: $licensePlate, '
        'currentStatus: $currentStatus, rating: $rating, '
        'totalDeliveries: $totalDeliveries)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is DeliveryPerson &&
      other.id == id &&
      other.userId == userId &&
      other.isActive == isActive &&
      other.vehicleType == vehicleType &&
      other.licensePlate == licensePlate &&
      other.currentStatus == currentStatus &&
      other.rating == rating &&
      other.totalDeliveries == totalDeliveries;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      userId.hashCode ^
      isActive.hashCode ^
      vehicleType.hashCode ^
      licensePlate.hashCode ^
      currentStatus.hashCode ^
      rating.hashCode ^
      totalDeliveries.hashCode;
  }
}