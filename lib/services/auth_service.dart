import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<ApiResponse<AuthData>> register(RegisterRequest request) async {
    try {
      final response = await _api.post(
        '/auth/register',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse<AuthData>.fromJson(
        response.data,
        (data) => AuthData.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<AuthData>.fromJson(
          e.response!.data,
          (data) => AuthData.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<AuthData>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<AuthData>.error(e.toString());
    }
  }

  Future<ApiResponse<AuthData>> verifyOtp(VerifyOtpRequest request) async {
    try {
      final response = await _api.post(
        '/auth/verify-otp',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse<AuthData>.fromJson(
        response.data,
        (data) => AuthData.fromJson(data as Map<String, dynamic>),
      );
      
      // Save tokens if login successful
      if (apiResponse.success && apiResponse.data != null) {
        await _storage.saveTokens(
          apiResponse.data!.accessToken,
          apiResponse.data!.refreshToken,
        );
        await _storage.setUserId(apiResponse.data!.userId);
        await _storage.setUserRole(apiResponse.data!.role);
        await _storage.setLoggedIn(true);
      }
      
      return apiResponse;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<AuthData>.fromJson(
          e.response!.data,
          (data) => AuthData.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<AuthData>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<AuthData>.error(e.toString());
    }
  }

  Future<ApiResponse<AuthData>> login(LoginRequest request) async {
    try {
      final response = await _api.post(
        '/auth/login',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse<AuthData>.fromJson(
        response.data,
        (data) => AuthData.fromJson(data as Map<String, dynamic>),
      );
      
      // Save tokens if login successful
      if (apiResponse.success && apiResponse.data != null) {
        await _storage.saveTokens(
          apiResponse.data!.accessToken,
          apiResponse.data!.refreshToken,
        );
        await _storage.setUserId(apiResponse.data!.userId);
        await _storage.setUserRole(apiResponse.data!.role);
        await _storage.setLoggedIn(true);
      }
      
      return apiResponse;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<AuthData>.fromJson(
          e.response!.data,
          (data) => AuthData.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<AuthData>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<AuthData>.error(e.toString());
    }
  }

  Future<ApiResponse<void>> resendOtp(String email, {String type = 'REGISTER'}) async {
    try {
      final response = await _api.post(
        '/auth/resend-otp?type=$type',
        data: {'email': email},
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

  Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      final response = await _api.post(
        '/auth/forgot-password',
        data: {'email': email},
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

  Future<ApiResponse<void>> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _api.post(
        '/auth/reset-password',
        data: request.toJson(),
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

  Future<void> logout() async {
    try {
      await _api.post('/auth/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    } finally {
      await _storage.clearAll();
    }
  }

  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }
}