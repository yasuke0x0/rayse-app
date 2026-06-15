import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../challenges/providers/challenge_provider.dart';
import '../../community/models/community_video.dart';
import '../../community/providers/community_provider.dart';
import '../../community/repository/community_video_repository.dart';
import '../models/skill.dart';
import '../providers/skill_provider.dart';

class SkillDetailScreen extends ConsumerStatefulWidget {
  final String skillId;
  const SkillDetailScreen({super.key, required this.skillId});

  @override
  ConsumerState<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends ConsumerState<SkillDetailScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;
  bool _hasWatchedEnough = false;

  late List<AnimationController> _tipControllers;
  late List<Animation<double>> _tipAnimations;
  bool _tipsInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initVideo());
  }

  Future<void> _initVideo() async {
    final skill = ref.read(skillsProvider).firstWhere(
          (s) => s.id == widget.skillId,
          orElse: () => ref.read(skillsProvider).first,
        );

    final controller =
        VideoPlayerController.networkUrl(Uri.parse(skill.videoUrl));
    _videoController = controller;

    await controller.initialize();
    if (!mounted) return;

    _chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      allowFullScreen: true,
      placeholder: Container(color: AppColors.surface),
    );

    controller.addListener(_onVideoUpdate);

    // Already practiced before — no need to re-watch
    if (skill.sessionsCompleted > 0) _hasWatchedEnough = true;

    // Init tip animations
    _tipControllers = List.generate(
      skill.tips.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _tipAnimations = _tipControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _tipsInitialized = true;

    for (int i = 0; i < _tipControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) _tipControllers[i].forward();
      });
    }

    setState(() => _videoInitialized = true);
  }

  void _onVideoUpdate() {
    if (_videoController == null || _hasWatchedEnough) return;
    final dur = _videoController!.value.duration;
    final pos = _videoController!.value.position;
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds / dur.inMilliseconds >= 0.8) {
      setState(() => _hasWatchedEnough = true);
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _chewieController?.dispose();
    _videoController?.dispose();
    if (_tipsInitialized) {
      for (final c in _tipControllers) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(skillsProvider);
    final userTier = ref.watch(userTierProvider).valueOrNull ?? 'free';
    final skill = skills.firstWhere(
      (s) => s.id == widget.skillId,
      orElse: () => skills.first,
    );
    final isLocked = skill.status == SkillStatus.locked;
    final isPremiumLocked = !skill.isFreeNode && userTier == 'free';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, skill),
                  _buildVideoSection(skill, isPremiumLocked),
                  _buildSkillInfo(skill),
                  if (_tipsInitialized) _buildTips(skill),
                  if (skill.status == SkillStatus.mastered)
                    _buildCommunitySection(skill, userTier),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomCTA(context, skill, isPremiumLocked, isLocked),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Skill skill) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
          const Spacer(),
          _buildStatusBadge(skill),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Skill skill) {
    switch (skill.status) {
      case SkillStatus.locked:
        return _pill('🔒 LOCKED', const Color(0xFF3F3F46), AppColors.textMuted);
      case SkillStatus.available:
        return _pill('READY', const Color(0xFF27272A), AppColors.textSecondary);
      case SkillStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(3, (i) => Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < skill.sessionsCompleted
                      ? AppColors.accent
                      : Colors.transparent,
                  border: Border.all(
                    color: i < skill.sessionsCompleted
                        ? AppColors.accent
                        : const Color(0xFF52525B),
                    width: 1.5,
                  ),
                ),
              )),
              const SizedBox(width: 4),
              Text(
                '${skill.sessionsCompleted}/3 sessions',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      case SkillStatus.mastered:
        return _pill('⭐ MASTERED', const Color(0xFF7C2D12), AppColors.accent);
    }
  }

  Widget _pill(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.8,
            )),
      );

  Widget _buildVideoSection(Skill skill, bool isPremiumLocked) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Player or loading state
              if (_videoInitialized && _chewieController != null)
                Chewie(controller: _chewieController!)
              else
                Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),

              // Premium lock overlay
              if (isPremiumLocked)
                Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded,
                            color: AppColors.accent, size: 48),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/paywall'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('UNLOCK WITH PREMIUM',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                )),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Free users get 3 skills — upgrade to unlock all',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillInfo(Skill skill) {
    final tierLabel = skill.isFreeNode ? 'FREE' : 'PREMIUM';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _pill(tierLabel, AppColors.surface, AppColors.textSecondary),
            const SizedBox(width: 8),
            _pill('+ ${skill.xpReward} XP', const Color(0xFF7C2D12),
                AppColors.accent),
          ]),
          const SizedBox(height: 12),
          Text(
            skill.title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(skill.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              )),
        ],
      ),
    );
  }

  Widget _buildTips(Skill skill) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COACHING TIPS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                letterSpacing: 1.5,
              )),
          const SizedBox(height: 12),
          ...List.generate(skill.tips.length, (i) {
            return FadeTransition(
              opacity: _tipAnimations[i],
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_tipAnimations[i]),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(skill.tips[i],
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ))),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }


  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Widget _statusPill(VideoStatus status) {
    final (label, bg, fg) = switch (status) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCommunitySection(Skill skill, String userTier) {
    final myAsync = ref.watch(mySkillVideosProvider(skill.id));
    final rankingAsync = ref.watch(skillWeekRankingProvider(skill.id));
    final activeChallenge = ref.watch(activeChallengeProvider);
    final now = DateTime.now().toUtc();
    final currentWeek = CommunityVideoRepository.isoWeek(now);
    final currentYear = now.year;

    final allMyVideos = myAsync.valueOrNull ?? [];
    final rankedVideos = rankingAsync.valueOrNull ?? [];
    final myVideos = allMyVideos
        .where(
            (v) => v.weekNumber == currentWeek && v.weekYear == currentYear)
        .toList();
    final hasThisWeek = myVideos.isNotEmpty;
    final isActiveChallenge = activeChallenge?.skillId == skill.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActiveChallenge
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Challenge banner ──
            if (isActiveChallenge) ...[
              GestureDetector(
                onTap: () {
                  ref.read(homeTabIndexProvider.notifier).state = 2;
                  context.pop();
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "THIS WEEK'S CHALLENGE SKILL",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        'VIEW',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios,
                          color: AppColors.accent, size: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Header ──
            Row(
              children: [
                const Text('🎥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'COMMUNITY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Submit your ${skill.title} video and compete with the community.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            // ── My submissions ──
            if (myVideos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'MY WEEK SUBMISSIONS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              ...myVideos.map((v) {
                // Find rank: position in the full approved ranking list
                final rankIndex = rankedVideos.indexWhere((r) => r.id == v.id);
                final rank = rankIndex >= 0 ? rankIndex + 1 : null;

                return GestureDetector(
                  onTap: () =>
                      context.push('/community-video', extra: v),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: rank == 1
                            ? AppColors.accent.withValues(alpha: 0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Rank badge or status icon
                        if (rank != null)
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: rank == 1
                                  ? AppColors.accent
                                  : const Color(0xFF3F3F46),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '#$rank',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          Icon(Icons.play_circle_outline_rounded,
                              color:
                                  AppColors.accent.withValues(alpha: 0.6),
                              size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.caption.isNotEmpty
                                    ? v.caption
                                    : 'No caption',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: v.caption.isNotEmpty
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                rank != null
                                    ? '${_timeAgo(v.submittedAt)} · 🔥 ${v.score}'
                                    : _timeAgo(v.submittedAt),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _statusPill(v.status),
                      ],
                    ),
                  ),
                );
              }),
            ],

            // ── Submit CTA ──
            const SizedBox(height: 14),
            if (!hasThisWeek) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        myVideos.isEmpty
                            ? 'Be the first to submit — show your skills!'
                            : "You haven't posted this week yet — keep the streak!",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            GestureDetector(
              onTap: () => userTier == 'premium'
                  ? context.push('/submit-video/${widget.skillId}')
                  : context.push('/paywall'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: userTier == 'premium'
                      ? AppColors.accent
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: userTier == 'premium'
                        ? AppColors.accent
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    userTier == 'premium'
                        ? 'SUBMIT YOUR VIDEO'
                        : '🔒 PREMIUM — SUBMIT VIDEO',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: userTier == 'premium'
                          ? Colors.white
                          : AppColors.textSecondary,
                      letterSpacing: 0.8,
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

  Widget _buildBottomCTA(BuildContext context, Skill skill, bool isPremiumLocked,
      bool isLocked) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Builder(builder: (ctx) {
        if (isPremiumLocked || isLocked) {
          return SizedBox(
            width: double.infinity,
            child: _ctaButton(
              label: 'UNLOCK WITH PREMIUM',
              color: AppColors.accent,
              onTap: () => ctx.push('/paywall'),
            ),
          );
        }
        if (skill.status == SkillStatus.mastered) {
          return SizedBox(
            width: double.infinity,
            child: _ctaButton(
              label: '⭐ MASTERED — PRACTICE AGAIN',
              color: const Color(0xFF3F3F46),
              onTap: () => ctx.push('/skill-practice/${widget.skillId}'),
            ),
          );
        }
        return SizedBox(
          width: double.infinity,
          child: _ctaButton(
            label: _hasWatchedEnough
                ? 'START PRACTICE →'
                : 'WATCH THE VIDEO FIRST',
            color:
                _hasWatchedEnough ? AppColors.accent : const Color(0xFF3F3F46),
            onTap: _hasWatchedEnough
                ? () => ctx.push('/skill-practice/${widget.skillId}')
                : null,
          ),
        );
      }),
    );
  }

  Widget _ctaButton({
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
              child: Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ))),
        ),
      );
}
