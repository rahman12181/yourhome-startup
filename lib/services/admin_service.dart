import 'package:dio/dio.dart';
import 'package:yourhome/models/property_model.dart';
import '../models/admin_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _api = ApiService();

  // ============== 10.1 GET PENDING OWNERS ==============
  Future<ApiResponse<List<PendingOwner>>> getPendingOwners() async {
    try {
      final response = await _api.get('/admin/owners/pending');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final owners = data.map((item) => PendingOwner.fromJson(item)).toList();
        return ApiResponse<List<PendingOwner>>(
          success: true,
          message: response.data['message'] ?? 'Pending owners fetched',
          data: owners,
        );
      } else {
        return ApiResponse<List<PendingOwner>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch pending owners',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<PendingOwner>>.fromJson(
          e.response!.data,
          (data) => (data as List)
              .map((item) => PendingOwner.fromJson(item))
              .toList(),
        );
      }
      return ApiResponse<List<PendingOwner>>.error(
          e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<PendingOwner>>.error(e.toString());
    }
  }

  // ============== 10.2 GET ALL OWNERS ==============
  Future<ApiResponse<List<PendingOwner>>> getAllOwners() async {
    try {
      final response = await _api.get('/admin/owners/all');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final owners = data.map((item) => PendingOwner.fromJson(item)).toList();
        return ApiResponse<List<PendingOwner>>(
          success: true,
          message: response.data['message'] ?? 'All owners fetched',
          data: owners,
        );
      } else {
        return ApiResponse<List<PendingOwner>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch owners',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<PendingOwner>>.fromJson(
          e.response!.data,
          (data) => (data as List)
              .map((item) => PendingOwner.fromJson(item))
              .toList(),
        );
      }
      return ApiResponse<List<PendingOwner>>.error(
          e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<PendingOwner>>.error(e.toString());
    }
  }

  // ============== 10.3 VERIFY OWNER ==============
  Future<ApiResponse<void>> verifyOwner(int ownerId) async {
    try {
      final response = await _api.patch('/admin/owners/$ownerId/verify');
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

  // ============== 10.4 REJECT OWNER ==============
  Future<ApiResponse<void>> rejectOwner(int ownerId, String reason) async {
    try {
      final response = await _api.patch(
        '/admin/owners/$ownerId/reject',
        data: {'reason': reason},
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

  // ============== 10.5 GET PENDING PROPERTIES ==============
  Future<ApiResponse<List<PendingProperty>>> getPendingProperties() async {
    try {
      final response = await _api.get('/admin/properties/pending');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final properties =
            data.map((item) => PendingProperty.fromJson(item)).toList();
        return ApiResponse<List<PendingProperty>>(
          success: true,
          message: response.data['message'] ?? 'Pending properties fetched',
          data: properties,
        );
      } else {
        return ApiResponse<List<PendingProperty>>(
          success: false,
          message:
              response.data['message'] ?? 'Failed to fetch pending properties',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<PendingProperty>>.fromJson(
          e.response!.data,
          (data) => (data as List)
              .map((item) => PendingProperty.fromJson(item))
              .toList(),
        );
      }
      return ApiResponse<List<PendingProperty>>.error(
          e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<PendingProperty>>.error(e.toString());
    }
  }

  // ============== 10.6 PUBLISH PROPERTY ==============
  Future<ApiResponse<void>> publishProperty(int propertyId) async {
    try {
      final response =
          await _api.patch('/admin/properties/$propertyId/publish');
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

  // ============== 10.7 UNPUBLISH PROPERTY ==============
  Future<ApiResponse<void>> unpublishProperty(int propertyId) async {
    try {
      final response =
          await _api.patch('/admin/properties/$propertyId/unpublish');
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

  // ============== 10.8 GET ALL USERS ==============
  Future<ApiResponse<List<AdminUser>>> getAllUsers() async {
    try {
      final response = await _api.get('/admin/users');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final users = data.map((item) => AdminUser.fromJson(item)).toList();
        return ApiResponse<List<AdminUser>>(
          success: true,
          message: response.data['message'] ?? 'Users fetched',
          data: users,
        );
      } else {
        return ApiResponse<List<AdminUser>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch users',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<AdminUser>>.fromJson(
          e.response!.data,
          (data) =>
              (data as List).map((item) => AdminUser.fromJson(item)).toList(),
        );
      }
      return ApiResponse<List<AdminUser>>.error(
          e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<AdminUser>>.error(e.toString());
    }
  }

  // ============== 10.9 DEACTIVATE USER ==============
  Future<ApiResponse<void>> deactivateUser(int userId) async {
    try {
      final response = await _api.patch('/admin/users/$userId/deactivate');
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

  // ============== 10.10 ACTIVATE USER ==============
  Future<ApiResponse<void>> activateUser(int userId) async {
    try {
      final response = await _api.patch('/admin/users/$userId/activate');
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

  // ============== 10.11 ADMIN DASHBOARD STATS ==============
  Future<ApiResponse<AdminDashboardStats>> getDashboardStats() async {
    try {
      final response = await _api.get('/admin/dashboard/stats');
      return ApiResponse<AdminDashboardStats>.fromJson(
        response.data,
        (data) => AdminDashboardStats.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<AdminDashboardStats>.fromJson(
          e.response!.data,
          (data) => AdminDashboardStats.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<AdminDashboardStats>.error(
          e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<AdminDashboardStats>.error(e.toString());
    }
  }

  // ============== 10.12 GET PENDING REPORTS ==============
  Future<ApiResponse<List<AdminReport>>> getPendingReports() async {
    try {
      final response = await _api.get('/admin/reports');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final reports = data.map((item) => AdminReport.fromJson(item)).toList();
        return ApiResponse<List<AdminReport>>(
          success: true,
          message: response.data['message'] ?? 'Reports fetched',
          data: reports,
        );
      } else {
        return ApiResponse<List<AdminReport>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch reports',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<AdminReport>>.fromJson(
          e.response!.data,
          (data) =>
              (data as List).map((item) => AdminReport.fromJson(item)).toList(),
        );
      }
      return ApiResponse<List<AdminReport>>.error(
          e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<AdminReport>>.error(e.toString());
    }
  }

  // ============== 10.13 RESOLVE REPORT ==============
  Future<ApiResponse<void>> resolveReport(int reportId) async {
    try {
      final response = await _api.patch('/admin/reports/$reportId/resolve');
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

  // ============== 10.14 GET PROPERTY DETAIL (ADMIN) ==============
  Future<ApiResponse<Property>> getPropertyDetailAdmin(int propertyId) async {
    try {
      final response = await _api.get('/admin/properties/$propertyId/detail');
      return ApiResponse<Property>.fromJson(
        response.data,
        (data) => Property.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Property>.fromJson(
          e.response!.data,
          (data) => Property.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<Property>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Property>.error(e.toString());
    }
  }

  // ============== 10.15 GET ALL PROPERTIES (ADMIN) ==============
  Future<ApiResponse<List<Property>>> getAllPropertiesAdmin() async {
    try {
      final response = await _api.get('/admin/properties/all');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final properties = data.map((item) => Property.fromJson(item)).toList();
        return ApiResponse<List<Property>>(
          success: true,
          message: response.data['message'] ?? 'Properties fetched',
          data: properties,
        );
      } else {
        return ApiResponse<List<Property>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch properties',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<Property>>.fromJson(
          e.response!.data,
          (data) =>
              (data as List).map((item) => Property.fromJson(item)).toList(),
        );
      }
      return ApiResponse<List<Property>>.error(
          e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<Property>>.error(e.toString());
    }
  }

  Future<ApiResponse<OwnerDetail>> getOwnerDetail(int ownerId) async {
    try {
      final response = await _api.get('/admin/owners/$ownerId/detail');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        return ApiResponse<OwnerDetail>(
          success: true,
          message: response.data['message'] ?? 'Owner detail fetched',
          data: OwnerDetail.fromJson(data),
        );
      } else {
        return ApiResponse<OwnerDetail>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch owner detail',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<OwnerDetail>.fromJson(
          e.response!.data,
          (data) => OwnerDetail.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<OwnerDetail>.error(
          e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<OwnerDetail>.error(e.toString());
    }
  }

  // ============== 10.16 GET PROPERTY ACCESS SUBSCRIPTIONS ==============
  Future<ApiResponse<List<AdminPropertyAccessSubscription>>>
      getPropertyAccessSubscriptions({
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _api.get(
        '/admin/property-access-subscriptions',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final subscriptions = data
            .map((item) => AdminPropertyAccessSubscription.fromJson(item))
            .toList();
        return ApiResponse<List<AdminPropertyAccessSubscription>>(
          success: true,
          message: response.data['message'] ?? 'Subscriptions fetched',
          data: subscriptions,
        );
      } else {
        return ApiResponse<List<AdminPropertyAccessSubscription>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch subscriptions',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<AdminPropertyAccessSubscription>>.fromJson(
          e.response!.data,
          (data) => (data as List)
              .map((item) => AdminPropertyAccessSubscription.fromJson(item))
              .toList(),
        );
      }
      return ApiResponse<List<AdminPropertyAccessSubscription>>.error(
          e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<AdminPropertyAccessSubscription>>.error(
          e.toString());
    }
  }

  // ============== 10.17 FORCE EXPIRE SUBSCRIPTION ==============
  Future<ApiResponse<void>> forceExpireSubscription(
      int subscriptionId, String reason) async {
    try {
      final response = await _api.patch(
        '/admin/property-access-subscriptions/$subscriptionId/expire',
        data: {'reason': reason},
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
}
