// lib/services/websocket_manager.dart

import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:yourhome/models/chat_model.dart';
import 'package:yourhome/utils/constants.dart';

class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  StompClient? _client;
  bool _isConnected = false;
  int? _currentUserId;

  Function(Message)? onMessageReceived;
  Function(Message)? onMessageEdited;
  Function(Message)? onMessageDeleted;
  Function(Conversation)? onConversationUpdated;
  Function(TypingEvent)? onTypingReceived; // ✅ ADDED
  Function()? onConnected;
  Function(String)? onError;

  bool get isConnected => _isConnected;
  int? get currentUserId => _currentUserId; // ✅ ADDED - needed for sendTyping

  void connect({required String token, required int userId}) {
    if (_isConnected && _currentUserId == userId) return;

    if (_client != null) {
      _client!.deactivate();
      _client = null;
    }

    _currentUserId = userId;
    final wsUrl = AppConstants.wsUrl;

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        onConnect: (frame) {
          _isConnected = true;
          _subscribeToTopics(userId);
          if (onConnected != null) onConnected!();
        },
        onDisconnect: (frame) {
          _isConnected = false;
        },
        onWebSocketError: (error) {
          _isConnected = false;
          if (onError != null) onError!(error.toString());
        },
        onStompError: (frame) {
          if (onError != null) onError!(frame.body ?? 'STOMP Error');
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
  }

  void _subscribeToTopics(int userId) {
    if (_client == null) return;

    _client!.subscribe(
      destination: '/user/$userId/queue/messages',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final message = Message.fromJson(json);
            if (onMessageReceived != null) onMessageReceived!(message);
          } catch (e) {}
        }
      },
    );

    _client!.subscribe(
      destination: '/user/$userId/queue/message-edited',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final message = Message.fromJson(json);
            if (onMessageEdited != null) onMessageEdited!(message);
          } catch (e) {}
        }
      },
    );

    _client!.subscribe(
      destination: '/user/$userId/queue/message-deleted',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final message = Message.fromJson(json);
            if (onMessageDeleted != null) onMessageDeleted!(message);
          } catch (e) {}
        }
      },
    );

    _client!.subscribe(
      destination: '/user/$userId/queue/conversation-update',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final conv = Conversation.fromJson(json);
            if (onConversationUpdated != null) onConversationUpdated!(conv);
          } catch (e) {}
        }
      },
    );

    // ✅ ADDED — typing indicator subscription
    _client!.subscribe(
      destination: '/user/$userId/queue/typing',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final event = TypingEvent.fromJson(json);
            if (onTypingReceived != null) onTypingReceived!(event);
          } catch (e) {}
        }
      },
    );
  }

  // ✅ ADDED — send typing status to the other user
  // NOTE: Backend mein ye STOMP @MessageMapping add karni hogi:
  //
  // @MessageMapping("/chat.typing")
  // public void handleTyping(@Payload TypingEventDto event) {
  //     messagingTemplate.convertAndSendToUser(
  //         String.valueOf(event.getReceiverId()),
  //         "/queue/typing",
  //         Map.of(
  //             "conversationId", event.getConversationId(),
  //             "senderId", event.getSenderId(),
  //             "isTyping", event.isTyping()
  //         )
  //     );
  // }
  void sendTyping({
    required int conversationId,
    required int receiverId,
    required bool isTyping,
  }) {
    if (_client == null || !_isConnected) return;
    try {
      _client!.send(
        destination: '/app/chat.typing',
        body: jsonEncode({
          'conversationId': conversationId,
          'senderId': _currentUserId,
          'receiverId': receiverId,
          'isTyping': isTyping,
        }),
      );
    } catch (e) {}
  }

  void disconnect() {
    if (_client != null) {
      _client!.deactivate();
      _client = null;
    }
    _isConnected = false;
    _currentUserId = null;
  }
}

final wsManager = WebSocketManager();