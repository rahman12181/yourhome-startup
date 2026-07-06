import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();

  UserProfile? _profile;
  List<BookingRequest> _bookings = [];
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  UserProfile? get profile => _profile;
  List<BookingRequest> get bookings => _bookings;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ============== GET PROFILE ==============
  Future<bool> getProfile() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getProfile();
      if (_isDisposed) return false;

      if (response.success && response.data != null) {
        _profile = response.data;
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== UPDATE PROFILE ==============
  Future<bool> updateProfile(UpdateProfileRequest request) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.updateProfile(request);
      if (_isDisposed) return false;

      if (response.success && response.data != null) {
        _profile = response.data;
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== UPLOAD PROFILE PICTURE ==============
  Future<bool> uploadProfilePicture(FormData formData) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.uploadProfilePicture(formData);
      if (_isDisposed) return false;

      if (response.success && response.data != null) {
        _profile = response.data;
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== CHANGE PASSWORD ==============
  Future<bool> changePassword(ChangePasswordRequest request) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.changePassword(request);
      if (_isDisposed) return false;

      if (response.success) {
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== GET MY BOOKINGS ==============
  Future<bool> getMyBookings() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getMyBookings();
      if (_isDisposed) return false;

      if (response.success) {
        _bookings = response.data ?? [];
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== CANCEL BOOKING ==============
  Future<bool> cancelBooking(int requestId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.cancelBooking(requestId);
      if (_isDisposed) return false;

      if (response.success) {
        await getMyBookings();
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== GET NOTIFICATIONS ==============
  Future<bool> getNotifications() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getNotifications();
      if (_isDisposed) return false;

      if (response.success) {
        _notifications = response.data ?? [];
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== GET UNREAD COUNT ==============
  Future<bool> getUnreadCount() async {
    if (_isDisposed) return false;

    try {
      final response = await _service.getUnreadCount();
      if (_isDisposed) return false;

      if (response.success && response.data != null) {
        _unreadCount = response.data!.unreadCount;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============== MARK AS READ ==============
  Future<bool> markAsRead(int notificationId) async {
    if (_isDisposed) return false;

    try {
      final response = await _service.markNotificationAsRead(notificationId);
      if (_isDisposed) return false;

      if (response.success) {
        await getUnreadCount();
        await getNotifications();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============== MARK ALL AS READ ==============
  Future<bool> markAllAsRead() async {
    if (_isDisposed) return false;

    try {
      final response = await _service.markAllAsRead();
      if (_isDisposed) return false;

      if (response.success) {
        _unreadCount = 0;
        await getNotifications();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============== LOAD ALL PROFILE DATA ==============
  Future<void> loadAllData() async {
    if (_isDisposed) return;
    _setLoading(true);
    _clearError();

    try {
      await getProfile();
      await getMyBookings();
      await getUnreadCount();
      await getNotifications();
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  void _setLoading(bool loading) {
    if (!_isDisposed && _isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _clearError() {
    if (!_isDisposed && _error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void clearError() {
    if (!_isDisposed) {
      _error = null;
      notifyListeners();
    }
  }

  void reset() {
    if (!_isDisposed) {
      _profile = null;
      _bookings = [];
      _notifications = [];
      _unreadCount = 0;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }
}