import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/community_video.dart';

class CommunityVideoRepository {
  final SupabaseClient _client = SupabaseService.client;

  // Upload video file to Supabase Storage
  // Returns the public URL
  Future<String> uploadVideo({
    required String userId,
    required String skillId,
    required File file,
    required String extension,
  }) async {
    final path =
        '$userId/$skillId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage.from('community-videos').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: false),
        );
    return _client.storage.from('community-videos').getPublicUrl(path);
  }

  // Submit a video (inserts into community_videos with status=pending)
  Future<void> submitVideo({
    required String userId,
    required String skillId,
    required String videoUrl,
    required String caption,
  }) async {
    final now = DateTime.now().toUtc();
    await _client.from('community_videos').insert({
      'user_id': userId,
      'skill_id': skillId,
      'video_url': videoUrl,
      'caption': caption,
      'status': 'pending',
      'week_number': _isoWeek(now),
      'week_year': now.year,
    });
  }

  // Fetch pending videos (admin only)
  Future<List<CommunityVideo>> fetchPendingVideos() async {
    final data = await _client
        .from('community_videos')
        .select('*, profiles(username)')
        .eq('status', 'pending')
        .order('submitted_at', ascending: true);
    return (data as List)
        .map((m) =>
            CommunityVideo.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  // Approve a video
  Future<void> approveVideo(String id, {bool samyApproved = false}) async {
    await _client.from('community_videos').update({
      'status': 'approved',
      'samy_approved': samyApproved,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // Reject a video
  Future<void> rejectVideo(String id) async {
    await _client.from('community_videos').update({
      'status': 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // Fetch user's own submissions for a skill
  Future<List<CommunityVideo>> fetchMyVideos(
      String userId, String skillId) async {
    final data = await _client
        .from('community_videos')
        .select('*, profiles(username)')
        .eq('user_id', userId)
        .eq('skill_id', skillId)
        .order('submitted_at', ascending: false);
    return (data as List)
        .map((m) =>
            CommunityVideo.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  // ISO week number helper
  static int _isoWeek(DateTime date) {
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final weekDay = date.weekday;
    final week = ((dayOfYear - weekDay + 10) / 7).floor();
    return week.clamp(1, 53);
  }
}
