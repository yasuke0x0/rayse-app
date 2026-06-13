import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/community_video.dart';
import '../providers/community_provider.dart';
import '../repository/community_video_repository.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  int _selectedWeekIndex = 0;
  late final List<({int week, int year})> _weeks;

  @override
  void initState() {
    super.initState();
    _weeks = _buildWeekList();
  }

  List<({int week, int year})> _buildWeekList() {
    final now = DateTime.now().toUtc();
    final currentWeek = CommunityVideoRepository.isoWeek(now);
    return List.generate(5, (i) {
      var week = currentWeek - i;
      var year = now.year;
      if (week <= 0) {
        week += 52;
        year -= 1;
      }
      return (week: week, year: year);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userTier = ref.watch(userTierProvider).valueOrNull ?? 'free';
    final selectedWeek = _weeks[_selectedWeekIndex];
    final weekKey = (selectedWeek.week, selectedWeek.year);
    final videosAsync = ref.watch(approvedVideosProvider(weekKey));
    final myReactions = ref.watch(myReactionsProvider).valueOrNull ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildWeekTabs(userTier),
            const SizedBox(height: 4),
            Expanded(
              child: _buildContent(
                  videosAsync, myReactions, userTier, weekKey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMUNITY',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Top videos from the community',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTabs(String userTier) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(_weeks.length, (i) {
          final isSelected = i == _selectedWeekIndex;
          final isArchive = i > 0;
          final showLock = isArchive && userTier == 'free' && !isSelected;
          return GestureDetector(
            onTap: () => setState(() => _selectedWeekIndex = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color:
                      isSelected ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLock) ...[
                    const Icon(Icons.lock_outline,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    i == 0 ? 'THIS WEEK' : 'WK ${_weeks[i].week}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<List<CommunityVideo>> videosAsync,
    Set<String> myReactions,
    String userTier,
    (int, int) weekKey,
  ) {
    // Archive lock for free users
    if (_selectedWeekIndex > 0 && userTier == 'free') {
      return _buildArchiveLocked();
    }

    return videosAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $e',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (videos) {
        if (videos.isEmpty) return _buildEmptyState();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: videos.length,
          itemBuilder: (_, i) => _VideoCard(
            video: videos[i],
            rank: i + 1,
            hasReacted: myReactions.contains(videos[i].id),
            weekKey: weekKey,
            onTap: () =>
                context.push('/community-video', extra: videos[i]),
          ),
        );
      },
    );
  }

  Widget _buildArchiveLocked() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.lock_rounded,
                  color: AppColors.accent, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              'ARCHIVES LOCKED',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Upgrade to Premium to browse past weeks' community highlights.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.push('/paywall'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'UNLOCK PREMIUM',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_outlined,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'NO VIDEOS YET',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to submit your video this week!',
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

// ─── Video card ────────────────────────────────────────────────────────────────

class _VideoCard extends ConsumerWidget {
  final CommunityVideo video;
  final int rank;
  final bool hasReacted;
  final (int, int) weekKey;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.rank,
    required this.hasReacted,
    required this.weekKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: rank == 1
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: Container(
                      color: const Color(0xFF27272A),
                      child: Center(
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          color:
                              AppColors.accent.withValues(alpha: 0.7),
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                ),
                // Rank badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: _RankBadge(rank: rank),
                ),
                // Samy Approved badge
                if (video.samyApproved)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _SamyBadge(),
                  ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '@${video.username}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('·',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted)),
                      const SizedBox(width: 6),
                      Text(
                        _skillLabel(video.skillId),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  if (video.caption.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.caption,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${video.score}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: hasReacted
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'fires',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(myReactionsProvider.notifier)
                              .toggle(video.id, weekKey);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: hasReacted
                                ? AppColors.accent
                                    .withValues(alpha: 0.15)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: hasReacted
                                  ? AppColors.accent
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥',
                                  style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                hasReacted ? 'FIRED' : 'FIRE IT',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: hasReacted
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  String _skillLabel(String id) => _skillLabels[id] ?? id;
}

// ─── Rank badge ────────────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: rank == 1
            ? AppColors.accent
            : Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$rank',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Samy Approved badge ───────────────────────────────────────────────────────

class _SamyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7C2D12),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            'SAMY APPROVED',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
