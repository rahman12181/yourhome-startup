class Review {
  final int reviewId;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.reviewId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['reviewId'] ?? 0,
      userName: json['userName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class CreateReviewRequest {
  final int rating;
  final String? comment;

  CreateReviewRequest({
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
    'rating': rating,
    if (comment != null) 'comment': comment,
  };
}