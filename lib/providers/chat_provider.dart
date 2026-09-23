// lib/providers/chat_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/websocket_manager.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final WebSocketManager _wsManager = WebSocketManager();

  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  int? _activeConversationId;
  final Map<int, bool> _typingByConversation = {};
  final Map<int, Timer> _typingTimers = {};

  // ✅ NEW — Unread count
  int _unreadCount = 0;

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  WebSocketManager get wsManager => _wsManager;
  int? get activeConversationId => _activeConversationId;

  // ✅ NEW — Getter
  int get unreadCount => _unreadCount;

  bool isOtherUserTyping(int conversationId) =>
      _typingByConversation[conversationId] ?? false;

  void setTypingStatus(int conversationId, bool isTyping) {
    if (_typingByConversation[conversationId] != isTyping) {
      _typingByConversation[conversationId] = isTyping;
      notifyListeners();
    }
  }

  void updateMessage(Message message) {
    final index = _messages.indexWhere((m) => m.messageId == message.messageId);
    if (index != -1) {
      _messages[index] = message;
      notifyListeners();
    }
  }

  void removeMessage(int messageId) {
    _messages.removeWhere((m) => m.messageId == messageId);
    notifyListeners();
  }

  void initWebSocket({required String token, required int userId}) {
    _wsManager.onMessageReceived = (message) {
      _addMessage(message);
      // ✅ NEW — Increment unread count on new message
      _unreadCount += 1;
      notifyListeners();
    };

    _wsManager.onMessageEdited = (message) {
      _updateMessage(message);
    };

    _wsManager.onMessageDeleted = (message) {
      _removeMessage(message);
    };

    _wsManager.onConversationUpdated = (conversation) {
      _updateConversation(conversation);
    };

    _wsManager.onTypingReceived = (event) {
      _handleTypingEvent(event);
    };

    _wsManager.onConnected = () {
      notifyListeners();
    };

    _wsManager.onError = (error) {
      _error = error;
      notifyListeners();
    };

    _wsManager.connect(token: token, userId: userId);
  }

  void setActiveConversation(int? conversationId) {
    _activeConversationId = conversationId;
  }

  Future<void> loadConversations() async {
    _setLoading(true);
    try {
      final response = await _chatService.getConversations();
      if (response.success && response.data != null) {
        _conversations = response.data!;
        _recalculateUnread();  // ✅ NEW
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> loadMessages(int conversationId) async {
    _setLoading(true);
    try {
      final response = await _chatService.getMessages(conversationId);
      if (response.success && response.data != null) {
        _messages = response.data!;
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  // ============================================
  // ✅ NEW — Load unread count
  // ============================================
  Future<void> loadUnreadCount() async {
    try {
      final response = await _chatService.getConversations();
      if (response.success && response.data != null) {
        _conversations = response.data!;
        _recalculateUnread();
        notifyListeners();
      }
    } catch (_) {}
  }

  // ✅ NEW — Helper to calculate total unread
  void _recalculateUnread() {
    int total = 0;
    for (final c in _conversations) {
      total += c.unreadCount;
    }
    _unreadCount = total;
  }

  void addOptimisticMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void replaceOptimisticMessage(int tempId, Message realMessage) {
    final index = _messages.indexWhere((m) => m.messageId == tempId);
    if (index != -1) {
      _messages[index] = realMessage;
    } else {
      _messages.add(realMessage);
    }
    notifyListeners();
  }

  void removeOptimisticMessage(int tempId) {
    _messages.removeWhere((m) => m.messageId == tempId);
    notifyListeners();
  }

  Future<bool> sendMessage({
    required int conversationId,
    required String content,
  }) async {
    try {
      final response = await _chatService.sendMessage(conversationId, content);
      if (response.success && response.data != null) {
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> editMessage({
    required int messageId,
    required String content,
  }) async {
    try {
      final response = await _chatService.editMessage(messageId, content);
      if (response.success && response.data != null) {
        _updateMessage(response.data!);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteForEveryone(int messageId) async {
    try {
      final response = await _chatService.deleteForEveryone(messageId);
      if (response.success && response.data != null) {
        _updateMessage(response.data!);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteForMe(int messageId) async {
    try {
      final response = await _chatService.deleteForMe(messageId);
      if (response.success) {
        _messages.removeWhere((m) => m.messageId == messageId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> markAsRead(int conversationId) async {
    try {
      await _chatService.markAsRead(conversationId);

      // ✅ NEW — Reset unread count for this conversation
      final index = _conversations.indexWhere(
        (c) => c.conversationId == conversationId,
      );
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
        _recalculateUnread();
        notifyListeners();
      }
    } catch (e) {}
  }

  void sendTypingIndicator({
    required int conversationId,
    required int receiverId,
    required bool isTyping,
  }) {
    _wsManager.sendTyping(
      conversationId: conversationId,
      receiverId: receiverId,
      isTyping: isTyping,
    );
  }

  void _handleTypingEvent(TypingEvent event) {
    _typingByConversation[event.conversationId] = event.isTyping;
    notifyListeners();

    _typingTimers[event.conversationId]?.cancel();
    if (event.isTyping) {
      _typingTimers[event.conversationId] = Timer(
        const Duration(seconds: 3),
        () {
          _typingByConversation[event.conversationId] = false;
          notifyListeners();
        },
      );
    }
  }

  void _addMessage(Message message) {
    final exists = _messages.any((m) => m.messageId == message.messageId);
    if (!exists) {
      _messages.add(message);
      // ✅ Removed print statement
    }
    _typingByConversation[message.conversationId] = false;
    notifyListeners();
  }

  void _updateMessage(Message message) {
    final index = _messages.indexWhere((m) => m.messageId == message.messageId);
    if (index != -1) {
      _messages[index] = message;
      notifyListeners();
    }
  }

  void _removeMessage(Message message) {
    if (message.isDeletedForEveryone) {
      _updateMessage(message);
    } else {
      _messages.removeWhere((m) => m.messageId == message.messageId);
      notifyListeners();
    }
  }

  void _updateConversation(Conversation conversation) {
    final index = _conversations.indexWhere(
      (c) => c.conversationId == conversation.conversationId,
    );
    if (index != -1) {
      _conversations[index] = conversation;
    } else {
      _conversations.insert(0, conversation);
    }
    _conversations.sort((a, b) {
      final aTime = a.lastMessageAt;
      final bTime = b.lastMessageAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    _recalculateUnread();  // ✅ NEW
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  void disconnectWebSocket() {
    _wsManager.disconnect();
  }

  @override
  void dispose() {
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    disconnectWebSocket();
    super.dispose();
  }
}