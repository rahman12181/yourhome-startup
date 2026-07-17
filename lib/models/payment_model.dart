class PaymentSummary {
  final int bookingRequestId;
  final String propertyTitle;
  final String roomNumber;
  final double originalAmount;
  final bool eligibleForFirstBookingDiscount;
  final String? availableCouponCode;
  final double discountPercent;
  final double estimatedDiscountAmount;
  final double estimatedPayableAmount;
  final bool alreadyPaid;

  PaymentSummary({
    required this.bookingRequestId,
    required this.propertyTitle,
    required this.roomNumber,
    required this.originalAmount,
    required this.eligibleForFirstBookingDiscount,
    this.availableCouponCode,
    required this.discountPercent,
    required this.estimatedDiscountAmount,
    required this.estimatedPayableAmount,
    required this.alreadyPaid,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      bookingRequestId: json['bookingRequestId'] ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      originalAmount: (json['originalAmount'] ?? 0).toDouble(),
      eligibleForFirstBookingDiscount: json['eligibleForFirstBookingDiscount'] ?? false,
      availableCouponCode: json['availableCouponCode'],
      discountPercent: (json['discountPercent'] ?? 0).toDouble(),
      estimatedDiscountAmount: (json['estimatedDiscountAmount'] ?? 0).toDouble(),
      estimatedPayableAmount: (json['estimatedPayableAmount'] ?? 0).toDouble(),
      alreadyPaid: json['alreadyPaid'] ?? false,
    );
  }
}

class InitiatePaymentResponse {
  final int rentPaymentId;
  final String razorpayOrderId;
  final int amount;
  final String currency;
  final String? couponApplied;
  final double discountAmount;
  final double payableAmount;

  InitiatePaymentResponse({
    required this.rentPaymentId,
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    this.couponApplied,
    required this.discountAmount,
    required this.payableAmount,
  });

  factory InitiatePaymentResponse.fromJson(Map<String, dynamic> json) {
    return InitiatePaymentResponse(
      rentPaymentId: json['rentPaymentId'] ?? 0,
      razorpayOrderId: json['razorpayOrderId'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'INR',
      couponApplied: json['couponApplied'],
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      payableAmount: (json['payableAmount'] ?? 0).toDouble(),
    );
  }
}

class ConfirmPaymentResponse {
  final int rentPaymentId;
  final int bookingRequestId;
  final String propertyTitle;
  final String roomNumber;
  final double originalAmount;
  final String? couponCode;
  final double discountAmount;
  final double studentPayableAmount;
  final double ownerPayoutAmount;
  final String status;
  final String razorpayPaymentId;
  final String payoutStatus;
  final String? payoutTransactionRef;
  final String createdAt;
  final String paidAt;
  final String? payoutAt;

  ConfirmPaymentResponse({
    required this.rentPaymentId,
    required this.bookingRequestId,
    required this.propertyTitle,
    required this.roomNumber,
    required this.originalAmount,
    this.couponCode,
    required this.discountAmount,
    required this.studentPayableAmount,
    required this.ownerPayoutAmount,
    required this.status,
    required this.razorpayPaymentId,
    required this.payoutStatus,
    this.payoutTransactionRef,
    required this.createdAt,
    required this.paidAt,
    this.payoutAt,
  });

