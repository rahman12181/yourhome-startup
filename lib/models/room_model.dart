import 'package:flutter/material.dart';

class Room {
  final int roomId;
  final String? roomNumber;
  final String roomType;
  final int? floorNumber;
  final double monthlyRent;
  final int capacity;
  final int occupiedCount;
  final String status;
  final bool hasAc;
  final bool hasAttachedBathroom;
  final String? description;

  Room({
    required this.roomId,
    this.roomNumber,
    required this.roomType,
    this.floorNumber,
    required this.monthlyRent,
    required this.capacity,
    this.occupiedCount = 0,
    this.status = 'AVAILABLE',
    this.hasAc = false,
    this.hasAttachedBathroom = false,
    this.description,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['roomId'] ?? 0,
      roomNumber: json['roomNumber'],
      roomType: json['roomType'] ?? 'SINGLE',
      floorNumber: json['floorNumber'],
      monthlyRent: json['monthlyRent']?.toDouble() ?? 0.0,
      capacity: json['capacity'] ?? 1,
      occupiedCount: json['occupiedCount'] ?? 0,
      status: json['status'] ?? 'AVAILABLE',
      hasAc: json['hasAc'] ?? false,
      hasAttachedBathroom: json['hasAttachedBathroom'] ?? false,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'roomNumber': roomNumber,
    'roomType': roomType,
    'floorNumber': floorNumber,
    'monthlyRent': monthlyRent,
    'capacity': capacity,
    'occupiedCount': occupiedCount,
    'status': status,
    'hasAc': hasAc,
    'hasAttachedBathroom': hasAttachedBathroom,
    'description': description,
  };

  // ✅ Helper getters
  bool get isAvailable => status == 'AVAILABLE';
  bool get isOccupied => status == 'OCCUPIED';
  bool get isUnderMaintenance => status == 'MAINTENANCE';
  
  String get statusDisplay {
    switch (status) {
      case 'AVAILABLE':
        return 'Available ✅';
      case 'OCCUPIED':
        return 'Occupied';
      case 'MAINTENANCE':
        return 'Under Maintenance';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'OCCUPIED':
        return Colors.red;
      case 'MAINTENANCE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get roomTypeDisplay {
    switch (roomType) {
      case 'SINGLE':
        return 'Single Bed';
      case 'DOUBLE':
        return 'Double Bed';
      case 'TRIPLE':
        return 'Triple Bed';
      case 'DORMITORY':
        return 'Dormitory';
      default:
        return roomType;
    }
  }

  int get availableBeds => capacity - occupiedCount;
  bool get hasAvailableBeds => availableBeds > 0;
}