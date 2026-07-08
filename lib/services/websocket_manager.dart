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
  Function()? onConnected;
  Function(String)? onError;

  bool get isConnected => _isConnected;
  int? get currentUserId => _currentUserId;

  void connect({required String token, required int userId}) {
    print('🔌 [WS] connect() called for userId=$userId, wsUrl=${AppConstants.wsUrl}'); // ✅ ADDED

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
          print('✅ [WS] CONNECTED successfully for user $userId'); // ✅
          _subscribeToTopics(userId);
          if (onConnected != null) onConnected!();
        },
        onDisconnect: (frame) {
          _isConnected = false;
          _isConnecting = false;
          print('❌ [WS] DISCONNECTED for user $userId'); // ✅ ADDED
        },
        onWebSocketError: (error) {
          _isConnected = false;
          _isConnecting = false;
          print('❌ [WS] WEBSOCKET ERROR: $error'); // ✅ ADDED — this will show the real cause
          if (onError != null) onError!(error.toString());
        },
        onStompError: (frame) {
          print('❌ [WS] STOMP ERROR: ${frame.body}'); // ✅ ADDED
          if (onError != null) onError!(frame.body ?? 'STOMP Error');
        },
        beforeConnect: () async {
          print('🔌 [WS] beforeConnect - attempting to reach $wsUrl'); // ✅ ADDED
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
    print('🔌 [WS] client.activate() called'); // ✅ ADDED
  }

  void _subscribeToTopics(int userId) {
    if (_client == null) return;
    print('📡 [WS] Subscribing to topics for user $userId'); // ✅ ADDED

    _client!.subscribe(
      destination: '/user/$userId/queue/messages',
      callback: (frame) {
        print('📩 [WS] Message received on /queue/messages'); // ✅ ADDED
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final message = Message.fromJson(json);
            if (onMessageReceived != null) onMessageReceived!(message);
          } catch (e) {
            print('❌ [WS] Error parsing message: $e'); // ✅ ADDED
          }
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
        print('📩 [WS] Conversation update received'); // ✅ ADDED
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final conv = Conversation.fromJson(json);
            if (onConversationUpdated != null) onConversationUpdated!(conv);
          } catch (e) {
            print('❌ [WS] Error parsing conversation update: $e'); // ✅ ADDED
          }
        }
      },
    );

    _client!.subscribe(
      destination: '/user/$userId/queue/typing',
      callback: (frame) {
        print('📩 [WS] Typing event received'); // ✅ ADDED
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final event = TypingEvent.fromJson(json);
            if (onTypingReceived != null) onTypingReceived!(event);
          } catch (e) {
            print('❌ [WS] Error parsing typing event: $e'); // ✅ ADDED
          }
        }
      },
    );

    print('📡 [WS] All subscriptions set up for user $userId'); // ✅ ADDED
  }

  void sendTyping({
    required int conversationId,
    required int receiverId,
    required bool isTyping,
  }) {
    if (_client == null || !_isConnected) {
      print('⚠️ [WS] Cannot send typing — client null or not connected (isConnected=$_isConnected)'); // ✅ ADDED
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
      print('📤 [WS] Typing sent: conv=$conversationId, isTyping=$isTyping'); // ✅ ADDED
    } catch (e) {
      print('❌ [WS] Error sending typing: $e'); // ✅ ADDED
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
    print('🔌 [WS] Manually disconnected'); // ✅ ADDED
  }
}

final wsManager = WebSocketManager();