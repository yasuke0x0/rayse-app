import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../challenges/providers/challenge_provider.dart';
import '../../community/providers/community_provider.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
  ) async {
    // Mark read first so the badge updates instantly
    if (!notif.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notif.id);
    }

    final data = notif.data;

    switch (notif.type) {
      case 'challenge_new':
        // Land on the challenges tab
        context.go('/home');
        ref.read(homeTabIndexProvider.notifier).state = 2;
        return;

      case 'challenge_placed':
        // Land on the leaderboard for the challenge
        final challengeId = data['challenge_id'] as String?;
        if (challengeId == null) return;
        final challenge = await ref
            .read(challengeRepositoryProvider)
            .fetchChallengeById(challengeId);
        if (!context.mounted) return;
        if (challenge == null) {
          _showSnack(context, 'Challenge not found');
          return;
        }
        context.push('/challenge-leaderboard', extra: challenge);
        return;

      case 'challenge_approved':
      case 'comment':
        // Land on the video detail
        final videoId = data['video_id'] as String?;
        if (videoId == null) return;
        final video = await ref
            .read(communityVideoRepositoryProvider)
            .fetchVideoById(videoId);
        if (!context.mounted) return;
        if (video == null) {
          _showSnack(context, 'Video not found');
          return;
        }
        context.push('/community-video', extra: video);
        return;

      default:
        // Unknown type — just mark read, no navigation
        return;
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'NOTIFICATIONS',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        ref.read(notificationsProvider.notifier).markAllAsRead(),
                    child: Text(
                      'MARK ALL READ',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded,
                              color: AppColors.textMuted, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications yet',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: notifications.length,
                    itemBuilder: (_, i) {
                      final notif = notifications[i];
                      return GestureDetector(
                        onTap: () => _handleTap(context, ref, notif),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: notif.isRead
                                ? AppColors.surface
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: notif.isRead
                                  ? AppColors.border
                                  : AppColors.accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: notif.isRead
                                      ? const Color(0xFF27272A)
                                      : AppColors.accent
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  switch (notif.type) {
                                    'challenge_new' =>
                                      Icons.celebration_outlined,
                                    'challenge_approved' =>
                                      Icons.emoji_events_outlined,
                                    'challenge_placed' =>
                                      Icons.military_tech_outlined,
                                    'comment' => Icons.comment_outlined,
                                    _ => Icons.notifications_outlined,
                                  },
                                  color: notif.isRead
                                      ? AppColors.textMuted
                                      : AppColors.accent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      notif.body,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _timeAgo(notif.createdAt),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!notif.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
