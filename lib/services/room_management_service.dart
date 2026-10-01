import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/room_model.dart';
import '../models/room_detail_model.dart';
import '../models/bulk_room_model.dart';
import '../models/booking_model.dart';
import 'api_service.dart';

class RoomManagementService {
  final ApiService _api = ApiService();

  // One place for the try/catch pattern used across the app
  Future<ApiResponse<T>> _run<T>(
    Future<Response> Function() request,
    T Function(dynamic data) parse,
  ) async {
    try {
      final response = await request();
      return ApiResponse<T>.fromJson(response.data, (d) => parse(d));
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<T>.fromJson(e.response!.data, (d) => parse(d));
      }
      return ApiResponse<T>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<T>.error(e.toString());
    }
  }

  Map<String, dynamic> _body(List<RoomBatchInput> batches) =>
      {'batches': batches.map((b) => b.toJson()).toList()};

  // POST /owner/properties/{id}/rooms/bulk/preview
  Future<ApiResponse<BulkPreview>> previewBulk(
      int propertyId, List<RoomBatchInput> batches) {
    return _run<BulkPreview>(
      () => _api.post('/owner/properties/$propertyId/rooms/bulk/preview',
          data: _body(batches)),
      (d) => BulkPreview.fromJson(d as Map<String, dynamic>),
    );
  }

  // POST /owner/properties/{id}/rooms/bulk
  Future<ApiResponse<BulkCreateResult>> createBulk(
      int propertyId, List<RoomBatchInput> batches) {
    return _run<BulkCreateResult>(
      () => _api.post('/owner/properties/$propertyId/rooms/bulk',
          data: _body(batches)),
      (d) => BulkCreateResult.fromJson(d as Map<String, dynamic>),
    );
  }

  // GET /owner/properties/{id}/rooms/{roomId}/detail   (owner only)
  Future<ApiResponse<RoomDetail>> getRoomDetail(int propertyId, int roomId) {
    return _run<RoomDetail>(
      () => _api.get('/owner/properties/$propertyId/rooms/$roomId/detail'),
      (d) => RoomDetail.fromJson(d as Map<String, dynamic>),
    );
  }

  // PATCH /owner/properties/{id}/rooms/{roomId}/maintenance
  Future<ApiResponse<Room>> setMaintenance(
      int propertyId, int roomId, bool enabled) {
    return _run<Room>(
      () => _api.patch(
        '/owner/properties/$propertyId/rooms/$roomId/maintenance',
        data: {'enabled': enabled},
      ),
      (d) => Room.fromJson(d as Map<String, dynamic>),
    );
  }

  // ✅ NEW — PATCH /owner/booking-requests/{id}/accept  (with optional room)
  // Used when the student asked for "any available room" and the owner picks one.
  Future<ApiResponse<BookingRequest>> acceptBooking(
    int requestId,
    String responseMsg, {
    int? roomId,
  }) {
    return _run<BookingRequest>(
      () => _api.patch(
        '/owner/booking-requests/$requestId/accept',
        data: {
          'response': responseMsg,
          if (roomId != null) 'roomId': roomId,
        },
      ),
      (d) => BookingRequest.fromJson(d as Map<String, dynamic>),
    );
  }
}