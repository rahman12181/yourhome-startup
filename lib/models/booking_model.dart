class BookingRequest {
  final int requestId;
  final int propertyId;
  final String? propertyTitle;
  final String? propertyCity;
  final String? propertyState;
  final String? propertyAddress;
  final String? coverImage;
  final int? roomId;
  final String? roomNumber;
  final String? roomType;
  final double? monthlyRent;
  final DateTime? moveInDate;
  final int? durationMonths;
  final String? message;
  final String status;
  final String? ownerResponse;
  final DateTime? requestedAt;
  final DateTime? respondedAt;

  final int? studentId;
  final String? studentName;
  final String? studentDisplayId;
  final String? studentEmail;
  final String? studentPhone;
  final String? studentProfilePic;
  final DateTime? studentJoinedAt;
  final int? studentTotalBookings;
  final int? studentAcceptedBookings;
  final bool studentHasActiveBooking;
  final bool isRepeatStudent;

  final bool isPaid;
  final double? paidAmount;
  final String? paymentStatus;
  final String? couponCode;
  final double? discountAmount;
  final double? ownerPayoutAmount;
  final String? payoutStatus;
  final String? payoutTransactionRef;
  final DateTime? paidAt;

  final bool isNew;
  final bool isUrgent;
  final bool hasUnreadMessages;
  final String? conversationId;
  final int daysSinceRequested;

  final int availableRooms;
  final bool isPropertyPublished;

  BookingRequest({
    required this.requestId,
    required this.propertyId,
    this.propertyTitle,
    this.propertyCity,
    this.propertyState,
    this.propertyAddress,
    this.coverImage,
    this.roomId,
    this.roomNumber,
    this.roomType,
    this.monthlyRent,
    this.moveInDate,
    this.durationMonths,
    this.message,
    this.status = 'PENDING',
    this.ownerResponse,
    this.requestedAt,
    this.respondedAt,
    this.studentId,
    this.studentName,
    this.studentDisplayId,
    this.studentEmail,
    this.studentPhone,
    this.studentProfilePic,
    this.studentJoinedAt,
    this.studentTotalBookings,
    this.studentAcceptedBookings,
    this.studentHasActiveBooking = false,
    this.isRepeatStudent = false,
    this.isPaid = false,
    this.paidAmount,
    this.paymentStatus,
    this.couponCode,
    this.discountAmount,
    this.ownerPayoutAmount,
    this.payoutStatus,
    this.payoutTransactionRef,
    this.paidAt,
    this.isNew = false,
    this.isUrgent = false,
    this.hasUnreadMessages = false,
    this.conversationId,
    this.daysSinceRequested = 0,
    this.availableRooms = 0,
    this.isPropertyPublished = false,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    final bool derivedIsPaid =
        json['isPaid'] == true ||
        json['paymentStatus'] == 'PAID' ||
        json['status'] == 'COMPLETED' ||
        json['paidAt'] != null;

    return BookingRequest(
      requestId: _parseInt(json['requestId']),
      propertyId: _parseInt(json['propertyId']),
      propertyTitle: _parseString(json['propertyTitle']),
      propertyCity: _parseString(json['propertyCity']),
      propertyState: _parseString(json['propertyState']),
      propertyAddress: _parseString(json['propertyAddress']),
      coverImage: _parseString(json['coverImage']),
      roomId: json['roomId'] != null ? _parseInt(json['roomId']) : null,
      roomNumber: _parseString(json['roomNumber']),
      roomType: _parseString(json['roomType']),
      monthlyRent: _parseDouble(json['monthlyRent']),
      moveInDate: _parseDateTime(json['moveInDate']),
      durationMonths: json['durationMonths'] != null
          ? _parseInt(json['durationMonths'])
          : null,
      message: _parseString(json['message']),
      status: _parseString(json['status']) ?? 'PENDING',
      ownerResponse: _parseString(json['ownerResponse']),
      requestedAt: _parseDateTime(json['requestedAt']),
      respondedAt: _parseDateTime(json['respondedAt']),
      studentId: json['studentId'] != null ? _parseInt(json['studentId']) : null,
      studentName: _parseString(json['studentName']),
      studentDisplayId: _parseString(json['studentDisplayId']),
      studentEmail: _parseString(json['studentEmail']),
      studentPhone: _parseString(json['studentPhone']),
      studentProfilePic: _parseString(json['studentProfilePic']),
      studentJoinedAt: _parseDateTime(json['studentJoinedAt']),
      studentTotalBookings: json['studentTotalBookings'] != null
          ? _parseInt(json['studentTotalBookings'])
          : null,
      studentAcceptedBookings: json['studentAcceptedBookings'] != null
          ? _parseInt(json['studentAcceptedBookings'])
          : null,
      studentHasActiveBooking: json['studentHasActiveBooking'] ?? false,
      isRepeatStudent: json['isRepeatStudent'] ?? false,
      isPaid: derivedIsPaid,
      paidAmount: _parseDouble(json['paidAmount']),
      paymentStatus: _parseString(json['paymentStatus']) ??
          (derivedIsPaid ? 'PAID' : 'CREATED'),
      couponCode: _parseString(json['couponCode']),
      discountAmount: _parseDouble(json['discountAmount']),
      ownerPayoutAmount: _parseDouble(json['ownerPayoutAmount']),
      payoutStatus: _parseString(json['payoutStatus']),
      payoutTransactionRef: _parseString(json['payoutTransactionRef']),
      paidAt: _parseDateTime(json['paidAt']),
      isNew: json['isNew'] ?? false,
      isUrgent: json['isUrgent'] ?? false,
      hasUnreadMessages: json['hasUnreadMessages'] ?? false,
      conversationId: _parseString(json['conversationId']),
      daysSinceRequested: _parseInt(json['daysSinceRequested']),
      availableRooms: _parseInt(json['availableRooms']),
      isPropertyPublished: json['isPropertyPublished'] ?? false,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String? _parseString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.trim().isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
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
        if (message != null && message!.trim().isNotEmpty) 'message': message,
      };
}