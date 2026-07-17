class BookingRequest {
  final int requestId;
  final int propertyId;
  final String propertyTitle;
  final String propertyCity;
  final String? roomNumber;
  final DateTime moveInDate;
  final int? durationMonths;
  final String status;
  final String? message;
  final String? ownerResponse;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final bool isPaid; // ✅ NEW

  BookingRequest({
    required this.requestId,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyCity,
    this.roomNumber,
    required this.moveInDate,
    this.durationMonths,
    required this.status,
    this.message,
    this.ownerResponse,
    required this.requestedAt,
    this.respondedAt,
    this.isPaid = false, // ✅ NEW
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      requestId: json['requestId'] ?? 0,
      propertyId: json['propertyId'] ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      propertyCity: json['propertyCity'] ?? '',
      roomNumber: json['roomNumber'],
      moveInDate: json['moveInDate'] != null 
          ? DateTime.parse(json['moveInDate']) 
          : DateTime.now(),
      durationMonths: json['durationMonths'],
      status: json['status'] ?? 'PENDING',
      message: json['message'],
      ownerResponse: json['ownerResponse'],
      requestedAt: json['requestedAt'] != null 
          ? DateTime.parse(json['requestedAt']) 
          : DateTime.now(),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt']) 
          : null,
      isPaid: json['isPaid'] ?? false, // ✅ NEW
    );
  }
}

class CreateBookingRequest {
  final int propertyId;
  final int? roomId;
  final String moveInDate;
  final int? durationMonths;
  final String? message;

  CreateBookingRequest({
    required this.propertyId,
    this.roomId,
    required this.moveInDate,
    this.durationMonths,
    this.message,
  });

  Map<String, dynamic> toJson() => {
    'propertyId': propertyId,
    if (roomId != null) 'roomId': roomId,
    'moveInDate': moveInDate,
    if (durationMonths != null) 'durationMonths': durationMonths,
    if (message != null) 'message': message,
  };
}