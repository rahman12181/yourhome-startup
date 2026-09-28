// ═══════════════════════════════════════════════════════════
// NESTORA — ADMIN ANALYTICS MODELS
// ═══════════════════════════════════════════════════════════

// ═══════════════════════════════════════════
// CHART POINT — Generic
// ═══════════════════════════════════════════
class ChartPoint {
  final String label;
  final double value;

  ChartPoint({required this.label, required this.value});

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      label: json['label']?.toString() ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

// ═══════════════════════════════════════════
// ADMIN ACTION ITEM
// ═══════════════════════════════════════════
class AdminActionItem {
  final String id;
  final String type;
  final String priority;
  final String title;
  final String description;
  final String actionLabel;
  final String actionRoute;
  final String icon;
  final String color;
  final int? referenceId;
  final int? count;

  AdminActionItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionRoute,
    required this.icon,
    required this.color,
    this.referenceId,
    this.count,
  });

  factory AdminActionItem.fromJson(Map<String, dynamic> json) {
    return AdminActionItem(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      priority: json['priority'] ?? 'LOW',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      actionLabel: json['actionLabel'] ?? 'View',
      actionRoute: json['actionRoute'] ?? '',
      icon: json['icon'] ?? 'info',
      color: json['color'] ?? '#7C3AED',
      referenceId: json['referenceId'],
      count: json['count'],
    );
  }
}

// ═══════════════════════════════════════════
// ADMIN DASHBOARD SUMMARY (ALL-IN-ONE)
// ═══════════════════════════════════════════
class AdminDashboardSummary {
  final int totalUsers;
  final int totalOwners;
  final int totalProperties;
  final int totalBookings;
  final double totalRevenue;
  final int activeSubscriptions;
  final int pendingActions;
  final int newUsersToday;
  final int newOwnersToday;
  final int newPropertiesToday;
  final int newBookingsToday;
  final double revenueToday;
  final int withdrawalsToday;
  final double userGrowthPercent;
  final double ownerGrowthPercent;
  final double propertyGrowthPercent;
  final double bookingGrowthPercent;
  final double revenueGrowthPercent;
  final List<AdminActionItem> actionsRequired;
  final List<ChartPoint> userTrend;
  final List<ChartPoint> ownerTrend;
  final List<ChartPoint> bookingTrend;
  final List<ChartPoint> revenueTrend;
  final List<ChartPoint> propertyTrend;
  final List<ChartPoint> bookingStatusBreakdown;
  final List<ChartPoint> propertyStatusBreakdown;
  final List<ChartPoint> userRoleBreakdown;
  final List<ChartPoint> ownerVerificationBreakdown;
  final List<ChartPoint> topCities;
  final List<ChartPoint> topPropertyTypes;
  final List<ChartPoint> topSubscriptionPlans;
  final int unreadSupportTickets;
  final int pendingReports;

