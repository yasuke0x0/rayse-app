import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/skill.dart';
import '../providers/skill_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String skillId;
  const ResultScreen({super.key, required this.skillId});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  int _reps = 0;
  bool _showXpAnim = false;
  late AnimationController _iconController;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale =
        CurvedAnimation(parent: _iconController, curve: Curves.elasticOut);
    _iconController.forward();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _handleGotIt(Skill skill) {
    ref.read(skillsProvider.notifier).completeSession(widget.skillId, _reps);
    setState(() => _showXpAnim = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      // Re-read updated skill
      final updatedSkill = ref
          .read(skillsProvider)
          .firstWhere((s) => s.id == widget.skillId);
      if (updatedSkill.status == SkillStatus.mastered) {
        context.pushReplacement('/skill-mastered/${widget.skillId}');
      } else {
        final sessions = updatedSkill.sessionsCompleted;
        final messenger = ScaffoldMessenger.of(context);
        context.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Session $sessions/3 complete! Keep going 🔥',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final skill = ref
        .watch(skillsProvider)
        .firstWhere((s) => s.id == widget.skillId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
              child: Column(
                children: [
                  // Animated trophy icon
                  ScaleTransition(
                    scale: _iconScale,
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.accent,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PRACTICE DONE!',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Rep counter
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'How many reps did you complete?',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RepButton(
                              icon: Icons.remove,
                              onTap: () => setState(() {
                                if (_reps > 0) _reps--;
                              }),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 60,
                              child: Text(
                                '$_reps',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 24),
                            _RepButton(
                              icon: Icons.add,
                              onTap: () => setState(() => _reps++),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {}, // skip does nothing to reps
                          child: Text(
                            'Skip',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Session progress dots
                  Column(
                    children: [
                      Text(
                        'SESSION PROGRESS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          // Preview +1 before tapping "I GOT IT";
                          // after tapping, provider has updated so show real count
                          final displayCount = _showXpAnim
                              ? skill.sessionsCompleted
                              : (skill.sessionsCompleted + 1).clamp(0, 3);
                          return Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < displayCount
                                  ? AppColors.accent
                                  : Colors.transparent,
                              border: Border.all(
                                color: i < displayCount
                                    ? AppColors.accent
                                    : const Color(0xFF3F3F46),
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_showXpAnim ? skill.sessionsCompleted : (skill.sessionsCompleted + 1).clamp(0, 3)} / 3 sessions to master',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // XP animation overlay
            if (_showXpAnim)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: _XpAnimWidget(xp: skill.xpReward),
              ),

            // Bottom buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                color: AppColors.background,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        label: 'NEEDS MORE PRACTICE',
                        bgColor: const Color(0xFF27272A),
                        onTap: () => context.pop(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        label: 'I GOT IT! ✓',
                        bgColor: AppColors.accent,
                        onTap:
                            _showXpAnim ? null : () => _handleGotIt(skill),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color bgColor;
  final VoidCallback? onTap;
  const _ActionButton(
      {required this.label, required this.bgColor, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
              child: Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ))),
        ),
      );
}

class _XpAnimWidget extends StatefulWidget {
  final int xp;
  const _XpAnimWidget({required this.xp});

  @override
  State<_XpAnimWidget> createState() => _XpAnimWidgetState();
}

class _XpAnimWidgetState extends State<_XpAnimWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -2),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Text(
              '+${widget.xp} XP',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      );
}
