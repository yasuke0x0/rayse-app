import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/skill_provider.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  final String skillId;
  const PracticeScreen({super.key, required this.skillId});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with TickerProviderStateMixin {
  static const int _totalSeconds =
      bool.fromEnvironment('dart.vm.product') ? 60 : 1;
  int _secondsLeft = _totalSeconds;
  Timer? _timer;
  int _tipIndex = 0;
  Timer? _tipTimer;

  late AnimationController _progressController;
  late AnimationController _tipFadeController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalSeconds),
    )..forward();

    _tipFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          t.cancel();
          _onTimerComplete();
        }
      });
    });

    _tipTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      _tipFadeController.reverse().then((_) {
        if (!mounted) return;
        final skill = ref
            .read(skillsProvider)
            .firstWhere((s) => s.id == widget.skillId);
        setState(() {
          _tipIndex = (_tipIndex + 1) % skill.tips.length;
        });
        _tipFadeController.forward();
      });
    });
  }

  void _onTimerComplete() {
    HapticFeedback.heavyImpact();
    context.pushReplacement('/skill-result/${widget.skillId}');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tipTimer?.cancel();
    _progressController.dispose();
    _tipFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skill = ref
        .watch(skillsProvider)
        .firstWhere((s) => s.id == widget.skillId);
    final sessions = skill.sessionsCompleted;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  Text(
                    skill.title.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PRACTICE SESSION ${sessions + 1} / 3',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Timer
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress ring
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (_, child) => CustomPaint(
                              size: const Size(240, 240),
                              painter: _CircleTimerPainter(
                                progress: 1.0 - _progressController.value,
                              ),
                            ),
                          ),
                          // Countdown
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_secondsLeft',
                                style: GoogleFonts.poppins(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'seconds',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Rotating tip
                    if (skill.tips.isNotEmpty)
                      FadeTransition(
                        opacity: _tipFadeController,
                        child: SizedBox(
                          width: 280,
                          child: Text(
                            skill.tips[_tipIndex % skill.tips.length],
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Stop button
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'STOP',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
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

class _CircleTimerPainter extends CustomPainter {
  final double progress; // 1.0 = full, 0.0 = empty

  const _CircleTimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleTimerPainter old) =>
      old.progress != progress;
}
