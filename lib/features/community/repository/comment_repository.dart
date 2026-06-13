import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/video_comment.dart';

const _selectWithProfile = '*, profiles!video_comments_user_id_fkey(username)';

class CommentRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<VideoComment>> fetchComments(String videoId) async {
    final data = await _client
        .from('video_comments')
        .select(_selectWithProfile)
        .eq('video_id', videoId)
        .order('created_at', ascending: true);
    return (data as List)
        .map((m) => VideoComment.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<void> addComment({
    required String videoId,
    required String userId,
    required String body,
    required String commenterUsername,
  }) async {
    // Insert comment
    await _client.from('video_comments').insert({
      'video_id': videoId,
      'user_id': userId,
      'body': body,
    });

    // Look up video owner
    final video = await _client
        .from('community_videos')
        .select('user_id')
        .eq('id', videoId)
        .single();
    final ownerId = video['user_id'] as String;

    // Send notification if commenter is not the video owner
    if (ownerId != userId) {
      await _client.from('notifications').insert({
        'user_id': ownerId,
        'type': 'comment',
        'title': 'New Comment',
        'body': '@$commenterUsername commented on your video',
        'data': {'video_id': videoId},
      });
    }
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('video_comments').delete().eq('id', commentId);
  }
}
