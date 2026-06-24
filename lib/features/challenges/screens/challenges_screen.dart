import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../community/models/community_video.dart';
import '../../community/providers/community_provider.dart';
import '../../skill_tree/models/skill.dart';
import '../../skill_tree/providers/skill_provider.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';

const _skillLabels = <String, String>{
  'basic_bounce': 'Basic Bounce',
  'forward_jump': 'Forward Jump',
  'backward_jump': 'Backward Jump',
  'alt_steps': 'Alternating Steps',
  'double_unders': 'Double Unders',
  'cross_overs': 'Cross Overs',
  'side_swing': 'Side Swing',
  'triple_unders': 'Triple Unders',
  'cross_double': 'Cross Double',
  'releases': 'Releases',
  'freestyle': 'Freestyle',
};

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _GridOverlay()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHALLENGES',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compete with the community every week',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: challengesAsync.when(
                    loading: () => const _LoadingState(),
                    error: (e, _) => _ErrorState(error: e.toString()),
                    data: (challenges) =>
                        _ChallengesBody(challenges: challenges),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _ChallengesBody extends ConsumerWidget {
  final List<Challenge> challenges;
  const _ChallengesBody({required this.challenges});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (challenges.isEmpty) return const _EmptyState();

    final active = challenges.where((c) => c.isCurrentWeek).firstOrNull;
    final past = challenges.where((c) => !c.isCurrentWeek).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active challenge
          if (active != null) ...[
            _ActiveChallengeCard(challenge: active),
            const SizedBox(height: 28),
            const _MyStatsSection(),
            const SizedBox(height: 28),
            _Podium(challenge: active),
          ] else ...[
            const _NoChallengeCard(),
            const SizedBox(height: 28),
            const _MyStatsSection(),
          ],

          // Past challenges
          if (past.isNotEmpty) ...[
            const SizedBox(height: 36),
            Text(
              'PAST CHALLENGES',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            ...past.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PastChallengeCard(challenge: c),
                )),
          ],
        ],
      ),
    );
  }
}

// ─── My challenge stats ───────────────────────────────────────────────────────

