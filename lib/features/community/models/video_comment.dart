import 'package:flutter/foundation.dart';

@immutable
class VideoComment {
  final String id;
  final String videoId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final String username;

  const VideoComment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.body,
    required this.createdAt,
    required this.username,
  });

  factory VideoComment.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final username = profile?['username'] as String? ?? 'Anonymous';
    return VideoComment(
      id: map['id'] as String,
      videoId: map['video_id'] as String,
      userId: map['user_id'] as String,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      username: username,
    );
  }
}
