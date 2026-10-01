// Owner-only. The backend returns this only to the owner of the property.

DateTime? _dt(dynamic v) {
  if (v is String && v.trim().isNotEmpty) {
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  return null;
}

double? _dbl(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int _int(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? fallback;
}

class BedSlot {
  final int bedNumber;

  /// OCCUPIED | HELD (accepted, awaiting payment) | EMPTY | UNAVAILABLE (maintenance)
  final String state;
  final String? occupantName;
  final int? occupantId;
  final int? bookingRequestId;

  const BedSlot({
    required this.bedNumber,
    required this.state,
    this.occupantName,
    this.occupantId,
    this.bookingRequestId,
  });

  factory BedSlot.fromJson(Map<String, dynamic> j) => BedSlot(
        bedNumber: _int(j['bedNumber']),
        state: (j['state'] ?? 'EMPTY').toString(),
        occupantName: j['occupantName']?.toString(),
        occupantId: j['occupantId'] == null ? null : _int(j['occupantId']),
        bookingRequestId:
            j['bookingRequestId'] == null ? null : _int(j['bookingRequestId']),
      );
}

class RoomOccupantInfo {
  final int occupantId;
  final int bookingRequestId;
  final int userId;
  final String name;
  final String? displayId;
  final String? phone;
  final String? email;
  final String? profilePic;
  final DateTime? movedInAt;
  final DateTime? vacatedAt;
  final DateTime? moveInDate;
  final int? durationMonths;
  final double? amountPaid;
  final DateTime? paidAt;
  final String? paymentStatus;

  const RoomOccupantInfo({
    required this.occupantId,
    required this.bookingRequestId,
    required this.userId,
    required this.name,
    this.displayId,
    this.phone,
    this.email,
    this.profilePic,
    this.movedInAt,
    this.vacatedAt,
    this.moveInDate,
    this.durationMonths,
    this.amountPaid,
    this.paidAt,
    this.paymentStatus,
  });

  factory RoomOccupantInfo.fromJson(Map<String, dynamic> j) => RoomOccupantInfo(
        occupantId: _int(j['occupantId']),
        bookingRequestId: _int(j['bookingRequestId']),
        userId: _int(j['userId']),
        name: (j['name'] ?? 'Unknown').toString(),
        displayId: j['displayId']?.toString(),
        phone: j['phone']?.toString(),
        email: j['email']?.toString(),
        profilePic: j['profilePic']?.toString(),
        movedInAt: _dt(j['movedInAt']),
        vacatedAt: _dt(j['vacatedAt']),
        moveInDate: _dt(j['moveInDate']),
        durationMonths:
            j['durationMonths'] == null ? null : _int(j['durationMonths']),
        amountPaid: _dbl(j['amountPaid']),
        paidAt: _dt(j['paidAt']),
        paymentStatus: j['paymentStatus']?.toString(),
      );
}

class RoomHoldInfo {
  final int bookingRequestId;
  final String studentName;
  final String? studentPhone;
  final DateTime? acceptedAt;
  final DateTime? holdExpiresAt;

  const RoomHoldInfo({
    required this.bookingRequestId,
    required this.studentName,
    this.studentPhone,
    this.acceptedAt,
    this.holdExpiresAt,
  });

  factory RoomHoldInfo.fromJson(Map<String, dynamic> j) => RoomHoldInfo(
        bookingRequestId: _int(j['bookingRequestId']),
        studentName: (j['studentName'] ?? 'Student').toString(),
        studentPhone: j['studentPhone']?.toString(),
        acceptedAt: _dt(j['acceptedAt']),
        holdExpiresAt: _dt(j['holdExpiresAt']),
      );
}

class RoomDetail {
  final int roomId;
  final int propertyId;
  final String propertyTitle;
  final String? roomNumber;
  final String roomType;
  final int? floorNumber;
  final double monthlyRent;
  final int capacity;
  final int occupiedCount;
  final int bedsLeft;
  final String status;
  final String availabilityLabel;
  final bool hasAc;
  final bool hasAttachedBathroom;
  final String? description;
  final List<BedSlot> beds;
  final List<RoomOccupantInfo> occupants;
  final List<RoomHoldInfo> pendingHolds;
  final List<RoomOccupantInfo> pastOccupants;

  const RoomDetail({
    required this.roomId,
    required this.propertyId,
    required this.propertyTitle,
    this.roomNumber,
    required this.roomType,
    this.floorNumber,
    required this.monthlyRent,
    required this.capacity,
    required this.occupiedCount,
    required this.bedsLeft,
    required this.status,
    required this.availabilityLabel,
    this.hasAc = false,
    this.hasAttachedBathroom = false,
    this.description,
    this.beds = const [],
    this.occupants = const [],
    this.pendingHolds = const [],
    this.pastOccupants = const [],
  });

  bool get isMaintenance => status == 'MAINTENANCE';
  bool get isFull => !isMaintenance && bedsLeft == 0;

  String get title => 'Room ${roomNumber ?? roomId}';

  factory RoomDetail.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        ((j[key] as List?) ?? [])
            .map((e) => parse(Map<String, dynamic>.from(e as Map)))
            .toList();

    return RoomDetail(
      roomId: _int(j['roomId']),
      propertyId: _int(j['propertyId']),
      propertyTitle: (j['propertyTitle'] ?? '').toString(),
      roomNumber: j['roomNumber']?.toString(),
      roomType: (j['roomType'] ?? 'SINGLE').toString(),
      floorNumber: j['floorNumber'] == null ? null : _int(j['floorNumber']),
      monthlyRent: _dbl(j['monthlyRent']) ?? 0,
      capacity: _int(j['capacity'], 1),
      occupiedCount: _int(j['occupiedCount']),
      bedsLeft: _int(j['bedsLeft']),
      status: (j['status'] ?? 'AVAILABLE').toString(),
      availabilityLabel: (j['availabilityLabel'] ?? '').toString(),
      hasAc: j['hasAc'] ?? false,
      hasAttachedBathroom: j['hasAttachedBathroom'] ?? false,
      description: j['description']?.toString(),
      beds: list('beds', BedSlot.fromJson),
      occupants: list('occupants', RoomOccupantInfo.fromJson),
      pendingHolds: list('pendingHolds', RoomHoldInfo.fromJson),
      pastOccupants: list('pastOccupants', RoomOccupantInfo.fromJson),
    );
  }
}