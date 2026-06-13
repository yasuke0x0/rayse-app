import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repository/comment_repository.dart';
import '../models/video_comment.dart';
import '../providers/community_provider.dart';
import '../../notifications/providers/notification_provider.dart';

final commentRepositoryProvider = Provider<CommentRepository>(
  (_) => CommentRepository(),
);

class VideoCommentsNotifier
    extends FamilyAsyncNotifier<List<VideoComment>, String> {
  @override
  Future<List<VideoComment>> build(String videoId) async {
    return ref.read(commentRepositoryProvider).fetchComments(videoId);
  }

  Future<void> addComment(String videoId, String body) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await ref.read(profileProvider.future);
    final username =
        profile?['username'] as String? ?? user.email?.split('@').first ?? 'user';

    await ref.read(commentRepositoryProvider).addComment(
          videoId: videoId,
          userId: user.id,
          body: body,
          commenterUsername: username,
        );
    ref.invalidateSelf();
    // Refresh notification count for other watchers
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> deleteComment(String commentId) async {
    // Optimistic removal
    state.whenData((comments) {
      state = AsyncData(comments.where((c) => c.id != commentId).toList());
    });
    try {
      await ref.read(commentRepositoryProvider).deleteComment(commentId);
    } catch (_) {
      ref.invalidateSelf();
    }
  }
}

final videoCommentsProvider = AsyncNotifierProvider.family<
    VideoCommentsNotifier, List<VideoComment>, String>(
  VideoCommentsNotifier.new,
);
