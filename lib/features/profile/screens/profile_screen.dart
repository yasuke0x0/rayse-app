import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/models/community_video.dart';
import '../../community/providers/community_provider.dart';
import '../../skill_tree/models/skill.dart';
import '../../skill_tree/providers/skill_provider.dart';

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
    final username = profileAsync.valueOrNull?['username'] as String? ??
        email.split('@').first;
    final isCreator = profileAsync.valueOrNull?['is_creator'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 24),

              // ── Avatar + identity ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Avatar circle
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            width: 2),
                      ),
                      child: Center(
                        child: Text(
                          username.isNotEmpty
                              ? username[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@$username',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _RoleBadge(
                              isCreator: isCreator, userTier: userTier),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Stats row ──────────────────────────────────────────────────
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
                          icon: Icons.videocam, value: '—', label: 'VIDEOS'),
                      error: (e, st) => const _StatCard(
                          icon: Icons.videocam, value: '—', label: 'VIDEOS'),
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

              // ── My videos ──────────────────────────────────────────────────
              _buildMyVideosSection(ref),
              const SizedBox(height: 16),

              // ── Admin panel button (creators only) ─────────────────────────
              if (isCreator) ...[
                GestureDetector(
                  onTap: () => context.push('/admin'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.admin_panel_settings,
                              color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      color: AppColors.textSecondary),
                                ),
                                error: (e, st) => const SizedBox.shrink(),
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
                        if (pendingAsync.valueOrNull?.isNotEmpty == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(999),
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
                const SizedBox(height: 16),
              ],

              // ── Upgrade banner (free users only) ───────────────────────────
              if (userTier == 'free' && !isCreator) ...[
                GestureDetector(
                  onTap: () => context.push('/paywall'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C2D12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('⚡',
                            style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
              ],

              // ── Log out ────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Text(
                    'LOG OUT',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyVideosSection(WidgetRef ref) {
    final videosAsync = ref.watch(myAllVideosProvider);

    return videosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (videos) {
        if (videos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 10),
            ...videos.map((v) => _VideoRow(video: v)),
          ],
        );
      },
    );
  }
}

// ─── Video row for profile ────────────────────────────────────────────────────

class _VideoRow extends StatelessWidget {
  final CommunityVideo video;
  const _VideoRow({required this.video});

  static const _skillLabels = {
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusBg, statusFg) = switch (video.status) {
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_outline_rounded,
                color: AppColors.accent.withValues(alpha: 0.7), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _skillLabels[video.skillId] ?? video.skillId,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _timeAgo(video.submittedAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (video.caption.isNotEmpty) ...[
                        Text(' · ',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.textMuted)),
                        Expanded(
                          child: Text(
                            video.caption,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: statusFg,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
