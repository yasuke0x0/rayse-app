import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/challenge.dart';
import '../models/leaderboard_entry.dart';
import '../providers/challenge_provider.dart';

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
                // ── Header ───────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text(
                      'CHALLENGES',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // ── Content ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: challengesAsync.when(
                    loading: () => const _LoadingState(),
                    error: (_, _) => const _ErrorState(),
                    data: (challenges) => _ChallengesBody(challenges: challenges),
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
    final active = challenges.firstWhere(
      (c) => c.isActive,
      orElse: () => challenges.first,
    );
    final rest = challenges.where((c) => c.id != active.id).toList();
    final leaderboardAsync = ref.watch(leaderboardProvider(active.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Active challenge hero ──────────────────────────────────────────
          _ActiveChallengeCard(challenge: active),

          const SizedBox(height: 36),

          // ── Leaderboard ───────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LEADERBOARD',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                active.title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          leaderboardAsync.when(
            loading: () => const _LeaderboardSkeleton(),
            error: (_, _) => const SizedBox.shrink(),
            data: (entries) => _LeaderboardList(entries: entries),
          ),

          const SizedBox(height: 36),

          // ── More challenges ───────────────────────────────────────────────
          Text(
            'MORE CHALLENGES',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...rest.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChallengeListCard(challenge: c),
              )),
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
    final joined = ref.watch(joinedChallengesProvider).contains(challenge.id);

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
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _StatBadge(
                icon: Icons.people_outline,
                label:
                    '${_formatCount(challenge.participantCount)} joined',
              ),
              const SizedBox(width: 12),
              _StatBadge(
                icon: Icons.flag_outlined,
                label:
                    '${challenge.targetValue} ${challenge.unit}',
              ),
              const SizedBox(width: 12),
              _StatBadge(
                icon: Icons.schedule,
                label: '${challenge.durationDays}d',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // CTA
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: joined
                  ? null
                  : () => ref
                      .read(joinedChallengesProvider.notifier)
                      .join(challenge.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: joined ? AppColors.surface : AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                  border: joined
                      ? Border.all(color: AppColors.border)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  joined ? 'JOINED ✓' : 'JOIN CHALLENGE',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: joined
                        ? AppColors.textSecondary
                        : Colors.white,
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
    return '$n';
  }
}

// ─── Leaderboard ──────────────────────────────────────────────────────────────

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _LeaderboardList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          final isLast = i == entries.length - 1;
          return Column(
            children: [
              _LeaderboardRow(entry: entry),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    final rankColor = switch (entry.rank) {
      1 => const Color(0xFFFBBF24), // gold
      2 => const Color(0xFF94A3B8), // silver
      3 => const Color(0xFFD97706), // bronze
      _ => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: entry.isCurrentUser
          ? BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isTop3 ? rankColor : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar placeholder
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: entry.isCurrentUser
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: entry.isCurrentUser
                    ? AppColors.accent
                    : AppColors.border,
              ),
            ),
            child: Center(
              child: Text(
                entry.username[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: entry.isCurrentUser
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
              entry.isCurrentUser ? 'You' : entry.username,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight:
                    entry.isCurrentUser ? FontWeight.w600 : FontWeight.w400,
                color: entry.isCurrentUser
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),

          // Score
          Text(
            '${entry.score} ${entry.unit}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isTop3 ? rankColor : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

// ─── Challenge list card ───────────────────────────────────────────────────────

class _ChallengeListCard extends ConsumerWidget {
  final Challenge challenge;
  const _ChallengeListCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joined = ref.watch(joinedChallengesProvider).contains(challenge.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              _iconFor(challenge.type),
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatCount(challenge.participantCount)} joined · ${challenge.daysLeft}d left',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Join button
          GestureDetector(
            onTap: joined
                ? null
                : () => ref
                    .read(joinedChallengesProvider.notifier)
                    .join(challenge.id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: joined ? AppColors.surface : AppColors.accent,
                borderRadius: BorderRadius.circular(999),
                border: joined ? Border.all(color: AppColors.border) : null,
              ),
              child: Text(
                joined ? 'JOINED' : 'JOIN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: joined ? AppColors.textMuted : Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'reps' => Icons.repeat,
        'time' => Icons.timer_outlined,
        'streak' => Icons.local_fire_department_outlined,
        _ => Icons.emoji_events_outlined,
      };

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ─── Stat badge ───────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─── Loading / error ──────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Failed to load challenges.',
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