  AdminDashboardSummary({
    required this.totalUsers,
    required this.totalOwners,
    required this.totalProperties,
    required this.totalBookings,
    required this.totalRevenue,
    required this.activeSubscriptions,
    required this.pendingActions,
    required this.newUsersToday,
    required this.newOwnersToday,
    required this.newPropertiesToday,
    required this.newBookingsToday,
    required this.revenueToday,
    required this.withdrawalsToday,
    required this.userGrowthPercent,
    required this.ownerGrowthPercent,
    required this.propertyGrowthPercent,
    required this.bookingGrowthPercent,
    required this.revenueGrowthPercent,
    required this.actionsRequired,
    required this.userTrend,
    required this.ownerTrend,
    required this.bookingTrend,
    required this.revenueTrend,
    required this.propertyTrend,
    required this.bookingStatusBreakdown,
    required this.propertyStatusBreakdown,
    required this.userRoleBreakdown,
    required this.ownerVerificationBreakdown,
    required this.topCities,
    required this.topPropertyTypes,
    required this.topSubscriptionPlans,
    required this.unreadSupportTickets,
    required this.pendingReports,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    List<ChartPoint> parseList(String key) {
      final list = json[key] as List? ?? [];
      return list
          .map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return AdminDashboardSummary(
      totalUsers: json['totalUsers'] ?? 0,
      totalOwners: json['totalOwners'] ?? 0,
      totalProperties: json['totalProperties'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      activeSubscriptions: json['activeSubscriptions'] ?? 0,
      pendingActions: json['pendingActions'] ?? 0,
      newUsersToday: json['newUsersToday'] ?? 0,
      newOwnersToday: json['newOwnersToday'] ?? 0,
      newPropertiesToday: json['newPropertiesToday'] ?? 0,
      newBookingsToday: json['newBookingsToday'] ?? 0,
      revenueToday: (json['revenueToday'] ?? 0).toDouble(),
      withdrawalsToday: json['withdrawalsToday'] ?? 0,
      userGrowthPercent: (json['userGrowthPercent'] ?? 0).toDouble(),
      ownerGrowthPercent: (json['ownerGrowthPercent'] ?? 0).toDouble(),
      propertyGrowthPercent: (json['propertyGrowthPercent'] ?? 0).toDouble(),
      bookingGrowthPercent: (json['bookingGrowthPercent'] ?? 0).toDouble(),
      revenueGrowthPercent: (json['revenueGrowthPercent'] ?? 0).toDouble(),
      actionsRequired: (json['actionsRequired'] as List? ?? [])
          .map((e) => AdminActionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      userTrend: parseList('userTrend'),
      ownerTrend: parseList('ownerTrend'),
      bookingTrend: parseList('bookingTrend'),
      revenueTrend: parseList('revenueTrend'),
      propertyTrend: parseList('propertyTrend'),
      bookingStatusBreakdown: parseList('bookingStatusBreakdown'),
      propertyStatusBreakdown: parseList('propertyStatusBreakdown'),
      userRoleBreakdown: parseList('userRoleBreakdown'),
      ownerVerificationBreakdown: parseList('ownerVerificationBreakdown'),
      topCities: parseList('topCities'),
      topPropertyTypes: parseList('topPropertyTypes'),
      topSubscriptionPlans: parseList('topSubscriptionPlans'),
      unreadSupportTickets: json['unreadSupportTickets'] ?? 0,
      pendingReports: json['pendingReports'] ?? 0,
    );
  }
}

// ═══════════════════════════════════════════
// USER ANALYTICS
// ═══════════════════════════════════════════
class UserAnalytics {
  final int totalUsers;
  final int activeUsers;
  final int deactivatedUsers;
  final int verifiedUsers;
  final int unverifiedUsers;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;
  final double growthPercent;
  final double retentionRate;
  final double churnRate;
  final List<ChartPoint> growthTrend;
  final List<ChartPoint> roleBreakdown;
  final List<ChartPoint> cityBreakdown;
  final List<ChartPoint> stateBreakdown;
  final List<ChartPoint> signupByDayOfWeek;
  final List<ChartPoint> activeVsInactive;

  UserAnalytics({
    required this.totalUsers,
    required this.activeUsers,
    required this.deactivatedUsers,
    required this.verifiedUsers,
    required this.unverifiedUsers,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.growthPercent,
    required this.retentionRate,
    required this.churnRate,
    required this.growthTrend,
    required this.roleBreakdown,
    required this.cityBreakdown,
    required this.stateBreakdown,
    required this.signupByDayOfWeek,
    required this.activeVsInactive,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    List<ChartPoint> parse(String key) => (json[key] as List? ?? [])
        .map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return UserAnalytics(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      deactivatedUsers: json['deactivatedUsers'] ?? 0,
      verifiedUsers: json['verifiedUsers'] ?? 0,
      unverifiedUsers: json['unverifiedUsers'] ?? 0,
      newUsersToday: json['newUsersToday'] ?? 0,
      newUsersThisWeek: json['newUsersThisWeek'] ?? 0,
      newUsersThisMonth: json['newUsersThisMonth'] ?? 0,
      growthPercent: (json['growthPercent'] ?? 0).toDouble(),
      retentionRate: (json['retentionRate'] ?? 0).toDouble(),
      churnRate: (json['churnRate'] ?? 0).toDouble(),
      growthTrend: parse('growthTrend'),
      roleBreakdown: parse('roleBreakdown'),
      cityBreakdown: parse('cityBreakdown'),
      stateBreakdown: parse('stateBreakdown'),
      signupByDayOfWeek: parse('signupByDayOfWeek'),
      activeVsInactive: parse('activeVsInactive'),
    );
  }
}

// ═══════════════════════════════════════════
// OWNER ANALYTICS
// ═══════════════════════════════════════════
class OwnerAnalytics {
  final int totalOwners;
  final int verifiedOwners;
  final int pendingVerifications;
  final int rejectedOwners;
  final int newOwnersToday;
  final int newOwnersThisWeek;
  final int newOwnersThisMonth;
  final double growthPercent;
  final double averageVerificationTimeHours;
  final double averagePropertiesPerOwner;
  final double averageRevenuePerOwner;
  final List<ChartPoint> growthTrend;
  final List<ChartPoint> verificationBreakdown;
  final List<ChartPoint> subscriptionPlanBreakdown;
  final List<ChartPoint> propertyAccessPlanBreakdown;
  final List<ChartPoint> cityBreakdown;
  final List<ChartPoint> topOwnersByRevenue;
  final List<ChartPoint> topOwnersByProperties;

  OwnerAnalytics({
    required this.totalOwners,
    required this.verifiedOwners,
    required this.pendingVerifications,
    required this.rejectedOwners,
    required this.newOwnersToday,
    required this.newOwnersThisWeek,
    required this.newOwnersThisMonth,
    required this.growthPercent,
    required this.averageVerificationTimeHours,
    required this.averagePropertiesPerOwner,
    required this.averageRevenuePerOwner,
    required this.growthTrend,
    required this.verificationBreakdown,
    required this.subscriptionPlanBreakdown,
    required this.propertyAccessPlanBreakdown,
    required this.cityBreakdown,
    required this.topOwnersByRevenue,
    required this.topOwnersByProperties,
  });

  factory OwnerAnalytics.fromJson(Map<String, dynamic> json) {
    List<ChartPoint> parse(String key) => (json[key] as List? ?? [])
        .map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return OwnerAnalytics(
      totalOwners: json['totalOwners'] ?? 0,
      verifiedOwners: json['verifiedOwners'] ?? 0,
      pendingVerifications: json['pendingVerifications'] ?? 0,
      rejectedOwners: json['rejectedOwners'] ?? 0,
      newOwnersToday: json['newOwnersToday'] ?? 0,
      newOwnersThisWeek: json['newOwnersThisWeek'] ?? 0,
      newOwnersThisMonth: json['newOwnersThisMonth'] ?? 0,
      growthPercent: (json['growthPercent'] ?? 0).toDouble(),
      averageVerificationTimeHours:
          (json['averageVerificationTimeHours'] ?? 0).toDouble(),
      averagePropertiesPerOwner:
          (json['averagePropertiesPerOwner'] ?? 0).toDouble(),
      averageRevenuePerOwner:
          (json['averageRevenuePerOwner'] ?? 0).toDouble(),
      growthTrend: parse('growthTrend'),
      verificationBreakdown: parse('verificationBreakdown'),
      subscriptionPlanBreakdown: parse('subscriptionPlanBreakdown'),
      propertyAccessPlanBreakdown: parse('propertyAccessPlanBreakdown'),
      cityBreakdown: parse('cityBreakdown'),
      topOwnersByRevenue: parse('topOwnersByRevenue'),
      topOwnersByProperties: parse('topOwnersByProperties'),
    );
  }
}

// ═══════════════════════════════════════════
// REVENUE ANALYTICS
// ═══════════════════════════════════════════
class RevenueAnalytics {
  final double totalRevenue;
  final double thisMonthRevenue;
  final double lastMonthRevenue;
  final double thisYearRevenue;
  final double growthPercent;
  final double listingSubscriptionRevenue;
  final double propertyAccessRevenue;
  final double rentCommissionRevenue;
  final double featuredListingRevenue;
  final double totalPayoutsCompleted;
  final double totalPayoutsPending;
  final double totalPayoutsFailed;
  final double totalWithdrawalsApproved;
  final double totalWithdrawalsPending;
  final double averageRevenuePerOwner;
  final double averageRevenuePerUser;
  final double averageTransactionValue;
  final List<ChartPoint> monthlyTrend;
  final List<ChartPoint> dailyTrend;
  final List<ChartPoint> revenueBySource;
  final List<ChartPoint> revenueByPlan;
  final List<ChartPoint> revenueByCity;

  RevenueAnalytics({
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.lastMonthRevenue,
    required this.thisYearRevenue,
    required this.growthPercent,
    required this.listingSubscriptionRevenue,
    required this.propertyAccessRevenue,
    required this.rentCommissionRevenue,
    required this.featuredListingRevenue,
    required this.totalPayoutsCompleted,
    required this.totalPayoutsPending,
    required this.totalPayoutsFailed,
    required this.totalWithdrawalsApproved,
    required this.totalWithdrawalsPending,
    required this.averageRevenuePerOwner,
    required this.averageRevenuePerUser,
    required this.averageTransactionValue,
    required this.monthlyTrend,
    required this.dailyTrend,
    required this.revenueBySource,
    required this.revenueByPlan,
    required this.revenueByCity,
  });

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    List<ChartPoint> parse(String key) => (json[key] as List? ?? [])
        .map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    double d(String key) => (json[key] ?? 0).toDouble();

    return RevenueAnalytics(
      totalRevenue: d('totalRevenue'),
      thisMonthRevenue: d('thisMonthRevenue'),
      lastMonthRevenue: d('lastMonthRevenue'),
      thisYearRevenue: d('thisYearRevenue'),
      growthPercent: d('growthPercent'),
      listingSubscriptionRevenue: d('listingSubscriptionRevenue'),
      propertyAccessRevenue: d('propertyAccessRevenue'),
      rentCommissionRevenue: d('rentCommissionRevenue'),
      featuredListingRevenue: d('featuredListingRevenue'),
      totalPayoutsCompleted: d('totalPayoutsCompleted'),
      totalPayoutsPending: d('totalPayoutsPending'),
      totalPayoutsFailed: d('totalPayoutsFailed'),
      totalWithdrawalsApproved: d('totalWithdrawalsApproved'),
      totalWithdrawalsPending: d('totalWithdrawalsPending'),
      averageRevenuePerOwner: d('averageRevenuePerOwner'),
      averageRevenuePerUser: d('averageRevenuePerUser'),
      averageTransactionValue: d('averageTransactionValue'),
      monthlyTrend: parse('monthlyTrend'),
      dailyTrend: parse('dailyTrend'),
      revenueBySource: parse('revenueBySource'),
      revenueByPlan: parse('revenueByPlan'),
      revenueByCity: parse('revenueByCity'),
    );
  }
}

// ═══════════════════════════════════════════
// BOOKING ANALYTICS
// ═══════════════════════════════════════════
class BookingAnalytics {
  final int totalBookings;
  final int pendingBookings;
  final int acceptedBookings;
  final int rejectedBookings;
  final int cancelledBookings;
  final int completedBookings;
  final int thisMonthBookings;
  final int lastMonthBookings;
  final double growthPercent;
  final double acceptanceRate;
  final double rejectionRate;
  final double cancellationRate;
  final double averageResponseTimeHours;
  final List<ChartPoint> monthlyTrend;
  final List<ChartPoint> dailyTrend;
  final List<ChartPoint> statusBreakdown;
  final List<ChartPoint> byPropertyType;
  final List<ChartPoint> byCity;
  final List<ChartPoint> byGender;
  final List<ChartPoint> topPropertiesByBookings;

  BookingAnalytics({
    required this.totalBookings,
    required this.pendingBookings,
    required this.acceptedBookings,
    required this.rejectedBookings,
    required this.cancelledBookings,
    required this.completedBookings,
    required this.thisMonthBookings,
    required this.lastMonthBookings,
    required this.growthPercent,
    required this.acceptanceRate,
    required this.rejectionRate,
    required this.cancellationRate,
    required this.averageResponseTimeHours,
    required this.monthlyTrend,
    required this.dailyTrend,
    required this.statusBreakdown,
    required this.byPropertyType,
    required this.byCity,
    required this.byGender,
    required this.topPropertiesByBookings,
  });

  factory BookingAnalytics.fromJson(Map<String, dynamic> json) {
    List<ChartPoint> parse(String key) => (json[key] as List? ?? [])
        .map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return BookingAnalytics(
      totalBookings: json['totalBookings'] ?? 0,
      pendingBookings: json['pendingBookings'] ?? 0,
      acceptedBookings: json['acceptedBookings'] ?? 0,
      rejectedBookings: json['rejectedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      thisMonthBookings: json['thisMonthBookings'] ?? 0,
      lastMonthBookings: json['lastMonthBookings'] ?? 0,
      growthPercent: (json['growthPercent'] ?? 0).toDouble(),
      acceptanceRate: (json['acceptanceRate'] ?? 0).toDouble(),
      rejectionRate: (json['rejectionRate'] ?? 0).toDouble(),
      cancellationRate: (json['cancellationRate'] ?? 0).toDouble(),
      averageResponseTimeHours:
          (json['averageResponseTimeHours'] ?? 0).toDouble(),
      monthlyTrend: parse('monthlyTrend'),
      dailyTrend: parse('dailyTrend'),
      statusBreakdown: parse('statusBreakdown'),
      byPropertyType: parse('byPropertyType'),
      byCity: parse('byCity'),
      byGender: parse('byGender'),
      topPropertiesByBookings: parse('topPropertiesByBookings'),
    );
  }
}

// ═══════════════════════════════════════════
// PROPERTY ANALYTICS
// ═══════════════════════════════════════════
class PropertyAnalytics {
  final int totalProperties;
  final int publishedProperties;
  final int pendingProperties;
  final int unpublishedProperties;
  final int featuredProperties;
  final int newPropertiesThisMonth;
  final double growthPercent;
  final int totalRooms;
  final int availableRooms;
  final int occupiedRooms;
  final double averageOccupancyRate;
  final int totalViews;
  final double averageViewsPerProperty;
  final List<ChartPoint> monthlyTrend;
  final List<ChartPoint> typeBreakdown;
  final List<ChartPoint> cityBreakdown;
  final List<ChartPoint> genderBreakdown;
  final List<ChartPoint> occupancyBreakdown;
  final List<ChartPoint> topPropertiesByViews;
  final List<ChartPoint> topPropertiesByRevenue;

  PropertyAnalytics({
    required this.totalProperties,
    required this.publishedProperties,
    required this.pendingProperties,
    required this.unpublishedProperties,
    required this.featuredProperties,
    required this.newPropertiesThisMonth,
    required this.growthPercent,
    required this.totalRooms,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.averageOccupancyRate,
    required this.totalViews,
    required this.averageViewsPerProperty,
    required this.monthlyTrend,
    required this.typeBreakdown,
    required this.cityBreakdown,
    required this.genderBreakdown,
    required this.occupancyBreakdown,
    required this.topPropertiesByViews,
    required this.topPropertiesByRevenue,
  });

  factory PropertyAnalytics.fromJson(Map<String, dynamic> json) {
    List<ChartPoint> parse(String key) => (json[key] as List? ?? [])
        .map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return PropertyAnalytics(
      totalProperties: json['totalProperties'] ?? 0,
      publishedProperties: json['publishedProperties'] ?? 0,
      pendingProperties: json['pendingProperties'] ?? 0,
      unpublishedProperties: json['unpublishedProperties'] ?? 0,
      featuredProperties: json['featuredProperties'] ?? 0,
      newPropertiesThisMonth: json['newPropertiesThisMonth'] ?? 0,
      growthPercent: (json['growthPercent'] ?? 0).toDouble(),
      totalRooms: json['totalRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      occupiedRooms: json['occupiedRooms'] ?? 0,
      averageOccupancyRate: (json['averageOccupancyRate'] ?? 0).toDouble(),
      totalViews: json['totalViews'] ?? 0,
      averageViewsPerProperty:
          (json['averageViewsPerProperty'] ?? 0).toDouble(),
      monthlyTrend: parse('monthlyTrend'),
      typeBreakdown: parse('typeBreakdown'),
      cityBreakdown: parse('cityBreakdown'),
      genderBreakdown: parse('genderBreakdown'),
      occupancyBreakdown: parse('occupancyBreakdown'),
      topPropertiesByViews: parse('topPropertiesByViews'),
      topPropertiesByRevenue: parse('topPropertiesByRevenue'),
    );
  }
}

// ═══════════════════════════════════════════
// ENGAGEMENT ANALYTICS
// ═══════════════════════════════════════════
class EngagementAnalytics {
  final int dailyActiveUsers;
  final int weeklyActiveUsers;
  final int monthlyActiveUsers;
  final double dauMauRatio;
  final int totalSearches;
  final int totalPropertyViews;
  final int totalChatMessages;
  final int totalReviews;
  final int totalWishlistSaves;
  final double averageRating;
  final List<ChartPoint> dauTrend;
  final List<ChartPoint> searchesTrend;
  final List<ChartPoint> viewsTrend;
  final List<ChartPoint> chatMessagesTrend;
  final List<ChartPoint> ratingDistribution;

  EngagementAnalytics({
    required this.dailyActiveUsers,
    required this.weeklyActiveUsers,
    required this.monthlyActiveUsers,
    required this.dauMauRatio,
    required this.totalSearches,
    required this.totalPropertyViews,
    required this.totalChatMessages,
    required this.totalReviews,
    required this.totalWishlistSaves,
    required this.averageRating,
    required this.dauTrend,
    required this.searchesTrend,
    required this.viewsTrend,
    required this.chatMessagesTrend,
    required this.ratingDistribution,
  });

  factory EngagementAnalytics.fromJson(Map<String, dynamic> json) {
    List<ChartPoint> parse(String key) => (json[key] as List? ?? [])
        .map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return EngagementAnalytics(
      dailyActiveUsers: json['dailyActiveUsers'] ?? 0,
      weeklyActiveUsers: json['weeklyActiveUsers'] ?? 0,
      monthlyActiveUsers: json['monthlyActiveUsers'] ?? 0,
      dauMauRatio: (json['dauMauRatio'] ?? 0).toDouble(),
      totalSearches: json['totalSearches'] ?? 0,
      totalPropertyViews: json['totalPropertyViews'] ?? 0,
      totalChatMessages: json['totalChatMessages'] ?? 0,
      totalReviews: json['totalReviews'] ?? 0,
      totalWishlistSaves: json['totalWishlistSaves'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      dauTrend: parse('dauTrend'),
      searchesTrend: parse('searchesTrend'),
      viewsTrend: parse('viewsTrend'),
      chatMessagesTrend: parse('chatMessagesTrend'),
      ratingDistribution: parse('ratingDistribution'),
    );
  }
}