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
  bool _isConnecting = false;
  int? _currentUserId;

  Function(Message)? onMessageReceived;
  Function(Message)? onMessageEdited;
  Function(Message)? onMessageDeleted;
  Function(Conversation)? onConversationUpdated;
  Function(TypingEvent)? onTypingReceived;
  Function(int)? onMessagesRead;
  Function()? onConnected;
  Function(String)? onError;

  bool get isConnected => _isConnected;
  int? get currentUserId => _currentUserId;

  void connect({required String token, required int userId}) {
    print('🔌 [WS] connect() called for userId=$userId, wsUrl=${AppConstants.wsUrl}');

    if (_isConnected && _currentUserId == userId) {
      print('🔌 [WS] Already connected for user $userId, skipping');
      return;
    }
    if (_isConnecting) {
      print('🔌 [WS] Connect already in progress, skipping duplicate call');
      return;
    }

    _isConnecting = true;

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
          _isConnecting = false;
          print('✅ [WS] CONNECTED successfully for user $userId');
          _subscribeToTopics(userId);
          if (onConnected != null) onConnected!();
        },
        onDisconnect: (frame) {
          _isConnected = false;
          _isConnecting = false;
          print('❌ [WS] DISCONNECTED for user $userId');
        },
        onWebSocketError: (error) {
          _isConnected = false;
          _isConnecting = false;
          print('❌ [WS] WEBSOCKET ERROR: $error');
          if (onError != null) onError!(error.toString());
        },
        onStompError: (frame) {
          print('❌ [WS] STOMP ERROR: ${frame.body}');
          if (onError != null) onError!(frame.body ?? 'STOMP Error');
        },
        beforeConnect: () async {
          print('🔌 [WS] beforeConnect - attempting to reach $wsUrl');
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
    print('🔌 [WS] client.activate() called');
  }

  void _subscribeToTopics(int userId) {
    if (_client == null) return;
    print('📡 [WS] Subscribing to topics for user $userId');

    _client!.subscribe(
      destination: '/user/queue/messages',
      callback: (frame) {
        print('📩 [WS] Message received on /user/queue/messages');
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            print('📩 [WS] Message JSON: $json');
            final message = Message.fromJson(json);
            if (onMessageReceived != null) onMessageReceived!(message);
          } catch (e) {
            print('❌ [WS] Error parsing message: $e');
          }
        }
      },
    );

    _client!.subscribe(
      destination: '/user/queue/message-edited',
      callback: (frame) {
        print('📩 [WS] Message edited received');
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final message = Message.fromJson(json);
            if (onMessageEdited != null) onMessageEdited!(message);
          } catch (e) {
            print('❌ [WS] Error parsing edit: $e');
          }
        }
      },
    );

    _client!.subscribe(
      destination: '/user/queue/message-deleted',
      callback: (frame) {
        print('📩 [WS] Message deleted received');
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final message = Message.fromJson(json);
            if (onMessageDeleted != null) onMessageDeleted!(message);
          } catch (e) {
            print('❌ [WS] Error parsing delete: $e');
          }
        }
      },
    );

    _client!.subscribe(
      destination: '/user/queue/conversation-update',
      callback: (frame) {
        print('📩 [WS] Conversation update received');
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final conv = Conversation.fromJson(json);
            if (onConversationUpdated != null) onConversationUpdated!(conv);
          } catch (e) {
            print('❌ [WS] Error parsing conversation update: $e');
          }
        }
      },
    );

    _client!.subscribe(
      destination: '/user/queue/typing',
      callback: (frame) {
        print('📩 [WS] Typing event received');
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final event = TypingEvent.fromJson(json);
            if (onTypingReceived != null) onTypingReceived!(event);
          } catch (e) {
            print('❌ [WS] Error parsing typing event: $e');
          }
        }
      },
    );

    _client!.subscribe(
      destination: '/user/queue/messages-read',
      callback: (frame) {
        print('📩 [WS] Messages read event received');
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final convId = json['conversationId'] as int;
            if (onMessagesRead != null) onMessagesRead!(convId);
          } catch (e) {
            print('❌ [WS] Error parsing read event: $e');
          }
        }
      },
    );

    print('📡 [WS] All subscriptions set up for user $userId');
  }

  void sendTyping({
    required int conversationId,
    required int receiverId,
    required bool isTyping,
  }) {
    if (_client == null || !_isConnected) {
      print('⚠️ [WS] Cannot send typing — client null or not connected (isConnected=$_isConnected)');
      return;
    }
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
      print('📤 [WS] Typing sent: conv=$conversationId, isTyping=$isTyping');
    } catch (e) {
      print('❌ [WS] Error sending typing: $e');
    }
  }

  // ============================================
  // 🆕 PRESENCE — Tell backend we're active in this chat or not
  // ============================================
  void sendPresence({
    required int conversationId,
    required bool isActive,
  }) {
    if (_client == null || !_isConnected) {
      print('⚠️ [WS] Cannot send presence — not connected');
      return;
    }
    try {
      _client!.send(
        destination: '/app/chat.presence',
        body: jsonEncode({
          'conversationId': conversationId,
          'isActive': isActive,
        }),
      );
      print('📤 [WS] Presence sent: conv=$conversationId, isActive=$isActive');
    } catch (e) {
      print('❌ [WS] Error sending presence: $e');
    }
  }

  void disconnect() {
    if (_client != null) {
      _client!.deactivate();
      _client = null;
    }
    _isConnected = false;
    _isConnecting = false;
    _currentUserId = null;
    print('🔌 [WS] Manually disconnected');
  }
}

final wsManager = WebSocketManager();