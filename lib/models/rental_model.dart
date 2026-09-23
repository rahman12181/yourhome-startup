// lib/models/rental_model.dart
//
// Models for Module 17 — Rental Agreements + Monthly Rent
// Handles both the "list" shape (nested user/owner/property/room objects)
// and the "detail" shape (flat propertyTitle/roomNumber/ownerName fields)
// that the backend docs show for the same resource.

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int _asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

class RentalAgreement {
  final int id;
  final String agreementCode;
  final String propertyTitle;
  final String? propertyCity;
  final String? roomNumber;
  final String? ownerName;
  final String? ownerPhone;
  final double monthlyRent;
  final double securityDeposit;
  final double? advancePaid;
  final String startDate;
  final String? endDate;
  final int rentDueDay;
  final String status; // ACTIVE | TERMINATED | EXPIRED
  final String? terminationReason;
  final String? terminatedAt;
  final String? createdAt;

  RentalAgreement({
    required this.id,
    required this.agreementCode,
    required this.propertyTitle,
    this.propertyCity,
    this.roomNumber,
    this.ownerName,
    this.ownerPhone,
    required this.monthlyRent,
    required this.securityDeposit,
    this.advancePaid,
    required this.startDate,
    this.endDate,
    this.rentDueDay = 5,
    required this.status,
    this.terminationReason,
    this.terminatedAt,
    this.createdAt,
  });

  bool get isActive => status == 'ACTIVE';

  factory RentalAgreement.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    final room = json['room'] as Map<String, dynamic>?;
    final owner = json['owner'] as Map<String, dynamic>?;

    return RentalAgreement(
      id: _asInt(json['id']),
      agreementCode: json['agreementCode']?.toString() ?? '',
      propertyTitle: (json['propertyTitle'] ?? property?['title'] ?? '')
          .toString(),
      propertyCity: (json['propertyCity'] ?? property?['city'])?.toString(),
      roomNumber: (json['roomNumber'] ?? room?['roomNumber'])?.toString(),
      ownerName:
          (json['ownerName'] ?? owner?['businessName'] ?? owner?['name'])
              ?.toString(),
      ownerPhone: json['ownerPhone']?.toString(),
      monthlyRent: _asDouble(json['monthlyRent']),
      securityDeposit: _asDouble(json['securityDeposit']),
      advancePaid: _asDoubleOrNull(json['advancePaid']),
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString(),
      rentDueDay: _asInt(json['rentDueDay'], 5),
      status: json['status']?.toString() ?? 'ACTIVE',
      terminationReason: json['terminationReason']?.toString(),
      terminatedAt: json['terminatedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class RentInvoice {
  final int id;
  final String invoiceCode;
  final int agreementId;
  final String invoiceMonth; // "2026-10"
  final String dueDate;
  final double amount;
  final double lateFee;
  final String status; // PENDING | PAID | OVERDUE
  final String? paidAt;
  final int daysOverdue;
  final String? createdAt;

  RentInvoice({
    required this.id,
    required this.invoiceCode,
    required this.agreementId,
    required this.invoiceMonth,
    required this.dueDate,
    required this.amount,
    this.lateFee = 0,
    required this.status,
    this.paidAt,
    this.daysOverdue = 0,
    this.createdAt,
  });

  bool get isPaid => status == 'PAID';
  bool get isOverdue => daysOverdue > 0 || status == 'OVERDUE';
  double get totalPayable => amount + lateFee;

  factory RentInvoice.fromJson(Map<String, dynamic> json) {
    return RentInvoice(
      id: _asInt(json['id']),
      invoiceCode: json['invoiceCode']?.toString() ?? '',
      agreementId: _asInt(json['agreementId']),
      invoiceMonth: json['invoiceMonth']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      lateFee: _asDouble(json['lateFee']),
      status: json['status']?.toString() ?? 'PENDING',
      paidAt: json['paidAt']?.toString(),
      daysOverdue: _asInt(json['daysOverdue']),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// Response of POST /user/monthly-rent/initiate/{invoiceId}
class MonthlyRentInitiateResponse {
  final int id;
  final String paymentCode;
  final double amount;
  final String razorpayOrderId;

  MonthlyRentInitiateResponse({
    required this.id,
    required this.paymentCode,
    required this.amount,
    required this.razorpayOrderId,
  });

  factory MonthlyRentInitiateResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyRentInitiateResponse(
      id: _asInt(json['id']),
      paymentCode: json['paymentCode']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      razorpayOrderId: json['razorpayOrderId']?.toString() ?? '',
    );
  }
}

/// Response of both POST /user/monthly-rent/confirm and
/// GET /user/monthly-rent/my-payments (list items).
class MonthlyRentPayment {
  final int id;
  final String paymentCode;
  final double amount;
  final double? platformFeeAmount;
  final double? ownerPayoutAmount;
  final String status; // CREATED | PAID | FAILED
  final String? payoutStatus; // NOT_STARTED | PROCESSING | COMPLETED | FAILED
  final String? payoutTransactionRef;
  final String? paidAt;
  final String? payoutAt;

  MonthlyRentPayment({
    required this.id,
    required this.paymentCode,
    required this.amount,
    this.platformFeeAmount,
    this.ownerPayoutAmount,
    required this.status,
    this.payoutStatus,
    this.payoutTransactionRef,
    this.paidAt,
    this.payoutAt,
  });

  bool get isPaid => status == 'PAID';

  factory MonthlyRentPayment.fromJson(Map<String, dynamic> json) {
    return MonthlyRentPayment(
      id: _asInt(json['id']),
      paymentCode: json['paymentCode']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      platformFeeAmount: _asDoubleOrNull(json['platformFeeAmount']),
      ownerPayoutAmount: _asDoubleOrNull(json['ownerPayoutAmount']),
      status: json['status']?.toString() ?? 'CREATED',
      payoutStatus: json['payoutStatus']?.toString(),
      payoutTransactionRef: json['payoutTransactionRef']?.toString(),
      paidAt: json['paidAt']?.toString(),
      payoutAt: json['payoutAt']?.toString(),
    );
  }
}

/// Generic wrapper matching the backend's standard
/// { success, message, data } response envelope.
class RentalApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  RentalApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}