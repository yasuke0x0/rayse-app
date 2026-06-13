import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/skill_provider.dart';

class MasteredScreen extends ConsumerStatefulWidget {
  final String skillId;
  const MasteredScreen({super.key, required this.skillId});

  @override
  ConsumerState<MasteredScreen> createState() => _MasteredScreenState();
}

class _MasteredScreenState extends ConsumerState<MasteredScreen>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _confettiController;
  late AnimationController _xpController;
  late Animation<double> _starScale;
  late Animation<int> _xpCount;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _starScale =
        CurvedAnimation(parent: _starController, curve: Curves.elasticOut);

    _starController.forward().then((_) {
      if (!mounted) return;
      // Pulse after scale in
      _starController.repeat(
          reverse: true, period: const Duration(seconds: 2));
    });

    final skill = ref
        .read(skillsProvider)
        .firstWhere((s) => s.id == widget.skillId);
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _xpCount = IntTween(begin: 0, end: skill.xpReward)
        .animate(CurvedAnimation(parent: _xpController, curve: Curves.easeOut));
    _xpController.forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    _confettiController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(skillsProvider);
    final skill = skills.firstWhere((s) => s.id == widget.skillId);
    final totalXP = ref.watch(xpProvider);
    final userTier = ref.watch(userTierProvider).valueOrNull ?? 'free';
    final unlockedNames = skill.unlockIds
        .map((id) {
          try {
            return skills.firstWhere((s) => s.id == id).title;
          } catch (_) {
            return id;
          }
        })
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Confetti
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context2, _) => CustomPaint(
              painter: _ConfettiPainter(progress: _confettiController.value),
              size: MediaQuery.of(context2).size,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              child: Column(
                children: [
                  // Star
                  ScaleTransition(
                    scale: _starScale,
                    child: const Text('⭐',
                        style: TextStyle(fontSize: 80)),
                  ),
                  const SizedBox(height: 20),
                  Text('SKILL MASTERED',
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      )),
                  const SizedBox(height: 8),
                  Text(skill.title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      )),
                  const SizedBox(height: 16),

                  // XP count-up
                  AnimatedBuilder(
                    animation: _xpCount,
                    builder: (_, child) => Text(
                      '+${_xpCount.value} XP',
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Progress recap card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _recapRow('Sessions completed', '3 / 3'),
                        const SizedBox(height: 8),
                        _recapRow('Total XP earned', '$totalXP XP'),
                        if (unlockedNames.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _recapRow(
                              'Skill unlocked', unlockedNames.join(', ')),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Share card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.accent, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('RAYSE',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                  letterSpacing: 2,
                                )),
                            Text('@samsjump',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('I JUST MASTERED',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.5,
                            )),
                        const SizedBox(height: 4),
                        Text(skill.title,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(height: 8),
                        Text('🔥 Keep the streak going',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.accent,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Share button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Share.share(
                        'I just mastered ${skill.title} on Rayse! 🔥 @samsjump',
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('SHARE TO INSTAGRAM',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            letterSpacing: 0.8,
                          )),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Community CTA
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🎥',
                                style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              'COMMUNITY CHALLENGE',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Show the community how you do ${skill.title}. Top 10 this week get featured on @samsjump — 279K followers.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => userTier == 'premium'
                                ? context.push('/submit-video/${widget.skillId}')
                                : context.push('/paywall'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              userTier == 'premium'
                                  ? 'SUBMIT YOUR VIDEO'
                                  : '🔒 PREMIUM — SUBMIT VIDEO',
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
                  const SizedBox(height: 16),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('CONTINUE',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recapRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              )),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              )),
        ],
      );
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final math.Random _rng = math.Random(42);

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 30; i++) {
      final x = _rng.nextDouble() * size.width;
      final startY = -20.0 - _rng.nextDouble() * 100;
      final speed = 0.3 + _rng.nextDouble() * 0.7;
      final y = startY + (size.height + 40) * ((progress * speed) % 1.0);
      final isOrange = i % 3 == 0;
      final paint = Paint()
        ..color = (isOrange ? AppColors.accent : Colors.white)
            .withValues(alpha: 0.15 + _rng.nextDouble() * 0.2);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 6 + _rng.nextDouble() * 6,
          height: 6 + _rng.nextDouble() * 6,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
