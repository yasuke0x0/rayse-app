import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/community_video.dart';

class UserRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final data = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> updateUserRole(
    String userId, {
    bool? isPremium,
    bool? isCreator,
  }) async {
    final updates = <String, dynamic>{};
    if (isPremium != null) updates['is_premium'] = isPremium;
    if (isCreator != null) updates['is_creator'] = isCreator;
    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }

  Future<void> banUser(String userId) async {
    await _client
        .from('profiles')
        .update({'is_banned': true}).eq('id', userId);
  }

  Future<void> unbanUser(String userId) async {
    await _client
        .from('profiles')
        .update({'is_banned': false}).eq('id', userId);
  }

  Future<int> fetchUserXP(String userId) async {
    final data = await _client
        .from('user_xp')
        .select('total_xp')
        .eq('user_id', userId)
        .maybeSingle();
    return (data?['total_xp'] as int?) ?? 0;
  }

  Future<List<CommunityVideo>> fetchUserVideos(String userId) async {
    final data = await _client
        .from('community_videos')
        .select('*, profiles!community_videos_user_id_fkey(username)')
        .eq('user_id', userId)
        .order('submitted_at', ascending: false);
    return (data as List)
        .map((m) =>
            CommunityVideo.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }
}
