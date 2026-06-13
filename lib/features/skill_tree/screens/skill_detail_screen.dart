import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
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
    final userTier = ref.watch(userTierProvider);
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
                '${skill.sessionsCompleted}/3',
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
