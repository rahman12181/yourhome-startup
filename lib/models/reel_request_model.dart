// lib/models/reel_request_model.dart

class AddCommentRequest {
  final String content;

  AddCommentRequest({required this.content});

  Map<String, dynamic> toJson() => {
    'content': content,
  };
}