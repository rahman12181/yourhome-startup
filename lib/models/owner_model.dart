// ============== OWNER_MODEL.DART - COMPLETE ==============

import 'package:flutter/material.dart';

class OwnerProfile {
  final int ownerId;
  final int userId;
  final String displayId;
  final String name;
  final String email;
  final String phone;
  final String businessName;
  final String aadharNumber;
  final String panNumber;
  final String? aadharDocUrl;
  final String? panDocUrl;
  final String? addressProofUrl;
  final String verificationStatus;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final String subscriptionPlan;
  final String subscriptionStatus;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final double? monthlyFee;
  final DateTime createdAt;

  OwnerProfile({
    required this.ownerId,
    required this.userId,
    required this.displayId,
    required this.name,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.aadharNumber,
    required this.panNumber,
    this.aadharDocUrl,
    this.panDocUrl,
    this.addressProofUrl,
    required this.verificationStatus,
    this.rejectionReason,
    this.verifiedAt,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.monthlyFee,
    required this.createdAt,
  });

  factory OwnerProfile.fromJson(Map<String, dynamic> json) {
    return OwnerProfile(
      ownerId: json['ownerId'] ?? 0,
      userId: json['userId'] ?? 0,
      displayId: json['displayId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      businessName: json['businessName'] ?? '',
      aadharNumber: json['aadharNumber'] ?? '',
      panNumber: json['panNumber'] ?? '',
      aadharDocUrl: json['aadharDocUrl'],
      panDocUrl: json['panDocUrl'],
      addressProofUrl: json['addressProofUrl'],
      verificationStatus: json['verificationStatus'] ?? 'PENDING',
      rejectionReason: json['rejectionReason'],
      verifiedAt: json['verifiedAt'] != null 
          ? DateTime.parse(json['verifiedAt']) 
          : null,
      subscriptionPlan: json['subscriptionPlan'] ?? 'BASIC',
      subscriptionStatus: json['subscriptionStatus'] ?? 'INACTIVE',
      subscriptionStart: json['subscriptionStart'] != null 
          ? DateTime.parse(json['subscriptionStart']) 
          : null,
      subscriptionEnd: json['subscriptionEnd'] != null 
          ? DateTime.parse(json['subscriptionEnd']) 
          : null,
      monthlyFee: json['monthlyFee']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// lib/models/owner_model.dart

class VerificationStatus {
  final bool isVerified;
  final bool isRejected;
  final String? rejectionReason;
  final String? verifiedAt;
  final String? submittedAt;  // ✅ ADD THIS
  final String? businessName;
  final String? aadharNumber;
  final String? panNumber;
  final String? aadharDocUrl;
  final String? panDocUrl;
  final String? addressProofUrl;

  VerificationStatus({
    required this.isVerified,
    required this.isRejected,
    this.rejectionReason,
    this.verifiedAt,
    this.submittedAt,  // ✅ ADD THIS
    this.businessName,
    this.aadharNumber,
    this.panNumber,
    this.aadharDocUrl,
    this.panDocUrl,
    this.addressProofUrl,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    // Check both possible field names
    final status = json['verificationStatus'] ?? json['status'] ?? '';
    final isVerified = status == 'VERIFIED' || json['isVerified'] == true;
    final isRejected = status == 'REJECTED' || json['isRejected'] == true;

    return VerificationStatus(
      isVerified: isVerified,
      isRejected: isRejected,
      rejectionReason: json['rejectionReason'],
      verifiedAt: json['verifiedAt'],
      submittedAt: json['submittedAt'] ?? json['createdAt'],
      businessName: json['businessName'],
      aadharNumber: json['aadharNumber'],
      panNumber: json['panNumber'],
      aadharDocUrl: json['aadharDocUrl'],
      panDocUrl: json['panDocUrl'],
      addressProofUrl: json['addressProofUrl'],
    );
  }
}

// ============== SUBSCRIPTION ORDER ==============
class SubscriptionOrder {
  final String razorpayOrderId;
  final int amount;
  final String currency;
  final String plan;
  final int? durationMonths;
  final double? planPrice;

  SubscriptionOrder({
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.plan,
    this.durationMonths,
    this.planPrice,
  });

  factory SubscriptionOrder.fromJson(Map<String, dynamic> json) {
    return SubscriptionOrder(
      razorpayOrderId: json['razorpayOrderId'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'INR',
      plan: json['plan'] ?? '',
      durationMonths: json['durationMonths'],
      planPrice: json['planPrice']?.toDouble(),
    );
  }

  String get amountInRupees => '₹${(amount / 100).toStringAsFixed(2)}';
}

class SubscriptionDetails {
  final String plan;
  final String subscriptionStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? monthlyFee;
  final int daysRemaining;

  SubscriptionDetails({
    required this.plan,
    required this.subscriptionStatus,
    this.startDate,
    this.endDate,
    this.monthlyFee,
    required this.daysRemaining,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetails(
      plan: json['plan'] ?? 'BASIC',
      subscriptionStatus: json['subscriptionStatus'] ?? 'INACTIVE',
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : null,
      monthlyFee: json['monthlyFee']?.toDouble(),
      daysRemaining: json['daysRemaining'] ?? 0,
    );
  }

  bool get isActive => subscriptionStatus == 'ACTIVE';
  bool get isExpired => subscriptionStatus == 'EXPIRED';
  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining > 0;
  
  String get planDisplayName {
    switch (plan) {
      case 'BASIC': return 'Basic';
      case 'STANDARD': return 'Standard';
      case 'PREMIUM': return 'Premium';
      case 'ENTERPRISE': return 'Enterprise';
      default: return plan;
    }
  }
}

// ============== DASHBOARD STATS ==============
class DashboardStats {
  final int totalProperties;
  final int publishedProperties;
  final int totalRooms;
  final int availableRooms;
  final int occupiedRooms;
  final int totalBookingRequests;
  final int pendingRequests;
  final int acceptedRequests;
  final int rejectedRequests;
  final int totalViews;
  final double averageRating;

  DashboardStats({
    required this.totalProperties,
    required this.publishedProperties,
    required this.totalRooms,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.totalBookingRequests,
    required this.pendingRequests,
    required this.acceptedRequests,
    required this.rejectedRequests,
    required this.totalViews,
    required this.averageRating,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalProperties: json['totalProperties'] ?? 0,
      publishedProperties: json['publishedProperties'] ?? 0,
      totalRooms: json['totalRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      occupiedRooms: json['occupiedRooms'] ?? 0,
      totalBookingRequests: json['totalBookingRequests'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      acceptedRequests: json['acceptedRequests'] ?? 0,
      rejectedRequests: json['rejectedRequests'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
    );
  }

  double get occupancyRate {
    if (totalRooms == 0) return 0;
    return (occupiedRooms / totalRooms) * 100;
  }

  double get bookingConversionRate {
    if (totalBookingRequests == 0) return 0;
    return (acceptedRequests / totalBookingRequests) * 100;
  }
}

// ============== PROPERTY ACCESS SUBSCRIPTION ==============
class PropertyAccessSubscription {
  final int subscriptionId;
  final String plan;
  final int durationMonths;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double amountPaid;
  final String paymentId;
  final DateTime purchasedAt;

  PropertyAccessSubscription({
    required this.subscriptionId,
    required this.plan,
    required this.durationMonths,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.amountPaid,
    required this.paymentId,
    required this.purchasedAt,
  });

  factory PropertyAccessSubscription.fromJson(Map<String, dynamic> json) {
    return PropertyAccessSubscription(
      subscriptionId: json['subscriptionId'] ?? 0,
      plan: json['plan'] ?? '',
      durationMonths: json['durationMonths'] ?? 0,
      status: json['status'] ?? 'ACTIVE',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      amountPaid: json['amountPaid']?.toDouble() ?? 0.0,
      paymentId: json['paymentId'] ?? '',
      purchasedAt: DateTime.parse(json['purchasedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isActive => status == 'ACTIVE';
  bool get isExpired => status == 'EXPIRED';
  bool get isCancelled => status == 'CANCELLED';
  
  int get daysRemaining {
    if (!isActive) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining > 0;

  String get planDisplayName {
    switch (plan) {
      case 'MONTHLY_1': return '1 Month';
      case 'MONTHLY_2': return '2 Months';
      case 'MONTHLY_3': return '3 Months';
      case 'MONTHLY_4': return '4 Months';
      case 'MONTHLY_5': return '5 Months';
      default: return plan;
    }
  }
}

// ============== PROPERTY ACCESS STATUS ==============
class PropertyAccessStatus {
  final bool hasActiveSubscription;
  final String? plan;
  final int? durationMonths;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int daysRemaining;
  final bool isExpiringSoon;
  final double? amountPaid;

  PropertyAccessStatus({
    required this.hasActiveSubscription,
    this.plan,
    this.durationMonths,
    required this.status,
    this.startDate,
    this.endDate,
    required this.daysRemaining,
    required this.isExpiringSoon,
    this.amountPaid,
  });

  factory PropertyAccessStatus.fromJson(Map<String, dynamic> json) {
    return PropertyAccessStatus(
      hasActiveSubscription: json['hasActiveSubscription'] ?? false,
      plan: json['plan'],
      durationMonths: json['durationMonths'],
      status: json['status'] ?? 'EXPIRED',
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : null,
      daysRemaining: json['daysRemaining'] ?? 0,
      isExpiringSoon: json['isExpiringSoon'] ?? false,
      amountPaid: json['amountPaid']?.toDouble(),
    );
  }

  bool get isActive => status == 'ACTIVE';
  bool get isExpired => status == 'EXPIRED';
  
  String get statusDisplay {
    if (isActive && isExpiringSoon) {
      return 'Expiring Soon';
    }
    switch (status) {
      case 'ACTIVE': return 'Active';
      case 'EXPIRED': return 'Expired';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }

  Color get statusColor {
    if (isActive && isExpiringSoon) {
      return Colors.orange;
    }
    switch (status) {
      case 'ACTIVE': return Colors.green;
      case 'EXPIRED': return Colors.red;
      case 'CANCELLED': return Colors.grey;
      default: return Colors.grey;
    }
  }
}

// ============== APPLY OWNER REQUEST ==============
class ApplyOwnerRequest {
  final String businessName;
  final String aadharNumber;
  final String panNumber;

  ApplyOwnerRequest({
    required this.businessName,
    required this.aadharNumber,
    required this.panNumber,
  });

  Map<String, String> toJson() => {
    'businessName': businessName,
    'aadharNumber': aadharNumber,
    'panNumber': panNumber,
  };
}

// ============== SUBSCRIPTION PLAN ==============
class SubscriptionPlan {
  final String code;
  final String name;
  final double price;
  final int maxRooms;
  final int rank;
  final String description;

  SubscriptionPlan({
    required this.code,
    required this.name,
    required this.price,
    required this.maxRooms,
    required this.rank,
    required this.description,
  });

  static final List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      code: 'BASIC',
      name: 'Basic',
      price: 399,
      maxRooms: 5,
      rank: 1,
      description: 'Perfect for small properties',
    ),
    SubscriptionPlan(
      code: 'STANDARD',
      name: 'Standard',
      price: 599,
      maxRooms: 10,
      rank: 2,
      description: 'Great for medium properties',
    ),
    SubscriptionPlan(
      code: 'PREMIUM',
      name: 'Premium',
      price: 799,
      maxRooms: 20,
      rank: 3,
      description: 'Best for large properties',
    ),
    SubscriptionPlan(
      code: 'ENTERPRISE',
      name: 'Enterprise',
      price: 999,
      maxRooms: 999,
      rank: 4,
      description: 'For property chains',
    ),
  ];

  static SubscriptionPlan? getByCode(String code) {
    return plans.firstWhere(
      (plan) => plan.code == code,
      orElse: () => plans.first,
    );
  }

  static final List<PropertyAccessPlan> propertyAccessPlans = [
    PropertyAccessPlan(
      code: 'MONTHLY_1',
      name: '1 Month',
      price: 599,
      durationMonths: 1,
    ),
    PropertyAccessPlan(
      code: 'MONTHLY_2',
      name: '2 Months',
      price: 899,
      durationMonths: 2,
    ),
    PropertyAccessPlan(
      code: 'MONTHLY_3',
      name: '3 Months',
      price: 1299,
      durationMonths: 3,
    ),
    PropertyAccessPlan(
      code: 'MONTHLY_4',
      name: '4 Months',
      price: 1599,
      durationMonths: 4,
    ),
    PropertyAccessPlan(
      code: 'MONTHLY_5',
      name: '5 Months',
      price: 1899,
      durationMonths: 5,
    ),
  ];
}

// ============== PROPERTY ACCESS PLAN ==============
class PropertyAccessPlan {
  final String code;
  final String name;
  final double price;
  final int durationMonths;

  PropertyAccessPlan({
    required this.code,
    required this.name,
    required this.price,
    required this.durationMonths,
  });

  String get displayPrice => '₹${price.toStringAsFixed(0)}';
  String get displayDuration => '$durationMonths Month${durationMonths > 1 ? 's' : ''}';
  String get displayPerMonth => '₹${(price / durationMonths).toStringAsFixed(0)}/month';
}