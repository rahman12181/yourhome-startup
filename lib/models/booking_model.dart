class BookingRequest {
  final int requestId;
  final int propertyId;
  final String propertyTitle;
  final String propertyCity;
  final String? coverImage;
  final int? roomId;
  final String? roomNumber;
  final DateTime moveInDate;
  final int? durationMonths;
  final String? message;
  final String status;
  final String? ownerResponse;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  BookingRequest({
    required this.requestId,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyCity,
    this.coverImage,
    this.roomId,
    this.roomNumber,
    required this.moveInDate,
    this.durationMonths,
    this.message,
    required this.status,
    this.ownerResponse,
    required this.requestedAt,
    this.respondedAt,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      requestId: json['requestId'] ?? 0,
      propertyId: json['propertyId'] ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      propertyCity: json['propertyCity'] ?? '',
      coverImage: json['coverImage'],
      roomId: json['roomId'],
      roomNumber: json['roomNumber'],
      moveInDate: DateTime.parse(json['moveInDate'] ?? DateTime.now().toIso8601String()),
      durationMonths: json['durationMonths'],
      message: json['message'],
      status: json['status'] ?? 'PENDING',
      ownerResponse: json['ownerResponse'],
      requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt']) 
          : null,
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