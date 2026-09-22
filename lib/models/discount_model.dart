// models/discount_model.dart

class DiscountEligibility {
  final bool eligible;
  final String? couponCode;
  final double? discountPercent;
  final String? message;

  DiscountEligibility({
    required this.eligible,
    this.couponCode,
    this.discountPercent,
    this.message,
  });

  factory DiscountEligibility.fromJson(Map<String, dynamic> json) {
    return DiscountEligibility(
      eligible: json['eligible'] ?? false,
      couponCode: json['couponCode'],
      discountPercent: json['discountPercent'] != null
          ? (json['discountPercent'] as num).toDouble()
          : null,
      message: json['message'],
    );
  }
}

class RentPaymentItem {
  final int rentPaymentId;
  final int bookingRequestId;
  final String propertyTitle;
  final String? roomNumber;
  final double originalAmount;
  final String? couponCode;
  final double discountAmount;
  final double studentPayableAmount;
  final String status; // CREATED / PAID / FAILED / REFUNDED
  final String payoutStatus;
  final DateTime createdAt;
  final DateTime? paidAt;

  RentPaymentItem({
    required this.rentPaymentId,
    required this.bookingRequestId,
    required this.propertyTitle,
    this.roomNumber,
    required this.originalAmount,
    this.couponCode,
    required this.discountAmount,
    required this.studentPayableAmount,
    required this.status,
    required this.payoutStatus,
    required this.createdAt,
    this.paidAt,
  });

  factory RentPaymentItem.fromJson(Map<String, dynamic> json) {
    return RentPaymentItem(
      rentPaymentId: json['rentPaymentId'],
      bookingRequestId: json['bookingRequestId'],
      propertyTitle: json['propertyTitle'] ?? '',
      roomNumber: json['roomNumber'],
      originalAmount: (json['originalAmount'] as num).toDouble(),
      couponCode: json['couponCode'],
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      studentPayableAmount: (json['studentPayableAmount'] as num).toDouble(),
      status: json['status'] ?? 'CREATED',
      payoutStatus: json['payoutStatus'] ?? 'NOT_STARTED',
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }
}