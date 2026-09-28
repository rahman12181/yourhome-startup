class Conversation {
  final int conversationId;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserPic;
  final String? propertyTitle;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPic,
    this.propertyTitle,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId'] ?? 0,
      otherUserId: json['otherUserId'] ?? 0,
      otherUserName: json['otherUserName'] ?? '',
      otherUserPic: json['otherUserPic'],
      propertyTitle: json['propertyTitle'],
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  String get lastMessageTime {
    if (lastMessageAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Conversation copyWith({
    int? conversationId,
    int? otherUserId,
    String? otherUserName,
    String? otherUserPic,
    String? propertyTitle,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return Conversation(
      conversationId: conversationId ?? this.conversationId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPic: otherUserPic ?? this.otherUserPic,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// ✅ MESSAGE CLASS (with receiverId, otherUserId, and reply fields)
class Message {
  final int messageId;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String? senderPic;
  final String? content;
  final bool isRead;
  final DateTime sentAt;
  final bool isMine;
  final bool isDeletedForEveryone;
  final bool isEdited;
  final DateTime? editedAt;
  final int? receiverId;
  final int? otherUserId;

  // 🆕 REPLY FIELDS
  final int? replyToMessageId;      // jis message ko reply kiya
  final String? replyToContent;     // us message ka content preview
  final String? replyToSenderName;  // us message ka sender ka naam
  final bool? replyToIsMine;        // kya wo replied message mera tha?

  Message({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPic,
    this.content,
    required this.isRead,
    required this.sentAt,
    required this.isMine,
    this.isDeletedForEveryone = false,
    this.isEdited = false,
    this.editedAt,
    this.receiverId,
    this.otherUserId,
    // 🆕 reply
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderName,
    this.replyToIsMine,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] ?? 0,
      conversationId: json['conversationId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'] ?? '',
      senderPic: json['senderPic'],
      content: json['content'],
      isRead: json['isRead'] ?? false,
      sentAt:
          DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      isMine: json['isMine'] ?? false,
      isDeletedForEveryone: json['isDeletedForEveryone'] ?? false,
      isEdited: json['isEdited'] ?? false,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      receiverId: json['receiverId'],
      otherUserId: json['otherUserId'],
      // 🆕 reply
      replyToMessageId: json['replyToMessageId'],
      replyToContent: json['replyToContent'],
      replyToSenderName: json['replyToSenderName'],
      replyToIsMine: json['replyToIsMine'],
    );
  }

  String get sentTime {
    final hour = sentAt.hour.toString().padLeft(2, '0');
    final minute = sentAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool get isEditedNow => isEdited;
  bool get isDeleted => isDeletedForEveryone;
  bool get hasContent => content != null && content!.isNotEmpty;
  bool get isFromMe => isMine;
  bool get isMessageRead => isRead;

  // 🆕 Kya ye message kisi aur message ka reply hai?
  bool get isReply => replyToMessageId != null;

  String get displayContent {
    if (isDeletedForEveryone) {
      return 'This message was deleted';
    }
    return content ?? '';
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPic': senderPic,
        'content': content,
        'isRead': isRead,
        'sentAt': sentAt.toIso8601String(),
        'isMine': isMine,
        'isDeletedForEveryone': isDeletedForEveryone,
        'isEdited': isEdited,
        'editedAt': editedAt?.toIso8601String(),
        'receiverId': receiverId,
        'otherUserId': otherUserId,
        // 🆕 reply
        'replyToMessageId': replyToMessageId,
        'replyToContent': replyToContent,
        'replyToSenderName': replyToSenderName,
        'replyToIsMine': replyToIsMine,
      };

  Message copyWith({
    int? messageId,
    int? conversationId,
    int? senderId,
    String? senderName,
    String? senderPic,
    String? content,
    bool? isRead,
    DateTime? sentAt,
    bool? isMine,
    bool? isDeletedForEveryone,
    bool? isEdited,
    DateTime? editedAt,
    int? receiverId,
    int? otherUserId,
    // 🆕 reply
    int? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
    bool? replyToIsMine,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPic: senderPic ?? this.senderPic,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      isMine: isMine ?? this.isMine,
      isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      receiverId: receiverId ?? this.receiverId,
      otherUserId: otherUserId ?? this.otherUserId,
      // 🆕 reply
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToIsMine: replyToIsMine ?? this.replyToIsMine,
    );
  }
}

// ✅ Send Message Request (with optional replyToMessageId)
class SendMessageRequest {
  final String content;
  final int? replyToMessageId;    // 🆕

  SendMessageRequest({
    required this.content,
    this.replyToMessageId,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      };
}

// ✅ Edit Message Request
class EditMessageRequest {
  final String content;

  EditMessageRequest({required this.content});

  Map<String, dynamic> toJson() => {
        'content': content,
      };
}

// ✅ Delete Message Response
class DeleteMessageResponse {
  final bool success;
  final String message;
  final int? messageId;

  DeleteMessageResponse({
    required this.success,
    required this.message,
    this.messageId,
  });

  factory DeleteMessageResponse.fromJson(Map<String, dynamic> json) {
    return DeleteMessageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      messageId: json['messageId'],
    );
  }
}

class TypingEvent {
  final int conversationId;
  final int senderId;
  final bool isTyping;

  TypingEvent({
    required this.conversationId,
    required this.senderId,
    required this.isTyping,
  });

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    return TypingEvent(
      conversationId: json['conversationId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      isTyping: json['isTyping'] ?? false,
    );
  }
}