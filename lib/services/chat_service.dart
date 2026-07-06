import 'package:dio/dio.dart';
import '../models/chat_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  // ============== 9.1 CREATE/GET CONVERSATION ==============
  Future<ApiResponse<Conversation>> createConversation({
    required int ownerUserId,
    int? propertyId,
    int? bookingRequestId,
  }) async {
    try {
      final response = await _api.post(
        '/chat/conversations',
        data: {
          'ownerUserId': ownerUserId,
          if (propertyId != null) 'propertyId': propertyId,
          if (bookingRequestId != null) 'bookingRequestId': bookingRequestId,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return ApiResponse<Conversation>(
          success: true,
          message: response.data['message'] ?? 'Conversation started',
          data: Conversation.fromJson(data),
        );
      } else {
        return ApiResponse<Conversation>(
          success: false,
          message: response.data['message'] ?? 'Failed to start conversation',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Conversation>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<Conversation>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Conversation>.error(e.toString());
    }
  }

  // ============== 9.2 GET ALL CONVERSATIONS ==============
  Future<ApiResponse<List<Conversation>>> getConversations() async {
    try {
      final response = await _api.get('/chat/conversations');

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final conversations = data.map((item) => Conversation.fromJson(item)).toList();
        return ApiResponse<List<Conversation>>(
          success: true,
          message: response.data['message'] ?? 'Conversations fetched',
          data: conversations,
        );
      } else {
        return ApiResponse<List<Conversation>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch conversations',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<Conversation>>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<List<Conversation>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<Conversation>>.error(e.toString());
    }
  }

  // ============== 9.3 GET MESSAGES ==============
  Future<ApiResponse<List<Message>>> getMessages(int conversationId) async {
    try {
      final response = await _api.get('/chat/conversations/$conversationId/messages');

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final messages = data.map((item) => Message.fromJson(item)).toList();
        return ApiResponse<List<Message>>(
          success: true,
          message: response.data['message'] ?? 'Messages fetched',
          data: messages,
        );
      } else {
        return ApiResponse<List<Message>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch messages',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<Message>>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<List<Message>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<Message>>.error(e.toString());
    }
  }

  // ============== 9.4 SEND MESSAGE ==============
  Future<ApiResponse<Message>> sendMessage(int conversationId, String content) async {
    try {
      final response = await _api.post(
        '/chat/conversations/$conversationId/messages',
        data: {'content': content},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return ApiResponse<Message>(
          success: true,
          message: response.data['message'] ?? 'Message sent',
          data: Message.fromJson(data),
        );
      } else {
        return ApiResponse<Message>(
          success: false,
          message: response.data['message'] ?? 'Failed to send message',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Message>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<Message>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Message>.error(e.toString());
    }
  }

  // ============== 9.5 MARK MESSAGES AS READ ==============
  Future<ApiResponse<void>> markAsRead(int conversationId) async {
    try {
      final response = await _api.patch('/chat/conversations/$conversationId/read');
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

  // ============== 9.6 EDIT MESSAGE ==============
  Future<ApiResponse<Message>> editMessage(int messageId, String content) async {
    try {
      final response = await _api.patch(
        '/chat/messages/$messageId/edit',
        data: {'content': content},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return ApiResponse<Message>(
          success: true,
          message: response.data['message'] ?? 'Message edited',
          data: Message.fromJson(data),
        );
      } else {
        return ApiResponse<Message>(
          success: false,
          message: response.data['message'] ?? 'Failed to edit message',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Message>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<Message>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Message>.error(e.toString());
    }
  }

  // ============== 9.7 DELETE MESSAGE FOR EVERYONE ✅ ==============
  Future<ApiResponse<Message>> deleteForEveryone(int messageId) async {
    try {
      final response = await _api.delete('/chat/messages/$messageId/everyone');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return ApiResponse<Message>(
          success: true,
          message: response.data['message'] ?? 'Message deleted for everyone',
          data: Message.fromJson(data),
        );
      } else {
        return ApiResponse<Message>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete message',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Message>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<Message>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Message>.error(e.toString());
    }
  }

  // ============== 9.8 DELETE MESSAGE FOR ME ✅ ==============
  Future<ApiResponse<void>> deleteForMe(int messageId) async {
    try {
      final response = await _api.delete('/chat/messages/$messageId/me');
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