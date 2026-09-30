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
      bookingRequestId: (json['bookingRequestId'] as num?)?.toInt() ?? 0,
      propertyTitle: json['propertyTitle']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
      eligibleForFirstBookingDiscount: json['eligibleForFirstBookingDiscount'] == true,
      availableCouponCode: json['availableCouponCode']?.toString(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      estimatedDiscountAmount: (json['estimatedDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      estimatedPayableAmount: (json['estimatedPayableAmount'] as num?)?.toDouble() ?? 0.0,
      alreadyPaid: json['alreadyPaid'] == true,
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
      rentPaymentId: (json['rentPaymentId'] as num?)?.toInt() ?? 0,
      razorpayOrderId: json['razorpayOrderId']?.toString() ?? '',
      amount: (json['amount'] as num).toInt(),
      currency: json['currency']?.toString() ?? 'INR',
      couponApplied: json['couponApplied']?.toString(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      payableAmount: (json['payableAmount'] as num?)?.toDouble() ?? 0.0,
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
      rentPaymentId: (json['rentPaymentId'] as num?)?.toInt() ?? 0,
      bookingRequestId: (json['bookingRequestId'] as num?)?.toInt() ?? 0,
      propertyTitle: json['propertyTitle']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
      couponCode: json['couponCode']?.toString(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      studentPayableAmount: (json['studentPayableAmount'] as num?)?.toDouble() ?? 0.0,
      ownerPayoutAmount: (json['ownerPayoutAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PAID',
      razorpayPaymentId: json['razorpayPaymentId']?.toString() ?? '',
      payoutStatus: json['payoutStatus']?.toString() ?? 'NOT_STARTED',
      payoutTransactionRef: json['payoutTransactionRef']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      paidAt: json['paidAt']?.toString() ?? '',
      payoutAt: json['payoutAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rentPaymentId': rentPaymentId,
      'bookingRequestId': bookingRequestId,
      'propertyTitle': propertyTitle,
      'roomNumber': roomNumber,
      'originalAmount': originalAmount,
      'couponCode': couponCode,
      'discountAmount': discountAmount,
      'studentPayableAmount': studentPayableAmount,
      'ownerPayoutAmount': ownerPayoutAmount,
      'status': status,
      'razorpayPaymentId': razorpayPaymentId,
      'payoutStatus': payoutStatus,
      'payoutTransactionRef': payoutTransactionRef,
      'createdAt': createdAt,
      'paidAt': paidAt,
      'payoutAt': payoutAt,
    };
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
      rentPaymentId: (json['rentPaymentId'] as num?)?.toInt() ?? 0,
      bookingRequestId: (json['bookingRequestId'] as num?)?.toInt() ?? 0,
      propertyTitle: json['propertyTitle']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
      couponCode: json['couponCode']?.toString(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      studentPayableAmount: (json['studentPayableAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'CREATED',
      razorpayPaymentId: json['razorpayPaymentId']?.toString() ?? '',
      payoutStatus: json['payoutStatus']?.toString() ?? 'NOT_STARTED',
      payoutTransactionRef: json['payoutTransactionRef']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      paidAt: json['paidAt']?.toString(),
      payoutAt: json['payoutAt']?.toString(),
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
      rentPaymentId: (json['rentPaymentId'] as num?)?.toInt() ?? 0,
      bookingRequestId: (json['bookingRequestId'] as num?)?.toInt() ?? 0,
      propertyTitle: json['propertyTitle']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
      couponCode: json['couponCode']?.toString(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      ownerPayoutAmount: (json['ownerPayoutAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PAID',
      payoutStatus: json['payoutStatus']?.toString() ?? 'NOT_STARTED',
      payoutTransactionRef: json['payoutTransactionRef']?.toString(),
      studentId: (json['studentId'] as num?)?.toInt() ?? 0,
      studentName: json['studentName']?.toString() ?? '',
      studentDisplayId: json['studentDisplayId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      paidAt: json['paidAt']?.toString(),
      payoutAt: json['payoutAt']?.toString(),
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
      rentPaymentId: (json['rentPaymentId'] as num?)?.toInt() ?? 0,
      bookingRequestId: (json['bookingRequestId'] as num?)?.toInt() ?? 0,
      propertyTitle: json['propertyTitle']?.toString() ?? '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
      couponCode: json['couponCode']?.toString(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      studentPayableAmount: (json['studentPayableAmount'] as num?)?.toDouble() ?? 0.0,
      ownerPayoutAmount: (json['ownerPayoutAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PAID',
      payoutStatus: json['payoutStatus']?.toString() ?? 'NOT_STARTED',
      payoutTransactionRef: json['payoutTransactionRef']?.toString(),
      studentId: (json['studentId'] as num?)?.toInt() ?? 0,
      studentName: json['studentName']?.toString() ?? '',
      studentDisplayId: json['studentDisplayId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      paidAt: json['paidAt']?.toString(),
    );
  }
}