class _MyStatsSection extends ConsumerWidget {
  const _MyStatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myChallengeStatsProvider);
    final stats = statsAsync.valueOrNull;
    if (stats == null) return const SizedBox.shrink();
    if (stats.joined == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MY CHALLENGE STATS',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.emoji_events_outlined,
                value: '${stats.joined}',
                label: 'JOINED',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.local_fire_department_outlined,
                value: '${stats.totalFires}',
                label: 'TOTAL FIRES',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.military_tech_outlined,
                value: stats.bestPlacement == null
                    ? '—'
                    : '#${stats.bestPlacement}',
                label: 'BEST',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active challenge hero card ───────────────────────────────────────────────

class _ActiveChallengeCard extends ConsumerWidget {
  final Challenge challenge;
  const _ActiveChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSubmitted =
        ref.watch(hasSubmittedChallengeProvider(challenge.id)).valueOrNull ??
            false;
    final participantCount =
        ref.watch(challengeParticipantCountProvider(challenge.id)).valueOrNull;
    final userTier = ref.watch(userTierProvider).valueOrNull ?? 'free';
    final skills = ref.watch(skillsProvider);
    final skill = skills.where((s) => s.id == challenge.skillId).firstOrNull;
    final isPremiumLocked =
        skill != null && !skill.isFreeNode && userTier == 'free';
    final isNotMastered =
        skill != null && skill.status != SkillStatus.mastered;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "THIS WEEK'S CHALLENGE",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${challenge.daysLeft}d left',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            challenge.title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // Skill + stats
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  (_skillLabels[challenge.skillId] ?? challenge.skillId)
                      .toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (participantCount != null) ...[
                Icon(Icons.people_outline,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  _formatCount(participantCount),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Mastery progress (only when skill not mastered, not premium-locked)
          if (skill != null && isNotMastered && !isPremiumLocked) ...[
            _MasteryProgressPanel(skill: skill),
            const SizedBox(height: 14),
          ],

          // CTA — when submitted, show live placement; otherwise show action button
          if (hasSubmitted)
            _LivePlacementCTA(challenge: challenge)
          else
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  if (isPremiumLocked) {
                    context.push('/paywall');
                  } else if (isNotMastered) {
                    context.push('/skill-detail/${challenge.skillId}');
                  } else {
                    context.push(
                        '/submit-video/${challenge.skillId}?challenge=true');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isPremiumLocked
                        ? const Color(0xFF3F3F46)
                        : isNotMastered
                            ? AppColors.accent.withValues(alpha: 0.85)
                            : AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isPremiumLocked
                        ? '🔒 PREMIUM — SUBMIT VIDEO'
                        : isNotMastered
                            ? 'GO PRACTICE →'
                            : 'SUBMIT YOUR VIDEO',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n participants';
  }
}

// ─── Mastery progress panel (shown when challenge skill not yet mastered) ────

class _MasteryProgressPanel extends StatelessWidget {
  final Skill skill;
  const _MasteryProgressPanel({required this.skill});

  @override
  Widget build(BuildContext context) {
    final sessionsLeft = 3 - skill.sessionsCompleted;
    final progress = skill.sessionsCompleted / 3;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                'NOT ELIGIBLE YET',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${skill.sessionsCompleted}/3',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sessionsLeft == 1
                ? 'One more practice session to master ${skill.title} and unlock this challenge.'
                : 'Complete $sessionsLeft practice sessions on ${skill.title} to unlock this challenge.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.surface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live placement (shown to users who have submitted) ──────────────────────

class _LivePlacementCTA extends ConsumerWidget {
  final Challenge challenge;
  const _LivePlacementCTA({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync =
        ref.watch(myChallengePlacementProvider(challenge.id));
    final leaderboardAsync =
        ref.watch(challengeLeaderboardProvider(challenge.id));
    final placement = placementAsync.valueOrNull;
    final leaderboard = leaderboardAsync.valueOrNull ?? [];

    return GestureDetector(
      onTap: () =>
          context.push('/challenge-leaderboard', extra: challenge),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: placement != null && placement <= 3
                ? AppColors.accent
                : AppColors.border,
            width: placement != null && placement <= 3 ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Placement badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: placement == 1
                    ? AppColors.accent
                    : const Color(0xFF3F3F46),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                placement == null
                    ? '?'
                    : placement == 1
                        ? '🥇'
                        : placement == 2
                            ? '🥈'
                            : placement == 3
                                ? '🥉'
                                : '#$placement',
                style: GoogleFonts.poppins(
                  fontSize: placement != null && placement <= 3 ? 18 : 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        placement == null
                            ? 'SUBMITTED ✓'
                            : "YOU'RE CURRENTLY #$placement",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(placement, leaderboard),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  String _subtitle(int? placement, List<CommunityVideo> leaderboard) {
    if (placement == null) {
      return 'Pending review or building your score';
    }
    if (placement == 1) {
      if (leaderboard.length >= 2) {
        final firesAhead = leaderboard[0].score - leaderboard[1].score;
        return '🔥 Holding #1 by $firesAhead fire${firesAhead == 1 ? '' : 's'}';
      }
      return '🔥 Standing alone at the top';
    }
    final me = leaderboard[placement - 1];
    final above = leaderboard[placement - 2];
    final gap = above.score - me.score;
    return '${gap == 0 ? 'Tied' : '$gap 🔥'} from #${placement - 1} · See leaderboard';
  }
}

// ─── Top 3 podium ─────────────────────────────────────────────────────────────

class _Podium extends ConsumerWidget {
  final Challenge challenge;
  const _Podium({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync =
        ref.watch(challengeLeaderboardProvider(challenge.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TOP 3',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                context.push('/challenge-leaderboard', extra: challenge);
              },
              child: Text(
                'SEE ALL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        leaderboardAsync.when(
          loading: () => Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (videos) {
            if (videos.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No approved videos yet — be the first!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }
            final top3 = videos.take(3).toList();
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: List.generate(top3.length, (i) {
                  final video = top3[i];
                  final isLast = i == top3.length - 1;
                  final rankColor = switch (i) {
                    0 => const Color(0xFFFBBF24),
                    1 => const Color(0xFF94A3B8),
                    2 => const Color(0xFFD97706),
                    _ => AppColors.textMuted,
                  };
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () => context.push(
                            '/community-video',
                            extra: video),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
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
                              Expanded(
                                child: Text(
                                  '@${video.username}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Text('🔥',
                                  style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                '${video.score}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: rankColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Past challenge card ──────────────────────────────────────────────────────

class _PastChallengeCard extends ConsumerWidget {
  final Challenge challenge;
  const _PastChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTier = ref.watch(userTierProvider).valueOrNull ?? 'free';
    final isLocked = userTier == 'free';
    final placement =
        ref.watch(myChallengePlacementProvider(challenge.id)).valueOrNull;

    return GestureDetector(
      onTap: isLocked
          ? () => context.push('/paywall')
          : () => context.push('/challenge-leaderboard', extra: challenge),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: placement != null && placement <= 3
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.emoji_events_outlined,
                color: isLocked ? AppColors.textMuted : AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isLocked
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'WK ${challenge.weekNumber} · ${_skillLabels[challenge.skillId] ?? challenge.skillId}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (!isLocked) ...[
                    const SizedBox(height: 6),
                    _placementChip(placement),
                  ],
                ],
              ),
            ),
            if (isLocked)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F3F46),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '🔒 PREMIUM',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _placementChip(int? placement) {
    if (placement == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'You didn\'t enter',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    final (label, bg, fg) = switch (placement) {
      1 => ('🥇 #1 — YOU WON', const Color(0xFF7C2D12), AppColors.accent),
      2 => ('🥈 #2', const Color(0xFF334155), const Color(0xFF94A3B8)),
      3 => ('🥉 #3', const Color(0xFF7C2D12), const Color(0xFFD97706)),
      _ => (
          'YOU PLACED #$placement',
          const Color(0xFF27272A),
          AppColors.textSecondary
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── No active challenge ──────────────────────────────────────────────────────

class _NoChallengeCard extends StatelessWidget {
  const _NoChallengeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.textMuted, size: 40),
          const SizedBox(height: 12),
          Text(
            'NO CHALLENGE THIS WEEK',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back soon — a new challenge drops every week.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / loading / error states ───────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'NO CHALLENGES YET',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Challenges are coming soon — stay tuned!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({this.error = ''});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Failed to load challenges.\n$error',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }
}

// ─── Grid overlay ─────────────────────────────────────────────────────────────

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 80.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
