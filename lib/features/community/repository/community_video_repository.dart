import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/community_video.dart';

// Select string that joins both submitter and reviewer profiles
const _selectWithReviewer =
    '*, profiles!community_videos_user_id_fkey(username), reviewer:profiles!community_videos_reviewed_by_fkey(username)';

// Select string for queries that don't need reviewer info
const _selectBasic = '*, profiles!community_videos_user_id_fkey(username)';

class CommunityVideoRepository {
  final SupabaseClient _client = SupabaseService.client;

  // Upload video bytes to Supabase Storage (web + mobile compatible)
  Future<String> uploadVideo({
    required String userId,
    required String skillId,
    required Uint8List bytes,
    required String extension,
    String? mimeType,
  }) async {
    final path =
        '$userId/$skillId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage.from('community-videos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: mimeType ?? 'video/mp4',
          ),
        );
    return _client.storage.from('community-videos').getPublicUrl(path);
  }

  // Submit a challenge video (pending admin approval)
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
      'is_challenge': true,
      'week_number': isoWeek(now),
      'week_year': now.year,
    });
  }

  // Submit a personal skill video (auto-approved, private)
  Future<void> submitPersonalVideo({
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
      'status': 'approved',
      'is_challenge': false,
      'week_number': isoWeek(now),
      'week_year': now.year,
    });
  }

  // Fetch pending videos (admin only)
  Future<List<CommunityVideo>> fetchPendingVideos() async {
    final data = await _client
        .from('community_videos')
        .select(_selectBasic)
        .eq('status', 'pending')
        .order('submitted_at', ascending: true);
    return _parseList(data);
  }

  // Approve a video
  Future<void> approveVideo(String id, {String? reviewedBy}) async {
    await _client.from('community_videos').update({
      'status': 'approved',
      'reviewed_at': DateTime.now().toIso8601String(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
    }).eq('id', id);
  }

  // Revert a video back to pending
  Future<void> revertToPending(String id) async {
    await _client.from('community_videos').update({
      'status': 'pending',
      'reviewed_at': null,
      'reviewed_by': null,
    }).eq('id', id);
  }

  // Reject a video
  Future<void> rejectVideo(String id, {String? reviewedBy}) async {
    await _client.from('community_videos').update({
      'status': 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
    }).eq('id', id);
  }

  // Fetch filtered videos for admin "All Videos" tab
  Future<List<CommunityVideo>> fetchFilteredVideos({
    String? status,
    String? skillId,
    int? weekNumber,
    int? weekYear,
    int limit = 50,
  }) async {
    var query = _client.from('community_videos').select(_selectWithReviewer);

    if (status != null) query = query.eq('status', status);
    if (skillId != null) query = query.eq('skill_id', skillId);
    if (weekNumber != null) query = query.eq('week_number', weekNumber);
    if (weekYear != null) query = query.eq('week_year', weekYear);

    final data =
        await query.order('submitted_at', ascending: false).limit(limit);
    return _parseList(data);
  }

  // Fetch top N approved videos for a specific skill this week
  Future<List<CommunityVideo>> fetchTopVideosForSkill({
    required String skillId,
    required int weekNumber,
    required int weekYear,
    int limit = 3,
  }) async {
    final data = await _client
        .from('community_videos')
        .select(_selectBasic)
        .eq('status', 'approved')
        .eq('skill_id', skillId)
        .eq('week_number', weekNumber)
        .eq('week_year', weekYear)
        .order('score', ascending: false)
        .limit(limit);
    return _parseList(data);
  }

  // Fetch user's own submissions for a skill
  Future<List<CommunityVideo>> fetchMyVideos(
      String userId, String skillId) async {
    final data = await _client
        .from('community_videos')
        .select(_selectBasic)
        .eq('user_id', userId)
        .eq('skill_id', skillId)
        .order('submitted_at', ascending: false);
    return _parseList(data);
  }

  // Fetch approved videos for a week, sorted by score (top 10)
  Future<List<CommunityVideo>> fetchApprovedVideos({
    required int weekNumber,
    required int weekYear,
  }) async {
    final data = await _client
        .from('community_videos')
        .select(_selectBasic)
        .eq('status', 'approved')
        .eq('week_number', weekNumber)
        .eq('week_year', weekYear)
        .order('score', ascending: false)
        .limit(10);
    return _parseList(data);
  }

  // Toggle fire reaction via RPC
  Future<bool> toggleReaction(String videoId) async {
    final result = await _client
        .rpc('toggle_reaction', params: {'p_video_id': videoId});
    return result as bool;
  }

  // Fetch the set of video IDs the current user has reacted to
  Future<Set<String>> fetchMyReactions(String userId) async {
    final data = await _client
        .from('community_reactions')
        .select('video_id')
        .eq('user_id', userId);
    return (data as List).map((m) => m['video_id'] as String).toSet();
  }

  // Fetch all videos submitted by the current user
  Future<List<CommunityVideo>> fetchAllMyVideos(String userId) async {
    final data = await _client
        .from('community_videos')
        .select(_selectBasic)
        .eq('user_id', userId)
        .order('submitted_at', ascending: false);
    return _parseList(data);
  }

  // Total number of videos submitted by the current user
  Future<int> fetchMyTotalSubmissions(String userId) async {
    final data = await _client
        .from('community_videos')
        .select('id')
        .eq('user_id', userId);
    return (data as List).length;
  }

  // ISO week number helper
  static int isoWeek(DateTime date) {
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final weekDay = date.weekday;
    final week = ((dayOfYear - weekDay + 10) / 7).floor();
    return week.clamp(1, 53);
  }

  static List<CommunityVideo> _parseList(dynamic data) {
    return (data as List)
        .map((m) =>
            CommunityVideo.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }
}
