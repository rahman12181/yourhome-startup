class NotificationModel {
  final int notificationId;
  final String title;
  final String body;
  final String type;
  final int? refId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    this.refId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'SYSTEM',
      refId: json['refId'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class UnreadCount {
  final int unreadCount;

  UnreadCount({required this.unreadCount});

  factory UnreadCount.fromJson(Map<String, dynamic> json) {
    return UnreadCount(
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}