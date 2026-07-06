import 'package:dio/dio.dart';
import 'package:yourhome/models/room_model.dart';
import '../models/property_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class PropertyService {
  final ApiService _api = ApiService();

  // 4.1 Add Property
  Future<ApiResponse<Property>> addProperty(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(
        '/owner/properties',
        data: data,
      );
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

  // 4.2 Get My Properties
  Future<ApiResponse<List<Property>>> getMyProperties() async {
    try {
      final response = await _api.get('/owner/properties');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final properties = data.map((item) => Property.fromJson(item)).toList();
        return ApiResponse<List<Property>>(
          success: true,
          message: response.data['message'] ?? '',
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
          (data) => (data as List).map((item) => Property.fromJson(item)).toList(),
        );
      }
      return ApiResponse<List<Property>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<Property>>.error(e.toString());
    }
  }

  // 4.3 Get Property Detail (Owner)
  Future<ApiResponse<Property>> getPropertyDetailOwner(int propertyId) async {
    try {
      final response = await _api.get('/owner/properties/$propertyId');
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

  // 4.4 Update Property
  Future<ApiResponse<Property>> updateProperty(int propertyId, Map<String, dynamic> data) async {
    try {
      final response = await _api.put(
        '/owner/properties/$propertyId',
        data: data,
      );
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

  // 4.5 Delete Property
  Future<ApiResponse<void>> deleteProperty(int propertyId) async {
    try {
      final response = await _api.delete('/owner/properties/$propertyId');
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

  // 4.6 Upload Property Media
  Future<ApiResponse<Media>> uploadPropertyMedia(int propertyId, FormData formData) async {
    try {
      final response = await _api.upload(
        '/owner/properties/$propertyId/media',
        formData,
      );
      return ApiResponse<Media>.fromJson(
        response.data,
        (data) => Media.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Media>.fromJson(
          e.response!.data,
          (data) => Media.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<Media>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Media>.error(e.toString());
    }
  }

  // 4.7 Delete Property Media
  Future<ApiResponse<void>> deletePropertyMedia(int propertyId, int mediaId) async {
    try {
      final response = await _api.delete('/owner/properties/$propertyId/media/$mediaId');
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

  // 5.1 Add Room
  Future<ApiResponse<Room>> addRoom(int propertyId, Map<String, dynamic> data) async {
    try {
      final response = await _api.post(
        '/owner/properties/$propertyId/rooms',
        data: data,
      );
      return ApiResponse<Room>.fromJson(
        response.data,
        (data) => Room.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Room>.fromJson(
          e.response!.data,
          (data) => Room.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<Room>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Room>.error(e.toString());
    }
  }

  // 5.2 Get All Rooms (Owner)
  Future<ApiResponse<List<Room>>> getRooms(int propertyId) async {
    try {
      final response = await _api.get('/owner/properties/$propertyId/rooms');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final rooms = data.map((item) => Room.fromJson(item)).toList();
        return ApiResponse<List<Room>>(
          success: true,
          message: response.data['message'] ?? '',
          data: rooms,
        );
      } else {
        return ApiResponse<List<Room>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch rooms',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<Room>>.fromJson(
          e.response!.data,
          (data) => (data as List).map((item) => Room.fromJson(item)).toList(),
        );
      }
      return ApiResponse<List<Room>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<Room>>.error(e.toString());
    }
  }

  // 5.3 Update Room
  Future<ApiResponse<Room>> updateRoom(int propertyId, int roomId, Map<String, dynamic> data) async {
    try {
      final response = await _api.put(
        '/owner/properties/$propertyId/rooms/$roomId',
        data: data,
      );
      return ApiResponse<Room>.fromJson(
        response.data,
        (data) => Room.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Room>.fromJson(
          e.response!.data,
          (data) => Room.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<Room>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Room>.error(e.toString());
    }
  }

  // 5.4 Update Room Status
  Future<ApiResponse<Room>> updateRoomStatus(int propertyId, int roomId, String status) async {
    try {
      final response = await _api.patch(
        '/owner/properties/$propertyId/rooms/$roomId/status',
        data: {'status': status},
      );
      return ApiResponse<Room>.fromJson(
        response.data,
        (data) => Room.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Room>.fromJson(
          e.response!.data,
          (data) => Room.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<Room>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Room>.error(e.toString());
    }
  }

  // 5.5 Delete Room
  Future<ApiResponse<void>> deleteRoom(int propertyId, int roomId) async {
    try {
      final response = await _api.delete('/owner/properties/$propertyId/rooms/$roomId');
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

  // 6.3 Get Property Rooms (Public)
  Future<ApiResponse<List<Room>>> getPublicRooms(int propertyId) async {
    try {
      final response = await _api.get('/properties/$propertyId/rooms');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final rooms = data.map((item) => Room.fromJson(item)).toList();
        return ApiResponse<List<Room>>(
          success: true,
          message: response.data['message'] ?? '',
          data: rooms,
        );
      } else {
        return ApiResponse<List<Room>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch rooms',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<Room>>.fromJson(
          e.response!.data,
          (data) => (data as List).map((item) => Room.fromJson(item)).toList(),
        );
      }
      return ApiResponse<List<Room>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<Room>>.error(e.toString());
    }
  }
}