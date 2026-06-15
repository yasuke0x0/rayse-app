import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../community/providers/community_provider.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';

class ChallengeLeaderboardScreen extends ConsumerWidget {
  final Challenge challenge;
  const ChallengeLeaderboardScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync =
        ref.watch(challengeLeaderboardProvider(challenge.id));
    final currentUserId =
        ref.watch(profileProvider).valueOrNull?['id'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEADERBOARD',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          challenge.title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Leaderboard
            Expanded(
              child: leaderboardAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load leaderboard.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
                data: (videos) {
                  if (videos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_outlined,
                              color: AppColors.textMuted, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'No approved videos yet',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: videos.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                    itemBuilder: (_, i) {
                      final video = videos[i];
                      final isCurrentUser =
                          video.userId == currentUserId;
                      final rankColor = switch (i) {
                        0 => const Color(0xFFFBBF24),
                        1 => const Color(0xFF94A3B8),
                        2 => const Color(0xFFD97706),
                        _ => AppColors.textMuted,
                      };

                      return GestureDetector(
                        onTap: () => context.push(
                            '/community-video',
                            extra: video),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          decoration: isCurrentUser
                              ? BoxDecoration(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.06),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                )
                              : null,
                          child: Row(
                            children: [
                              // Rank
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? AppColors.accent
                                      : const Color(0xFF3F3F46),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '#${i + 1}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Avatar
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? AppColors.accent
                                          .withValues(alpha: 0.2)
                                      : AppColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCurrentUser
                                        ? AppColors.accent
                                        : AppColors.border,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    video.username[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrentUser
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Username
                              Expanded(
                                child: Text(
                                  isCurrentUser
                                      ? 'You'
                                      : '@${video.username}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isCurrentUser
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isCurrentUser
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),

                              // Score
                              const Text('🔥',
                                  style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                '${video.score}',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: i <= 2
                                      ? rankColor
                                      : AppColors.textPrimary,
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
