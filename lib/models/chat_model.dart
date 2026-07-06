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
}

// ✅ FIXED MESSAGE CLASS
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
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      isMine: json['isMine'] ?? false,
      isDeletedForEveryone: json['isDeletedForEveryone'] ?? false,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null 
          ? DateTime.parse(json['editedAt']) 
          : null,
    );
  }

  // ✅ Getter for sent time
  String get sentTime {
    final hour = sentAt.hour.toString().padLeft(2, '0');
    final minute = sentAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ✅ Getter for isEditedNow (for backward compatibility)
  bool get isEditedNow => isEdited;
  
  // ✅ Getter for isDeleted
  bool get isDeleted => isDeletedForEveryone;
  
  // ✅ Getter for hasContent
  bool get hasContent => content != null && content!.isNotEmpty;
  
  // ✅ Getter for isFromMe
  bool get isFromMe => isMine;
  
  // ✅ Getter for isMessageRead
  bool get isMessageRead => isRead;

  // ✅ Getter for displayContent
  String get displayContent {
    if (isDeletedForEveryone) {
      return 'This message was deleted';
    }
    return content ?? '';
  }

  // ✅ Convert to JSON for API
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
  };

  // ✅ CopyWith method for updates
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
    );
  }
}

// ✅ Send Message Request
class SendMessageRequest {
  final String content;

  SendMessageRequest({required this.content});

  Map<String, dynamic> toJson() => {
    'content': content,
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