// lib/providers/notification_provider.dart

import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  bool _isDisposed = false;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _service.getUnreadCount();
      if (_isDisposed) return;
      if (response.success && response.data != null) {
        _unreadCount = response.data!.unreadCount;
        notifyListeners();
      }
    } catch (_) {}
  }

  void reset() {
    _unreadCount = 0;
    notifyListeners();
  }
}