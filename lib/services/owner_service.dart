import 'package:dio/dio.dart';
import '../models/owner_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class OwnerService {
  final ApiService _api = ApiService();

  // 3.1 Apply as Owner
  Future<ApiResponse<void>> applyAsOwner(FormData formData) async {
    try {
      final response = await _api.upload('/owner/apply', formData);
      return ApiResponse<void>.fromJson(
        response.data,
        (data) => null,
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<void>.fromJson(
          e.response!.data,
          (data) => null,
        );
      }
      return ApiResponse<void>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }

  // 3.2 Get My Owner Profile
  Future<ApiResponse<OwnerProfile>> getOwnerProfile() async {
    try {
      final response = await _api.get('/owner/my-profile');
      return ApiResponse<OwnerProfile>.fromJson(
        response.data,
        (data) => OwnerProfile.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<OwnerProfile>.fromJson(
          e.response!.data,
          (data) => OwnerProfile.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<OwnerProfile>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<OwnerProfile>.error(e.toString());
    }
  }

  // 3.3 Get Verification Status
  Future<ApiResponse<VerificationStatus>> getVerificationStatus() async {
    try {
      final response = await _api.get('/owner/verification-status');
      return ApiResponse<VerificationStatus>.fromJson(
        response.data,
        (data) => VerificationStatus.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<VerificationStatus>.fromJson(
          e.response!.data,
          (data) => VerificationStatus.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<VerificationStatus>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<VerificationStatus>.error(e.toString());
    }
  }

  // 3.4 Buy Listing Subscription
  Future<ApiResponse<SubscriptionOrder>> buyListingSubscription(String plan) async {
    try {
      final response = await _api.post(
        '/owner/subscription/buy',
        data: {'plan': plan},
      );
      return ApiResponse<SubscriptionOrder>.fromJson(
        response.data,
        (data) => SubscriptionOrder.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<SubscriptionOrder>.fromJson(
          e.response!.data,
          (data) => SubscriptionOrder.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<SubscriptionOrder>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<SubscriptionOrder>.error(e.toString());
    }
  }

  // 3.5 Confirm Listing Subscription Payment
  Future<ApiResponse<SubscriptionDetails>> confirmListingSubscription({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String plan,
  }) async {
    try {
      final response = await _api.post(
        '/owner/subscription/confirm',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
          'plan': plan,
        },
      );
      return ApiResponse<SubscriptionDetails>.fromJson(
        response.data,
        (data) => SubscriptionDetails.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<SubscriptionDetails>.fromJson(
          e.response!.data,
          (data) => SubscriptionDetails.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<SubscriptionDetails>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<SubscriptionDetails>.error(e.toString());
    }
  }

  // 3.6 Get Listing Subscription Details
  Future<ApiResponse<SubscriptionDetails>> getListingSubscriptionDetails() async {
    try {
      final response = await _api.get('/owner/subscription/details');
      return ApiResponse<SubscriptionDetails>.fromJson(
        response.data,
        (data) => SubscriptionDetails.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<SubscriptionDetails>.fromJson(
          e.response!.data,
          (data) => SubscriptionDetails.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<SubscriptionDetails>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<SubscriptionDetails>.error(e.toString());
    }
  }

  // 3.7 Owner Dashboard Stats
  Future<ApiResponse<DashboardStats>> getDashboardStats() async {
    try {
      final response = await _api.get('/owner/dashboard');
      return ApiResponse<DashboardStats>.fromJson(
        response.data,
        (data) => DashboardStats.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<DashboardStats>.fromJson(
          e.response!.data,
          (data) => DashboardStats.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<DashboardStats>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<DashboardStats>.error(e.toString());
    }
  }

  // 3.8 Buy Featured Listing
  Future<ApiResponse<void>> buyFeaturedListing(int propertyId, int days) async {
    try {
      final response = await _api.post(
        '/owner/properties/$propertyId/feature?days=$days',
      );
      return ApiResponse<void>.fromJson(
        response.data,
        (data) => null,
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<void>.fromJson(
          e.response!.data,
          (data) => null,
        );
      }
      return ApiResponse<void>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }

  // 11.1 Buy Property Access Subscription
  Future<ApiResponse<SubscriptionOrder>> buyPropertyAccessSubscription(String plan) async {
    try {
      final response = await _api.post(
        '/owner/property-access/buy',
        data: {'plan': plan},
      );
      return ApiResponse<SubscriptionOrder>.fromJson(
        response.data,
        (data) => SubscriptionOrder.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<SubscriptionOrder>.fromJson(
          e.response!.data,
          (data) => SubscriptionOrder.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<SubscriptionOrder>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<SubscriptionOrder>.error(e.toString());
    }
  }

  // 11.2 Confirm Property Access Payment
  Future<ApiResponse<PropertyAccessSubscription>> confirmPropertyAccessSubscription({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String plan,
  }) async {
    try {
      final response = await _api.post(
        '/owner/property-access/confirm',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
          'plan': plan,
        },
      );
      return ApiResponse<PropertyAccessSubscription>.fromJson(
        response.data,
        (data) => PropertyAccessSubscription.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<PropertyAccessSubscription>.fromJson(
          e.response!.data,
          (data) => PropertyAccessSubscription.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<PropertyAccessSubscription>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<PropertyAccessSubscription>.error(e.toString());
    }
  }

  // 11.3 Get Property Access Subscription Status
  Future<ApiResponse<PropertyAccessStatus>> getPropertyAccessStatus() async {
    try {
      final response = await _api.get('/owner/property-access/status');
      return ApiResponse<PropertyAccessStatus>.fromJson(
        response.data,
        (data) => PropertyAccessStatus.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<PropertyAccessStatus>.fromJson(
          e.response!.data,
          (data) => PropertyAccessStatus.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<PropertyAccessStatus>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<PropertyAccessStatus>.error(e.toString());
    }
  }

  // 11.4 Get Property Access Subscription History
  Future<ApiResponse<List<PropertyAccessSubscription>>> getPropertyAccessHistory() async {
    try {
      final response = await _api.get('/owner/property-access/history');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final history = data.map((item) => PropertyAccessSubscription.fromJson(item)).toList();
        return ApiResponse<List<PropertyAccessSubscription>>(
          success: true,
          message: response.data['message'] ?? '',
          data: history,
        );
      } else {
        return ApiResponse<List<PropertyAccessSubscription>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch history',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<PropertyAccessSubscription>>.fromJson(
          e.response!.data,
          (data) => (data as List).map((item) => PropertyAccessSubscription.fromJson(item)).toList(),
        );
      }
      return ApiResponse<List<PropertyAccessSubscription>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<PropertyAccessSubscription>>.error(e.toString());
    }
  }

  // 11.5 Renew Property Access Subscription
  Future<ApiResponse<SubscriptionOrder>> renewPropertyAccessSubscription(String plan) async {
    try {
      final response = await _api.post(
        '/owner/property-access/renew',
        data: {'plan': plan},
      );
      return ApiResponse<SubscriptionOrder>.fromJson(
        response.data,
        (data) => SubscriptionOrder.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<SubscriptionOrder>.fromJson(
          e.response!.data,
          (data) => SubscriptionOrder.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<SubscriptionOrder>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<SubscriptionOrder>.error(e.toString());
    }
  }
}