  factory ConfirmPaymentResponse.fromJson(Map<String, dynamic> json) {
    return ConfirmPaymentResponse(
      rentPaymentId: json['rentPaymentId'] ?? 0,
      bookingRequestId: json['bookingRequestId'] ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      originalAmount: (json['originalAmount'] ?? 0).toDouble(),
      couponCode: json['couponCode'],
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      studentPayableAmount: (json['studentPayableAmount'] ?? 0).toDouble(),
      ownerPayoutAmount: (json['ownerPayoutAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PAID',
      razorpayPaymentId: json['razorpayPaymentId'] ?? '',
      payoutStatus: json['payoutStatus'] ?? 'NOT_STARTED',
      payoutTransactionRef: json['payoutTransactionRef'],
      createdAt: json['createdAt'] ?? '',
      paidAt: json['paidAt'] ?? '',
      payoutAt: json['payoutAt'],
    );
  }
}

class RentPayment {
  final int rentPaymentId;
  final int bookingRequestId;
  final String propertyTitle;
  final String roomNumber;
  final double originalAmount;
  final String? couponCode;
  final double discountAmount;
  final double studentPayableAmount;
  final String status;
  final String razorpayPaymentId;
  final String payoutStatus;
  final String? payoutTransactionRef;
  final String createdAt;
  final String? paidAt;
  final String? payoutAt;

  RentPayment({
    required this.rentPaymentId,
    required this.bookingRequestId,
    required this.propertyTitle,
    required this.roomNumber,
    required this.originalAmount,
    this.couponCode,
    required this.discountAmount,
    required this.studentPayableAmount,
    required this.status,
    required this.razorpayPaymentId,
    required this.payoutStatus,
    this.payoutTransactionRef,
    required this.createdAt,
    this.paidAt,
    this.payoutAt,
  });

  factory RentPayment.fromJson(Map<String, dynamic> json) {
    return RentPayment(
      rentPaymentId: json['rentPaymentId'] ?? 0,
      bookingRequestId: json['bookingRequestId'] ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      originalAmount: (json['originalAmount'] ?? 0).toDouble(),
      couponCode: json['couponCode'],
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      studentPayableAmount: (json['studentPayableAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'CREATED',
      razorpayPaymentId: json['razorpayPaymentId'] ?? '',
      payoutStatus: json['payoutStatus'] ?? 'NOT_STARTED',
      payoutTransactionRef: json['payoutTransactionRef'],
      createdAt: json['createdAt'] ?? '',
      paidAt: json['paidAt'],
      payoutAt: json['payoutAt'],
    );
  }
}

class OwnerPayment {
  final int rentPaymentId;
  final int bookingRequestId;
  final String propertyTitle;
  final String roomNumber;
  final double originalAmount;
  final String? couponCode;
  final double discountAmount;
  final double ownerPayoutAmount;
  final String status;
  final String payoutStatus;
  final String? payoutTransactionRef;
  final int studentId;
  final String studentName;
  final String studentDisplayId;
  final String createdAt;
  final String? paidAt;
  final String? payoutAt;

  OwnerPayment({
    required this.rentPaymentId,
    required this.bookingRequestId,
    required this.propertyTitle,
    required this.roomNumber,
    required this.originalAmount,
    this.couponCode,
    required this.discountAmount,
    required this.ownerPayoutAmount,
    required this.status,
    required this.payoutStatus,
    this.payoutTransactionRef,
    required this.studentId,
    required this.studentName,
    required this.studentDisplayId,
    required this.createdAt,
    this.paidAt,
    this.payoutAt,
  });

  factory OwnerPayment.fromJson(Map<String, dynamic> json) {
    return OwnerPayment(
      rentPaymentId: json['rentPaymentId'] ?? 0,
      bookingRequestId: json['bookingRequestId'] ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      originalAmount: (json['originalAmount'] ?? 0).toDouble(),
      couponCode: json['couponCode'],
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      ownerPayoutAmount: (json['ownerPayoutAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PAID',
      payoutStatus: json['payoutStatus'] ?? 'NOT_STARTED',
      payoutTransactionRef: json['payoutTransactionRef'],
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      studentDisplayId: json['studentDisplayId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      paidAt: json['paidAt'],
      payoutAt: json['payoutAt'],
    );
  }
}

class AdminRentPayment {
  final int rentPaymentId;
  final int bookingRequestId;
  final String propertyTitle;
  final double originalAmount;
  final String? couponCode;
  final double discountAmount;
  final double studentPayableAmount;
  final double ownerPayoutAmount;
  final String status;
  final String payoutStatus;
  final String? payoutTransactionRef;
  final int studentId;
  final String studentName;
  final String studentDisplayId;
  final String createdAt;
  final String? paidAt;

  AdminRentPayment({
    required this.rentPaymentId,
    required this.bookingRequestId,
    required this.propertyTitle,
    required this.originalAmount,
    this.couponCode,
    required this.discountAmount,
    required this.studentPayableAmount,
    required this.ownerPayoutAmount,
    required this.status,
    required this.payoutStatus,
    this.payoutTransactionRef,
    required this.studentId,
    required this.studentName,
    required this.studentDisplayId,
    required this.createdAt,
    this.paidAt,
  });

  factory AdminRentPayment.fromJson(Map<String, dynamic> json) {
    return AdminRentPayment(
      rentPaymentId: json['rentPaymentId'] ?? 0,
      bookingRequestId: json['bookingRequestId'] ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      originalAmount: (json['originalAmount'] ?? 0).toDouble(),
      couponCode: json['couponCode'],
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      studentPayableAmount: (json['studentPayableAmount'] ?? 0).toDouble(),
      ownerPayoutAmount: (json['ownerPayoutAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PAID',
      payoutStatus: json['payoutStatus'] ?? 'NOT_STARTED',
      payoutTransactionRef: json['payoutTransactionRef'],
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      studentDisplayId: json['studentDisplayId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      paidAt: json['paidAt'],
    );
  }
}