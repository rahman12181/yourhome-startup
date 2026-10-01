import 'package:flutter/material.dart';
import 'room_model.dart';

/// Single source for room-type labels / bed counts / colors (no hardcoding in screens).
class RoomTypeInfo {
  static const List<String> all = ['SINGLE', 'DOUBLE', 'TRIPLE', 'DORMITORY'];

  /// Fixed bed count for the type, or null when the owner chooses it (dormitory).
  static int? fixedBeds(String type) {
    switch (type) {
      case 'SINGLE':
        return 1;
      case 'DOUBLE':
        return 2;
      case 'TRIPLE':
        return 3;
      default:
        return null;
    }
  }

  static String label(String type) {
    switch (type) {
      case 'SINGLE':
        return 'Single';
      case 'DOUBLE':
        return 'Double';
      case 'TRIPLE':
        return 'Triple';
      case 'DORMITORY':
        return 'Dormitory';
      default:
        return type;
    }
  }

  static Color color(String type) {
    switch (type) {
      case 'SINGLE':
        return const Color(0xFF7C3AED);
      case 'DOUBLE':
        return const Color(0xFF3B82F6);
      case 'TRIPLE':
        return const Color(0xFF14B8A6);
      case 'DORMITORY':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8A8FA3);
    }
  }
}

class RoomBatchInput {
  final String roomType;
  final int count;
  final double monthlyRent;
  final int? floorNumber;
  final int? capacity; // only used for DORMITORY
  final bool hasAc;
  final bool hasAttachedBathroom;
  final String? description;
  final String? roomNumberPrefix;
  final int? startNumber;

  const RoomBatchInput({
    required this.roomType,
    required this.count,
    required this.monthlyRent,
    this.floorNumber,
    this.capacity,
    this.hasAc = false,
    this.hasAttachedBathroom = false,
    this.description,
    this.roomNumberPrefix,
    this.startNumber,
  });

  Map<String, dynamic> toJson() => {
        'roomType': roomType,
        'count': count,
        'monthlyRent': monthlyRent,
        if (floorNumber != null) 'floorNumber': floorNumber,
        if (capacity != null) 'capacity': capacity,
        'hasAc': hasAc,
        'hasAttachedBathroom': hasAttachedBathroom,
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        if (roomNumberPrefix != null && roomNumberPrefix!.trim().isNotEmpty)
          'roomNumberPrefix': roomNumberPrefix!.trim(),
        if (startNumber != null) 'startNumber': startNumber,
      };
}

class BulkPreviewRoom {
  final String roomNumber;
  final String roomType;
  final int? floorNumber;
  final int capacity;
  final double monthlyRent;

  const BulkPreviewRoom({
    required this.roomNumber,
    required this.roomType,
    this.floorNumber,
    required this.capacity,
    required this.monthlyRent,
  });

  factory BulkPreviewRoom.fromJson(Map<String, dynamic> j) => BulkPreviewRoom(
        roomNumber: (j['roomNumber'] ?? '').toString(),
        roomType: (j['roomType'] ?? 'SINGLE').toString(),
        floorNumber: j['floorNumber'] is num ? (j['floorNumber'] as num).toInt() : null,
        capacity: j['capacity'] is num ? (j['capacity'] as num).toInt() : 1,
        monthlyRent: j['monthlyRent'] is num ? (j['monthlyRent'] as num).toDouble() : 0,
      );
}

class BulkPreview {
  final int totalRooms;
  final int totalBeds;
  final bool canCreate;
  final List<String> conflicts;
  final Map<String, int> countsByType;
  final List<BulkPreviewRoom> rooms;

  const BulkPreview({
    required this.totalRooms,
    required this.totalBeds,
    required this.canCreate,
    this.conflicts = const [],
    this.countsByType = const {},
    this.rooms = const [],
  });

  factory BulkPreview.fromJson(Map<String, dynamic> j) {
    final counts = <String, int>{};
    (j['countsByType'] as Map?)?.forEach((k, v) {
      counts[k.toString()] = v is num ? v.toInt() : 0;
    });
    return BulkPreview(
      totalRooms: j['totalRooms'] is num ? (j['totalRooms'] as num).toInt() : 0,
      totalBeds: j['totalBeds'] is num ? (j['totalBeds'] as num).toInt() : 0,
      canCreate: j['canCreate'] == true,
      conflicts: ((j['conflicts'] as List?) ?? []).map((e) => e.toString()).toList(),
      countsByType: counts,
      rooms: ((j['rooms'] as List?) ?? [])
          .map((e) => BulkPreviewRoom.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class BulkCreateResult {
  final int createdRooms;
  final int totalBeds;
  final List<Room> rooms;

  const BulkCreateResult({
    required this.createdRooms,
    required this.totalBeds,
    this.rooms = const [],
  });

  factory BulkCreateResult.fromJson(Map<String, dynamic> j) => BulkCreateResult(
        createdRooms: j['createdRooms'] is num ? (j['createdRooms'] as num).toInt() : 0,
        totalBeds: j['totalBeds'] is num ? (j['totalBeds'] as num).toInt() : 0,
        rooms: ((j['rooms'] as List?) ?? [])
            .map((e) => Room.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}