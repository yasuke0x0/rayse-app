import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../challenges/providers/challenge_provider.dart';
import '../../community/models/community_video.dart';
import '../../community/providers/community_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../skill_tree/models/skill.dart';
import '../../skill_tree/providers/skill_provider.dart';

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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.client.auth.currentUser;
    final profileAsync = ref.watch(profileProvider);
    final userTier = ref.watch(userTierProvider).valueOrNull ?? 'free';
    final totalXP = ref.watch(xpProvider);
    final skills = ref.watch(skillsProvider);
    final masteredCount =
        skills.where((s) => s.status == SkillStatus.mastered).length;
    final submissionsAsync = ref.watch(myTotalSubmissionsProvider);
    final pendingAsync = ref.watch(pendingVideosProvider);

    final email = user?.email ?? '';
    final profile = profileAsync.valueOrNull;
    final username = profile?['username'] as String? ??
        email.split('@').first;
    final firstName = profile?['first_name'] as String? ?? '';
    final lastName = profile?['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final avatarUrl = profile?['avatar_url'] as String?;
    final isCreator = profile?['is_creator'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          'PROFILE',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        _NotificationBell(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Avatar + identity ───────────────────────────────
                    GestureDetector(
                      onTap: () => context.push('/edit-profile'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.accent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.4),
                                    width: 2),
                                image: avatarUrl != null &&
                                        avatarUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(avatarUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: avatarUrl == null || avatarUrl.isEmpty
                                  ? Center(
                                      child: Text(
                                        firstName.isNotEmpty
                                            ? firstName[0].toUpperCase()
                                            : username.isNotEmpty
                                                ? username[0].toUpperCase()
                                                : '?',
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (fullName.isNotEmpty)
                                    Text(
                                      fullName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  Text(
                                    '@$username',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: fullName.isNotEmpty
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                      fontWeight: fullName.isNotEmpty
                                          ? FontWeight.normal
                                          : FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _RoleBadge(
                                      isCreator: isCreator,
                                      userTier: userTier),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit_outlined,
                                color: AppColors.textMuted, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Stats row ───────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.bolt,
                            value: '$totalXP',
                            label: 'XP EARNED',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star_rounded,
                            value: '$masteredCount',
                            label: 'MASTERED',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: submissionsAsync.when(
                            loading: () => const _StatCard(
                                icon: Icons.videocam,
                                value: '—',
                                label: 'VIDEOS'),
                            error: (e, st) => const _StatCard(
                                icon: Icons.videocam,
                                value: '—',
                                label: 'VIDEOS'),
                            data: (count) => _StatCard(
                              icon: Icons.videocam,
                              value: '$count',
                              label: 'VIDEOS',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── My videos ───────────────────────────────────────
                    _buildMyVideosSection(ref, context),

                    // ── Challenge history ───────────────────────────────
                    _ChallengeHistorySection(),

                    // ── Admin panel button (creators only) ──────────────
                    if (isCreator) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => context.push('/admin'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    AppColors.accent.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.admin_panel_settings,
                                    color: AppColors.accent,
                                    size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ADMIN PANEL',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    pendingAsync.when(
                                      loading: () => Text(
                                        'Review community videos',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color:
                                                AppColors.textSecondary),
                                      ),
                                      error: (e, st) =>
                                          const SizedBox.shrink(),
                                      data: (videos) => Text(
                                        videos.isEmpty
                                            ? 'No pending videos'
                                            : '${videos.length} video${videos.length == 1 ? '' : 's'} to review',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: videos.isEmpty
                                              ? AppColors.textSecondary
                                              : AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (pendingAsync.valueOrNull?.isNotEmpty ==
                                  true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${pendingAsync.valueOrNull!.length}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios,
                                  color: AppColors.textMuted, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── Upgrade banner (free users only) ────────────────
                    if (userTier == 'free' && !isCreator) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => context.push('/paywall'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C2D12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.accent
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Text('⚡',
                                  style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UPGRADE TO PREMIUM',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'Submit videos, access archives & more',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: AppColors.accent, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Pinned log out button ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: GestureDetector(
                onTap: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'LOG OUT',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyVideosSection(WidgetRef ref, BuildContext context) {
    final videosAsync = ref.watch(myAllVideosProvider);

    return videosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (videos) {
        if (videos.isEmpty) return const SizedBox.shrink();

        // Group counts (challenge videos only for live/pending)
        final challengeVideos = videos.where((v) => v.isChallenge);
        final personalCount = videos.where((v) => !v.isChallenge).length;
        final liveCount = challengeVideos
            .where((v) => v.status == VideoStatus.approved)
            .length;
        final pendingCount = challengeVideos
            .where((v) => v.status == VideoStatus.pending)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Text(
                  'MY VIDEOS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
                if (personalCount > 0)
                  _MiniPill(
                      label: '$personalCount PERSONAL',
                      bg: const Color(0xFF27272A),
                      fg: AppColors.textMuted),
                if (liveCount > 0) ...[
                  const SizedBox(width: 6),
                  _MiniPill(
                      label: '$liveCount LIVE',
                      bg: const Color(0xFF14532D),
                      fg: const Color(0xFF4ADE80)),
                ],
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  _MiniPill(
                      label: '$pendingCount PENDING',
                      bg: const Color(0xFF3F3F46),
                      fg: AppColors.textSecondary),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal scroll of video cards
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) =>
                    _VideoCard(video: videos[i], context: context),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Challenge history section ──────────────────────────────────────────────

class _ChallengeHistorySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(myChallengeHistoryProvider);
    final history = historyAsync.valueOrNull;
    if (history == null || history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CHALLENGE HISTORY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${history.length} ENTERED',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...history.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HistoryRow(entry: entry),
              )),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final MyChallengeHistoryEntry entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final skillName =
        _skillLabels[entry.challenge.skillId] ?? entry.challenge.skillId;
    final placement = entry.placement;
    final status = entry.video.status;
    final isTop3 = placement != null && placement <= 3;

    return GestureDetector(
      onTap: () =>
          context.push('/challenge-leaderboard', extra: entry.challenge),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTop3
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                color: isTop3 ? AppColors.accent : AppColors.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.challenge.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'WK ${entry.challenge.weekNumber} · $skillName',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            _statusChip(status, placement),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(VideoStatus status, int? placement) {
    if (status == VideoStatus.pending) {
      return _pill(
          'PENDING', const Color(0xFF3F3F46), AppColors.textSecondary);
    }
    if (status == VideoStatus.rejected) {
      return _pill('REJECTED', const Color(0xFF450A0A),
          const Color(0xFFF87171));
    }
    // approved
    if (placement == null) {
      return _pill('LIVE', const Color(0xFF14532D), const Color(0xFF4ADE80));
    }
    final (label, bg, fg) = switch (placement) {
      1 => ('🥇 #1', const Color(0xFF7C2D12), AppColors.accent),
      2 => ('🥈 #2', const Color(0xFF334155), const Color(0xFF94A3B8)),
      3 => ('🥉 #3', const Color(0xFF7C2D12), const Color(0xFFD97706)),
      _ => ('#$placement', const Color(0xFF27272A), AppColors.textSecondary),
    };
    return _pill(label, bg, fg);
  }

  Widget _pill(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.3,
          ),
        ),
      );
}

// ─── Mini status pill (for section header) ──────────────────────────────────────

class _MiniPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _MiniPill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Video card (horizontal scroll) ─────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final CommunityVideo video;
  final BuildContext context;

  const _VideoCard({required this.video, required this.context});

  @override
  Widget build(BuildContext _) {
    final (statusLabel, statusBg, statusFg) = !video.isChallenge
        ? ('PERSONAL', const Color(0xFF27272A), AppColors.textMuted)
        : switch (video.status) {
      VideoStatus.pending => (
          'PENDING',
          const Color(0xFF3F3F46),
          AppColors.textSecondary
        ),
      VideoStatus.approved => (
          'LIVE',
          const Color(0xFF14532D),
          const Color(0xFF4ADE80)
        ),
      VideoStatus.rejected => (
          'REJECTED',
          const Color(0xFF450A0A),
          const Color(0xFFF87171)
        ),
    };

    return GestureDetector(
      onTap: () => context.push('/community-video', extra: video),
      child: SizedBox(
        width: 130,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(13)),
                        child: Container(
                          color: const Color(0xFF27272A),
                          child: Center(
                            child: Icon(
                              Icons.play_circle_outline_rounded,
                              color:
                                  AppColors.accent.withValues(alpha: 0.5),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Status pill
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: statusFg,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    // Fire score (challenge + approved only)
                    if (video.isChallenge &&
                        video.status == VideoStatus.approved &&
                        video.score > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥',
                                  style: TextStyle(fontSize: 8)),
                              const SizedBox(width: 2),
                              Text(
                                '${video.score}',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title.isNotEmpty
                          ? video.title
                          : _skillLabels[video.skillId] ?? video.skillId,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(video.submittedAt),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

// ─── Role badge ───────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final bool isCreator;
  final String userTier;

  const _RoleBadge({required this.isCreator, required this.userTier});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = isCreator
        ? ('ADMIN', const Color(0xFF1E3A5F), const Color(0xFF60A5FA))
        : userTier == 'premium'
            ? ('PREMIUM', const Color(0xFF7C2D12), AppColors.accent)
            : ('FREE', const Color(0xFF27272A), AppColors.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Notification bell ────────────────────────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationCountProvider);
    final count = countAsync.valueOrNull ?? 0;

    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
                count > 0
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                color: count > 0
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                size: 24),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
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
