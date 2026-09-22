// lib/models/booking_stats_model.dart

class BookingStats {
  final int todayNew;
  final int todayAccepted;
  final int todayRejected;
  final int totalPending;
  final int urgentPending;
  final int totalBookings;
  final int totalAccepted;
  final int totalRejected;
  final double acceptanceRate;
  final double avgResponseHours;
  final int avgResponseMinutes;
  final int thisWeekBookings;
  final int lastWeekBookings;
  final double weeklyGrowthPercent;
  final int thisMonthBookings;
  final int unreadBookingCount;

  BookingStats({
    this.todayNew = 0,
    this.todayAccepted = 0,
    this.todayRejected = 0,
    this.totalPending = 0,
    this.urgentPending = 0,
    this.totalBookings = 0,
    this.totalAccepted = 0,
    this.totalRejected = 0,
    this.acceptanceRate = 0,
    this.avgResponseHours = 0,
    this.avgResponseMinutes = 0,
    this.thisWeekBookings = 0,
    this.lastWeekBookings = 0,
    this.weeklyGrowthPercent = 0,
    this.thisMonthBookings = 0,
    this.unreadBookingCount = 0,
  });

  factory BookingStats.fromJson(Map<String, dynamic> json) {
    return BookingStats(
      todayNew: _int(json['todayNew']),
      todayAccepted: _int(json['todayAccepted']),
      todayRejected: _int(json['todayRejected']),
      totalPending: _int(json['totalPending']),
      urgentPending: _int(json['urgentPending']),
      totalBookings: _int(json['totalBookings']),
      totalAccepted: _int(json['totalAccepted']),
      totalRejected: _int(json['totalRejected']),
      acceptanceRate: _double(json['acceptanceRate']),
      avgResponseHours: _double(json['avgResponseHours']),
      avgResponseMinutes: _int(json['avgResponseMinutes']),
      thisWeekBookings: _int(json['thisWeekBookings']),
      lastWeekBookings: _int(json['lastWeekBookings']),
      weeklyGrowthPercent: _double(json['weeklyGrowthPercent']),
      thisMonthBookings: _int(json['thisMonthBookings']),
      unreadBookingCount: _int(json['unreadBookingCount']),
    );
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _double(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

// ============================================
// TIMELINE EVENT
// ============================================
class BookingTimelineEvent {
  final String eventType;
  final String title;
  final String description;
  final DateTime? timestamp;
  final String icon;
  final String color;

  BookingTimelineEvent({
    required this.eventType,
    required this.title,
    required this.description,
    this.timestamp,
    this.icon = 'info',
    this.color = '#8A8FA3',
  });

  factory BookingTimelineEvent.fromJson(Map<String, dynamic> json) {
    return BookingTimelineEvent(
      eventType: json['eventType']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      icon: json['icon']?.toString() ?? 'info',
      color: json['color']?.toString() ?? '#8A8FA3',
    );
  }
}