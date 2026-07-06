// ============== PENDING OWNER ==============
class PendingOwner {
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
  final String subscriptionPlan;
  final DateTime? verifiedAt; // ✅ ADD THIS
  final DateTime createdAt;

  PendingOwner({
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
    required this.subscriptionPlan,
    this.verifiedAt, // ✅ ADD THIS
    required this.createdAt,
  });

  factory PendingOwner.fromJson(Map<String, dynamic> json) {
    return PendingOwner(
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
      subscriptionPlan: json['subscriptionPlan'] ?? 'BASIC',
      verifiedAt: json['verifiedAt'] != null 
          ? DateTime.parse(json['verifiedAt']) 
          : null, 
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isPending => verificationStatus == 'PENDING';
  bool get isVerified => verificationStatus == 'VERIFIED';
  bool get isRejected => verificationStatus == 'REJECTED';
}
class OwnerDetail {
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
  final String subscriptionPlan;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final int totalProperties;
  final int totalRooms;
  final double totalRevenue;

  OwnerDetail({
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
    required this.subscriptionPlan,
    this.verifiedAt,
    required this.createdAt,
    this.totalProperties = 0,
    this.totalRooms = 0,
    this.totalRevenue = 0,
  });

  factory OwnerDetail.fromJson(Map<String, dynamic> json) {
    return OwnerDetail(
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
      subscriptionPlan: json['subscriptionPlan'] ?? 'BASIC',
      verifiedAt: json['verifiedAt'] != null 
          ? DateTime.parse(json['verifiedAt']) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      totalProperties: json['totalProperties'] ?? 0,
      totalRooms: json['totalRooms'] ?? 0,
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
    );
  }

  bool get isPending => verificationStatus == 'PENDING';
  bool get isVerified => verificationStatus == 'VERIFIED';
  bool get isRejected => verificationStatus == 'REJECTED';
}

// ============== PENDING PROPERTY ==============
class PendingProperty {
  final int propertyId;
  final String title;
  final String ownerName;
  final String ownerDisplayId;
  final String city;
  final String state;
  final String propertyType;
  final bool isPublished;
  final DateTime createdAt;

  PendingProperty({
    required this.propertyId,
    required this.title,
    required this.ownerName,
    required this.ownerDisplayId,
    required this.city,
    required this.state,
    required this.propertyType,
    required this.isPublished,
    required this.createdAt,
  });

  factory PendingProperty.fromJson(Map<String, dynamic> json) {
    return PendingProperty(
      propertyId: json['propertyId'] ?? 0,
      title: json['title'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerDisplayId: json['ownerDisplayId'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      propertyType: json['propertyType'] ?? '',
      isPublished: json['isPublished'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isPending => !isPublished;
}

// ============== ADMIN USER ==============
class AdminUser {
  final int userId;
  final String displayId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime createdAt;

  AdminUser({
    required this.userId,
    required this.displayId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    required this.isEmailVerified,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      userId: json['userId'] ?? 0,
      displayId: json['displayId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'STUDENT',
      isActive: json['isActive'] ?? true,
      isEmailVerified: json['isEmailVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ============== ADMIN DASHBOARD STATS ==============
class AdminDashboardStats {
  final int totalUsers;
  final int totalOwners;
  final int verifiedOwners;
  final int pendingVerifications;
  final int totalProperties;
  final int publishedProperties;
  final int pendingProperties;
  final double totalRevenue;
  final double listingSubscriptionRevenue;
  final double propertyAccessRevenue;

  AdminDashboardStats({
    required this.totalUsers,
    required this.totalOwners,
    required this.verifiedOwners,
    required this.pendingVerifications,
    required this.totalProperties,
    required this.publishedProperties,
    required this.pendingProperties,
    required this.totalRevenue,
    required this.listingSubscriptionRevenue,
    required this.propertyAccessRevenue,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalOwners: json['totalOwners'] ?? 0,
      verifiedOwners: json['verifiedOwners'] ?? 0,
      pendingVerifications: json['pendingVerifications'] ?? 0,
      totalProperties: json['totalProperties'] ?? 0,
      publishedProperties: json['publishedProperties'] ?? 0,
      pendingProperties: json['pendingProperties'] ?? 0,
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
      listingSubscriptionRevenue: json['listingSubscriptionRevenue']?.toDouble() ?? 0.0,
      propertyAccessRevenue: json['propertyAccessRevenue']?.toDouble() ?? 0.0,
    );
  }
}

// ============== REPORT ==============
class AdminReport {
  final int id;
  final String type;
  final int refId;
  final String reason;
  final String? description;
  final String status;
  final String reporterName;
  final DateTime createdAt;

  AdminReport({
    required this.id,
    required this.type,
    required this.refId,
    required this.reason,
    this.description,
    required this.status,
    required this.reporterName,
    required this.createdAt,
  });

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    return AdminReport(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      refId: json['refId'] ?? 0,
      reason: json['reason'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'PENDING',
      reporterName: json['reporter']?['name'] ?? 'Unknown',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isResolved => status == 'RESOLVED';
}

// ============== PROPERTY ACCESS SUBSCRIPTION (Admin) ==============
class AdminPropertyAccessSubscription {
  final int subscriptionId;
  final String plan;
  final int durationMonths;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double amountPaid;
  final String paymentId;
  final DateTime purchasedAt;

  AdminPropertyAccessSubscription({
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

  factory AdminPropertyAccessSubscription.fromJson(Map<String, dynamic> json) {
    return AdminPropertyAccessSubscription(
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
}