import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final StorageService _storage = StorageService();
  bool _isInitialized = false;

  // ✅ Initialize method - call this from main.dart
  Future<void> init() async {
    if (_isInitialized) return;
    
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('📤 Request: ${options.method} ${options.path}');
        print('📤 Headers: ${options.headers}');
        print('📤 Data: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // ✅ ADD THIS - Print response for debugging
        print('📥 Response: ${response.statusCode}');
        print('📥 Data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        print('❌ Error: ${error.message}');
        print('❌ Error Response: ${error.response?.data}');
        
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token = await _storage.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final retry = await _dio.fetch(error.requestOptions);
            return handler.resolve(retry);
          }
        }
        return handler.next(error);
      },
    ));
    
    _isInitialized = true;
  }

  Dio get dio {
    if (!_isInitialized) {
      throw Exception('ApiService not initialized. Call ApiService().init() first.');
    }
    return _dio;
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh-token',
        options: Options(
          headers: {'Refresh-Token': refreshToken},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await checkConnectivity()) {
      throw Exception('No internet connection');
    }
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await checkConnectivity()) {
      throw Exception('No internet connection');
    }
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await checkConnectivity()) {
      throw Exception('No internet connection');
    }
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await checkConnectivity()) {
      throw Exception('No internet connection');
    }
    return _dio.delete(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await checkConnectivity()) {
      throw Exception('No internet connection');
    }
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> upload(
    String path,
    FormData formData, {
    Options? options,
  }) async {
    if (!await checkConnectivity()) {
      throw Exception('No internet connection');
    }
    return _dio.post(
      path,
      data: formData,
      options: options?.copyWith(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

//IN THE ApiService CLASS, ADD THESE METHODS

  //  REFER & EARN APIs 

  /// Get My Referral Info
  Future<Response> getReferralInfo() async {
    return await get('/user/referral/info');
  }

  ///Get My Referral History
  Future<Response> getReferralHistory() async {
    return await get('/user/referral/history');
  }

  /// Get Wallet Transaction History
  Future<Response> getWalletTransactions({
    int page = 0,
    int size = 20,
  }) async {
    return await get(
      '/user/wallet/transactions',
      queryParameters: {
        'page': page,
        'size': size,
      },
    );
  }

  /// Request Withdrawal
  Future<Response> requestWithdrawal({
    required double amount,
    required String upiId,
  }) async {
    return await post(
      '/user/wallet/withdraw',
      data: {
        'amount': amount,
        'upiId': upiId,
      },
    );
  }

  /// Get My Withdrawal Requests
  Future<Response> getWithdrawals() async {
    return await get('/user/wallet/withdrawals');
  }

  ///- Get Pending Withdrawals (Admin)
  Future<Response> getPendingWithdrawals() async {
    return await get('/admin/withdrawals/pending');
  }

  /// Approve Withdrawal (Admin)
  Future<Response> approveWithdrawal({
    required int withdrawalId,
    required String transactionRef,
  }) async {
    return await patch(
      '/admin/withdrawals/$withdrawalId/approve',
      data: {'transactionRef': transactionRef},
    );
  }

  /// Reject Withdrawal (Admin)
  Future<Response> rejectWithdrawal({
    required int withdrawalId,
    required String reason,
  }) async {
    return await patch(
      '/admin/withdrawals/$withdrawalId/reject',
      data: {'reason': reason},
    );
  }
}