// lib/models/reel_model.dart

class Reel {
  final int reelId;
  final int propertyId;
  final String propertyTitle;
  final String propertyCity;
  final int ownerUserId;
  final String ownerName;
  final String ownerDisplayId;
  final String? ownerProfilePic;
  final bool isVerifiedOwner;
  final String videoUrl;
  final String? caption;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool? isLikedByMe;
  final DateTime createdAt;
  final int? duration; // 👈 ADD THIS LINE

  Reel({
    required this.reelId,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyCity,
    required this.ownerUserId,
    required this.ownerName,
    required this.ownerDisplayId,
    this.ownerProfilePic,
    required this.isVerifiedOwner,
    required this.videoUrl,
    this.caption,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    this.isLikedByMe,
    required this.createdAt,
    this.duration, // 👈 ADD THIS LINE
  });

  factory Reel.fromJson(Map<String, dynamic> json) {
    return Reel(
      reelId: json['reelId'] ?? 0,
      propertyId: json['propertyId'] ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      propertyCity: json['propertyCity'] ?? '',
      ownerUserId: json['ownerUserId'] ?? 0,
      ownerName: json['ownerName'] ?? 'Owner',
      ownerDisplayId: json['ownerDisplayId'] ?? '',
      ownerProfilePic: json['ownerProfilePic'],
      isVerifiedOwner: json['isVerifiedOwner'] ?? false,
      videoUrl: json['videoUrl'] ?? '',
      caption: json['caption'],
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      isLikedByMe: json['isLikedByMe'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      duration: json['duration'] ?? 20, // 👈 ADD THIS LINE (default 20 seconds)
    );
  }
}

class ReelComment {
  final int commentId;
  final int userId;
  final String userName;
  final String content;
  final bool isMine;
  final DateTime createdAt;

  ReelComment({
    required this.commentId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.isMine,
    required this.createdAt,
  });

  factory ReelComment.fromJson(Map<String, dynamic> json) {
    return ReelComment(
      commentId: json['commentId'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? 'User',
      content: json['content'] ?? '',
      isMine: json['isMine'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ReelFeedResponse {
  final List<Reel> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool last;

  ReelFeedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.last,
  });

  factory ReelFeedResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return ReelFeedResponse(
      content: (data['content'] as List?)?.map((item) => Reel.fromJson(item)).toList() ?? [],
      totalElements: data['totalElements'] ?? 0,
      totalPages: data['totalPages'] ?? 0,
      number: data['number'] ?? 0,
      size: data['size'] ?? 0,
      last: data['last'] ?? true,
    );
  }
}