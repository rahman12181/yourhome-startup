// lib/models/dashboard_model.dart

class DashboardSummary {
  final RevenueSummary? revenue;
  final ActionRequired? actionsRequired;
  final RecentActivity? recentActivity;
  final OccupancyData? occupancy;
  final TrendsData? trends;
  final TopProperty? topProperty;
  final TodaySchedule? todaySchedule;
  final int unreadMessages;
  final int unreadNotifications;

  DashboardSummary({
    this.revenue,
    this.actionsRequired,
    this.recentActivity,
    this.occupancy,
    this.trends,
    this.topProperty,
    this.todaySchedule,
    this.unreadMessages = 0,
    this.unreadNotifications = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) {
    return DashboardSummary(
      revenue: j['revenue'] != null
          ? RevenueSummary.fromJson(j['revenue'])
          : null,
      actionsRequired: j['actionsRequired'] != null
          ? ActionRequired.fromJson(j['actionsRequired'])
          : null,
      recentActivity: j['recentActivity'] != null
          ? RecentActivity.fromJson(j['recentActivity'])
          : null,
      occupancy: j['occupancy'] != null
          ? OccupancyData.fromJson(j['occupancy'])
          : null,
      trends: j['trends'] != null ? TrendsData.fromJson(j['trends']) : null,
      topProperty: j['topProperty'] != null
          ? TopProperty.fromJson(j['topProperty'])
          : null,
      todaySchedule: j['todaySchedule'] != null
          ? TodaySchedule.fromJson(j['todaySchedule'])
          : null,
      unreadMessages: _int(j['unreadMessages']),
      unreadNotifications: _int(j['unreadNotifications']),
    );
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

// ============================================
// REVENUE
// ============================================
class RevenueSummary {
  final double thisMonthTotal;
  final double lastMonthTotal;
  final double growthPercent;
  final double paidAmount;
  final double pendingAmount;
  final double collectionRate;
  final double payoutsCompleted;
  final double payoutsPending;
  final double thisYearTotal;
  final int totalTransactions;
  final List<MonthlyRevenue> monthlyTrend;
  final List<DailyRevenue> dailyTrend;

  RevenueSummary({
    this.thisMonthTotal = 0,
    this.lastMonthTotal = 0,
    this.growthPercent = 0,
    this.paidAmount = 0,
    this.pendingAmount = 0,
    this.collectionRate = 0,
    this.payoutsCompleted = 0,
    this.payoutsPending = 0,
    this.thisYearTotal = 0,
    this.totalTransactions = 0,
    this.monthlyTrend = const [],
    this.dailyTrend = const [],
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> j) {
    return RevenueSummary(
      thisMonthTotal: _d(j['thisMonthTotal']),
      lastMonthTotal: _d(j['lastMonthTotal']),
      growthPercent: _d(j['growthPercent']),
      paidAmount: _d(j['paidAmount']),
      pendingAmount: _d(j['pendingAmount']),
      collectionRate: _d(j['collectionRate']),
      payoutsCompleted: _d(j['payoutsCompleted']),
      payoutsPending: _d(j['payoutsPending']),
      thisYearTotal: _d(j['thisYearTotal']),
      totalTransactions: DashboardSummary._int(j['totalTransactions']),
      monthlyTrend: (j['monthlyTrend'] as List?)
              ?.map((e) => MonthlyRevenue.fromJson(e))
              .toList() ??
          [],
      dailyTrend: (j['dailyTrend'] as List?)
              ?.map((e) => DailyRevenue.fromJson(e))
              .toList() ??
          [],
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class MonthlyRevenue {
  final String month;
  final int year;
  final double amount;
  final int transactions;

  MonthlyRevenue({
    required this.month,
    required this.year,
    required this.amount,
    required this.transactions,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> j) => MonthlyRevenue(
        month: j['month']?.toString() ?? '',
        year: DashboardSummary._int(j['year']),
        amount: RevenueSummary._d(j['amount']),
        transactions: DashboardSummary._int(j['transactions']),
      );
}

class DailyRevenue {
  final String date;
  final double amount;

  DailyRevenue({required this.date, required this.amount});

  factory DailyRevenue.fromJson(Map<String, dynamic> j) => DailyRevenue(
        date: j['date']?.toString() ?? '',
        amount: RevenueSummary._d(j['amount']),
      );
}

// ============================================
// ACTIONS REQUIRED
// ============================================
class ActionRequired {
  final int totalActions;
  final List<ActionItem> items;

  ActionRequired({this.totalActions = 0, this.items = const []});

  factory ActionRequired.fromJson(Map<String, dynamic> j) => ActionRequired(
        totalActions: DashboardSummary._int(j['totalActions']),
        items: (j['items'] as List?)
                ?.map((e) => ActionItem.fromJson(e))
                .toList() ??
            [],
      );
}

class ActionItem {
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

  ActionItem({
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

  factory ActionItem.fromJson(Map<String, dynamic> j) => ActionItem(
        id: j['id']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        priority: j['priority']?.toString() ?? 'LOW',
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        actionLabel: j['actionLabel']?.toString() ?? 'View',
        actionRoute: j['actionRoute']?.toString() ?? '',
        icon: j['icon']?.toString() ?? 'info',
        color: j['color']?.toString() ?? '#7C3AED',
        referenceId: j['referenceId'] != null
            ? DashboardSummary._int(j['referenceId'])
            : null,
        count: j['count'] != null ? DashboardSummary._int(j['count']) : null,
      );
}

// ============================================
// RECENT ACTIVITY
// ============================================
class RecentActivity {
  final List<ActivityItem> activities;

  RecentActivity({this.activities = const []});

  factory RecentActivity.fromJson(Map<String, dynamic> j) => RecentActivity(
        activities: (j['activities'] as List?)
                ?.map((e) => ActivityItem.fromJson(e))
                .toList() ??
            [],
      );
}

class ActivityItem {
  final int id;
  final String activityType;
  final String title;
  final String description;
  final String icon;
  final String color;
  final int? referenceId;
  final String referenceType;
  final DateTime? createdAt;
  final String timeAgo;

  ActivityItem({
    required this.id,
    required this.activityType,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.referenceId,
    this.referenceType = '',
    this.createdAt,
    this.timeAgo = '',
  });

  factory ActivityItem.fromJson(Map<String, dynamic> j) => ActivityItem(
        id: DashboardSummary._int(j['id']),
        activityType: j['activityType']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        icon: j['icon']?.toString() ?? 'info',
        color: j['color']?.toString() ?? '#7C3AED',
        referenceId: j['referenceId'] != null
            ? DashboardSummary._int(j['referenceId'])
            : null,
        referenceType: j['referenceType']?.toString() ?? '',
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
        timeAgo: j['timeAgo']?.toString() ?? '',
      );
}

// ============================================
// OCCUPANCY
// ============================================
class OccupancyData {
  final int totalRooms;
  final int occupiedRooms;
  final int availableRooms;
  final int maintenanceRooms;
  final double occupancyRate;
  final String occupancyLabel;
  final double lastWeekRate;
  final double changeFromLastWeek;
  final List<PropertyOccupancy> byProperty;

  OccupancyData({
    this.totalRooms = 0,
    this.occupiedRooms = 0,
    this.availableRooms = 0,
    this.maintenanceRooms = 0,
    this.occupancyRate = 0,
    this.occupancyLabel = '',
    this.lastWeekRate = 0,
    this.changeFromLastWeek = 0,
    this.byProperty = const [],
  });

  factory OccupancyData.fromJson(Map<String, dynamic> j) => OccupancyData(
        totalRooms: DashboardSummary._int(j['totalRooms']),
        occupiedRooms: DashboardSummary._int(j['occupiedRooms']),
        availableRooms: DashboardSummary._int(j['availableRooms']),
        maintenanceRooms: DashboardSummary._int(j['maintenanceRooms']),
        occupancyRate: RevenueSummary._d(j['occupancyRate']),
        occupancyLabel: j['occupancyLabel']?.toString() ?? '',
        lastWeekRate: RevenueSummary._d(j['lastWeekRate']),
        changeFromLastWeek: RevenueSummary._d(j['changeFromLastWeek']),
        byProperty: (j['byProperty'] as List?)
                ?.map((e) => PropertyOccupancy.fromJson(e))
                .toList() ??
            [],
      );
}

class PropertyOccupancy {
  final int propertyId;
  final String propertyTitle;
  final int totalRooms;
  final int occupiedRooms;
  final int availableRooms;
  final double occupancyRate;
  final String color;

  PropertyOccupancy({
    required this.propertyId,
    required this.propertyTitle,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.availableRooms,
    required this.occupancyRate,
    required this.color,
  });

  factory PropertyOccupancy.fromJson(Map<String, dynamic> j) =>
      PropertyOccupancy(
        propertyId: DashboardSummary._int(j['propertyId']),
        propertyTitle: j['propertyTitle']?.toString() ?? '',
        totalRooms: DashboardSummary._int(j['totalRooms']),
        occupiedRooms: DashboardSummary._int(j['occupiedRooms']),
        availableRooms: DashboardSummary._int(j['availableRooms']),
        occupancyRate: RevenueSummary._d(j['occupancyRate']),
        color: j['color']?.toString() ?? '#7C3AED',
      );
}

// ============================================
// TRENDS
// ============================================
class TrendsData {
  final List<DailyPoint> bookingsTrend;
  final int totalThisWeek;
  final int totalLastWeek;
  final double growthPercent;
  final List<DailyPoint> viewsTrend;
  final int totalViewsThisWeek;

  TrendsData({
    this.bookingsTrend = const [],
    this.totalThisWeek = 0,
    this.totalLastWeek = 0,
    this.growthPercent = 0,
    this.viewsTrend = const [],
    this.totalViewsThisWeek = 0,
  });

  factory TrendsData.fromJson(Map<String, dynamic> j) => TrendsData(
        bookingsTrend: (j['bookingsTrend'] as List?)
                ?.map((e) => DailyPoint.fromJson(e))
                .toList() ??
            [],
        totalThisWeek: DashboardSummary._int(j['totalThisWeek']),
        totalLastWeek: DashboardSummary._int(j['totalLastWeek']),
        growthPercent: RevenueSummary._d(j['growthPercent']),
        viewsTrend: (j['viewsTrend'] as List?)
                ?.map((e) => DailyPoint.fromJson(e))
                .toList() ??
            [],
        totalViewsThisWeek: DashboardSummary._int(j['totalViewsThisWeek']),
      );
}

class DailyPoint {
  final String day;
  final String date;
  final int value;
  final int accepted;
  final int rejected;

  DailyPoint({
    required this.day,
    required this.date,
    required this.value,
    this.accepted = 0,
    this.rejected = 0,
  });

  factory DailyPoint.fromJson(Map<String, dynamic> j) => DailyPoint(
        day: j['day']?.toString() ?? '',
        date: j['date']?.toString() ?? '',
        value: DashboardSummary._int(j['value']),
        accepted: DashboardSummary._int(j['accepted']),
        rejected: DashboardSummary._int(j['rejected']),
      );
}

// ============================================
// TOP PROPERTY
// ============================================
class TopProperty {
  final int propertyId;
  final String title;
  final String city;
  final String? coverImage;
  final double revenueThisMonth;
  final int bookingsThisMonth;
  final double averageRating;
  final int totalReviews;
  final int viewCount;
  final double occupancyRate;
  final int availableRooms;
  final int totalRooms;
  final String topReason;
  final String rankBadge;

  TopProperty({
    required this.propertyId,
    required this.title,
    required this.city,
    this.coverImage,
    this.revenueThisMonth = 0,
    this.bookingsThisMonth = 0,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.viewCount = 0,
    this.occupancyRate = 0,
    this.availableRooms = 0,
    this.totalRooms = 0,
    this.topReason = '',
    this.rankBadge = '',
  });

  factory TopProperty.fromJson(Map<String, dynamic> j) => TopProperty(
        propertyId: DashboardSummary._int(j['propertyId']),
        title: j['title']?.toString() ?? '',
        city: j['city']?.toString() ?? '',
        coverImage: j['coverImage']?.toString(),
        revenueThisMonth: RevenueSummary._d(j['revenueThisMonth']),
        bookingsThisMonth: DashboardSummary._int(j['bookingsThisMonth']),
        averageRating: RevenueSummary._d(j['averageRating']),
        totalReviews: DashboardSummary._int(j['totalReviews']),
        viewCount: DashboardSummary._int(j['viewCount']),
        occupancyRate: RevenueSummary._d(j['occupancyRate']),
        availableRooms: DashboardSummary._int(j['availableRooms']),
        totalRooms: DashboardSummary._int(j['totalRooms']),
        topReason: j['topReason']?.toString() ?? '',
        rankBadge: j['rankBadge']?.toString() ?? '',
      );
}

// ============================================
// TODAY SCHEDULE
// ============================================
class TodaySchedule {
  final String date;
  final int totalEvents;
  final List<ScheduleItem> events;

  TodaySchedule({
    this.date = '',
    this.totalEvents = 0,
    this.events = const [],
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> j) => TodaySchedule(
        date: j['date']?.toString() ?? '',
        totalEvents: DashboardSummary._int(j['totalEvents']),
        events: (j['events'] as List?)
                ?.map((e) => ScheduleItem.fromJson(e))
                .toList() ??
            [],
      );
}

class ScheduleItem {
  final int id;
  final String eventType;
  final String title;
  final String description;
  final DateTime? scheduledAt;
  final String timeLabel;
  final String icon;
  final String color;
  final int? referenceId;
  final String referenceType;

  ScheduleItem({
    required this.id,
    required this.eventType,
    required this.title,
    required this.description,
    this.scheduledAt,
    required this.timeLabel,
    required this.icon,
    required this.color,
    this.referenceId,
    this.referenceType = '',
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
        id: DashboardSummary._int(j['id']),
        eventType: j['eventType']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        scheduledAt: j['scheduledAt'] != null
            ? DateTime.tryParse(j['scheduledAt'].toString())
            : null,
        timeLabel: j['timeLabel']?.toString() ?? '',
        icon: j['icon']?.toString() ?? 'event',
        color: j['color']?.toString() ?? '#7C3AED',
        referenceId: j['referenceId'] != null
            ? DashboardSummary._int(j['referenceId'])
            : null,
        referenceType: j['referenceType']?.toString() ?? '',
      );
}