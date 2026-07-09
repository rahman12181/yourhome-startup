// lib/services/reel_service.dart

import 'dart:io';

import 'package:dio/dio.dart';
import '../models/reel_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class ReelService {
  final ApiService _api = ApiService();

  // ============== 12.1 UPLOAD REEL (OWNER) ==============
  Future<ApiResponse<Reel>> uploadReel({
    required int propertyId,
    required String caption,
    required File videoFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'propertyId': propertyId,
        'caption': caption,
        'file': await MultipartFile.fromFile(
          videoFile.path,
          filename: 'reel_${DateTime.now().millisecondsSinceEpoch}.mp4',
        ),
      });

      final response = await _api.post(
        '/owner/reels',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return ApiResponse<Reel>(
          success: true,
          message: response.data['message'] ?? 'Reel uploaded successfully',
          data: Reel.fromJson(data),
        );
      } else {
        return ApiResponse<Reel>(
          success: false,
          message: response.data['message'] ?? 'Failed to upload reel',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Reel>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<Reel>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Reel>.error(e.toString());
    }
  }

  // ============== 12.2 GET MY REELS (OWNER) ==============
  Future<ApiResponse<List<Reel>>> getMyReels() async {
    try {
      final response = await _api.get('/owner/reels');

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final reels = data.map((item) => Reel.fromJson(item)).toList();
        return ApiResponse<List<Reel>>(
          success: true,
          message: response.data['message'] ?? 'Reels fetched',
          data: reels,
        );
      } else {
        return ApiResponse<List<Reel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch reels',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<Reel>>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<List<Reel>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<Reel>>.error(e.toString());
    }
  }

  // ============== 12.3 DELETE REEL (OWNER) ==============
  Future<ApiResponse<void>> deleteReel(int reelId) async {
    try {
      final response = await _api.delete('/owner/reels/$reelId');

      return ApiResponse<void>(
        success: response.data['success'] ?? false,
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<void>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<void>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }

  // ============== 12.4 GET REELS FEED ==============
  Future<ApiResponse<ReelFeedResponse>> getReelsFeed({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _api.get(
        '/reels/feed',
        queryParameters: {'page': page, 'size': size},
      );

      if (response.data['success'] == true) {
        final feedResponse = ReelFeedResponse.fromJson(response.data);
        return ApiResponse<ReelFeedResponse>(
          success: true,
          message: response.data['message'] ?? 'Reels fetched',
          data: feedResponse,
        );
      } else {
        return ApiResponse<ReelFeedResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch reels',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<ReelFeedResponse>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<ReelFeedResponse>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<ReelFeedResponse>.error(e.toString());
    }
  }

  // ============== 12.5 GET REELS FOR PROPERTY ==============
  Future<ApiResponse<List<Reel>>> getPropertyReels(int propertyId) async {
    try {
      final response = await _api.get('/properties/$propertyId/reels');

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final reels = data.map((item) => Reel.fromJson(item)).toList();
        return ApiResponse<List<Reel>>(
          success: true,
          message: response.data['message'] ?? 'Reels fetched',
          data: reels,
        );
      } else {
        return ApiResponse<List<Reel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch reels',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<Reel>>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<List<Reel>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<Reel>>.error(e.toString());
    }
  }

  // ============== 12.6 LIKE REEL ==============
  Future<ApiResponse<void>> likeReel(int reelId) async {
    try {
      final response = await _api.post('/reels/$reelId/like');

      return ApiResponse<void>(
        success: response.data['success'] ?? false,
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<void>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<void>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }

  // ============== 12.7 UNLIKE REEL ==============
  Future<ApiResponse<void>> unlikeReel(int reelId) async {
    try {
      final response = await _api.delete('/reels/$reelId/like');

      return ApiResponse<void>(
        success: response.data['success'] ?? false,
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<void>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<void>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }

  // ============== 12.8 ADD COMMENT ==============
  Future<ApiResponse<ReelComment>> addComment({
    required int reelId,
    required String content,
  }) async {
    try {
      final response = await _api.post(
        '/reels/$reelId/comments',
        data: {'content': content},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return ApiResponse<ReelComment>(
          success: true,
          message: response.data['message'] ?? 'Comment added',
          data: ReelComment.fromJson(data),
        );
      } else {
        return ApiResponse<ReelComment>(
          success: false,
          message: response.data['message'] ?? 'Failed to add comment',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<ReelComment>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<ReelComment>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<ReelComment>.error(e.toString());
    }
  }

  // ============== 12.9 GET COMMENTS ==============
  Future<ApiResponse<List<ReelComment>>> getComments(int reelId) async {
    try {
      final response = await _api.get('/reels/$reelId/comments');

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final comments = data.map((item) => ReelComment.fromJson(item)).toList();
        return ApiResponse<List<ReelComment>>(
          success: true,
          message: response.data['message'] ?? 'Comments fetched',
          data: comments,
        );
      } else {
        return ApiResponse<List<ReelComment>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch comments',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<ReelComment>>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<List<ReelComment>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<ReelComment>>.error(e.toString());
    }
  }

  // ============== 12.10 REGISTER VIEW ==============
  Future<ApiResponse<void>> registerView(int reelId) async {
    try {
      final response = await _api.patch('/reels/$reelId/view');

      return ApiResponse<void>(
        success: response.data['success'] ?? false,
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<void>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<void>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }

  // ============== 12.11 REGISTER SHARE ==============
  Future<ApiResponse<void>> registerShare(int reelId) async {
    try {
      final response = await _api.post('/reels/$reelId/share');

      return ApiResponse<void>(
        success: response.data['success'] ?? false,
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<void>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<void>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }
}