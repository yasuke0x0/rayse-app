import 'package:flutter/foundation.dart';

enum VideoStatus { pending, approved, rejected }

@immutable
class CommunityVideo {
  final String id;
  final String userId;
  final String skillId;
  final String videoUrl;
  final String caption;
  final VideoStatus status;
  final int weekNumber;
  final int weekYear;
  final int score;
  final bool isChallenge;
  final DateTime submittedAt;
  final String username;
  final String? reviewedBy; // reviewer username
  final DateTime? reviewedAt;

  const CommunityVideo({
    required this.id,
    required this.userId,
    required this.skillId,
    required this.videoUrl,
    required this.caption,
    required this.status,
    required this.weekNumber,
    required this.weekYear,
    required this.score,
    required this.isChallenge,
    required this.submittedAt,
    required this.username,
    this.reviewedBy,
    this.reviewedAt,
  });

  CommunityVideo copyWith({int? score}) {
    return CommunityVideo(
      id: id,
      userId: userId,
      skillId: skillId,
      videoUrl: videoUrl,
      caption: caption,
      status: status,
      weekNumber: weekNumber,
      weekYear: weekYear,
      score: score ?? this.score,
      isChallenge: isChallenge,
      submittedAt: submittedAt,
      username: username,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
    );
  }

  factory CommunityVideo.fromMap(Map<String, dynamic> map) {
    // Submitter username from profiles join
    final submitterProfile = map['profiles'] as Map<String, dynamic>?;
    final username =
        submitterProfile?['username'] as String? ?? 'Anonymous';

    // Reviewer username from reviewer join (aliased)
    final reviewerProfile = map['reviewer'] as Map<String, dynamic>?;
    final reviewerName = reviewerProfile?['username'] as String?;

    return CommunityVideo(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      skillId: map['skill_id'] as String,
      videoUrl: map['video_url'] as String,
      caption: map['caption'] as String? ?? '',
      status: _statusFromString(map['status'] as String),
      weekNumber: map['week_number'] as int,
      weekYear: map['week_year'] as int,
      score: map['score'] as int? ?? 0,
      isChallenge: map['is_challenge'] as bool? ?? false,
      submittedAt: DateTime.parse(map['submitted_at'] as String),
      username: username,
      reviewedBy: reviewerName,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
    );
  }

  static VideoStatus _statusFromString(String s) {
    switch (s) {
      case 'approved':
        return VideoStatus.approved;
      case 'rejected':
        return VideoStatus.rejected;
      default:
        return VideoStatus.pending;
    }
  }
}
