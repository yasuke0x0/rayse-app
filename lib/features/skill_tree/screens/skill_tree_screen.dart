import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../data/skill_tree_data.dart';
import '../models/skill.dart';
import '../models/skill_node.dart';
import '../../community/providers/community_provider.dart';
import '../providers/skill_provider.dart';

const double _topPad = 80;
const double _tierGap = 150;
const double _bottomPad = 80;
const double _nodeRadius = 36;

class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(skillsProvider);
    final totalXP = ref.watch(xpProvider);
    final userTier = ref.watch(userTierProvider).valueOrNull ?? 'free';

    final mastered =
        skills.where((s) => s.status == SkillStatus.mastered).length;
    final total = skills.length;
    final progress = total > 0 ? mastered / total : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _GridOverlay()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SKILL TREE',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$mastered / $total SKILLS MASTERED',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // XP badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C2D12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '⚡ $totalXP XP',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                // Tree canvas
                Expanded(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final canvasHeight =
                            _topPad + 4 * _tierGap + _bottomPad;
                        final positions = <String, Offset>{};
                        for (final node in kSkillTree) {
                          final x = width * node.xFraction;
                          final y = _topPad + node.tier * _tierGap;
                          positions[node.id] = Offset(x, y);
                        }

                        return SizedBox(
                          width: width,
                          height: canvasHeight,
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: Size(width, canvasHeight),
                                painter: _TreeLinePainter(
                                  positions: positions,
                                  skills: skills,
                                ),
                              ),
                              for (final node in kSkillTree)
                                Builder(builder: (ctx) {
                                  Skill? skill;
                                  try {
                                    skill = skills
                                        .firstWhere((s) => s.id == node.id);
                                  } catch (_) {}
                                  if (skill == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Positioned(
                                    left: positions[node.id]!.dx - _nodeRadius,
                                    top: positions[node.id]!.dy - _nodeRadius,
                                    child: _SkillNodeWidget(
                                      node: node,
                                      skill: skill,
                                      onTap: () => _handleNodeTap(
                                        context,
                                        ref,
                                        skill!,
                                        userTier,
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleNodeTap(
    BuildContext context,
    WidgetRef ref,
    Skill skill,
    String userTier,
  ) {
    if (skill.status == SkillStatus.locked) {
      if (!skill.isFreeNode && userTier == 'free') {
        context.push('/paywall');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Complete previous skills first',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      context.push('/skill-detail/${skill.id}');
    }
  }
}

// ─── Skill node widget ────────────────────────────────────────────────────────

class _SkillNodeWidget extends StatelessWidget {
  final SkillNode node;
  final Skill skill;
  final VoidCallback onTap;

  const _SkillNodeWidget({
    required this.node,
    required this.skill,
    required this.onTap,
  });

  IconData _iconFor(String id) {
    switch (id) {
      case 'basic_bounce':
        return Icons.radio_button_checked;
      case 'forward_jump':
        return Icons.arrow_upward;
      case 'backward_jump':
        return Icons.arrow_downward;
      case 'alt_steps':
        return Icons.directions_run;
      case 'double_unders':
        return Icons.fast_forward;
      case 'cross_overs':
        return Icons.close;
      case 'side_swing':
        return Icons.swap_horiz;
      case 'triple_unders':
        return Icons.bolt;
      case 'cross_double':
        return Icons.shuffle;
      case 'releases':
        return Icons.open_in_full;
      case 'freestyle':
        return Icons.star;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = skill.status;
    Widget circleContent;
    BoxDecoration circleDecoration;

    switch (status) {
      case SkillStatus.mastered:
        circleDecoration = const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        );
        circleContent = const Icon(Icons.star_rounded,
            color: Colors.white, size: 28);
      case SkillStatus.completed:
        circleDecoration = const BoxDecoration(
          color: Color(0xFF3F3F46),
          shape: BoxShape.circle,
        );
        circleContent = Icon(_iconFor(node.id), color: AppColors.accent, size: 28);
      case SkillStatus.available:
        circleDecoration = BoxDecoration(
          color: const Color(0xFF3F3F46),
          shape: BoxShape.circle,
          border:
              Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        );
        circleContent =
            Icon(_iconFor(node.id), color: Colors.white, size: 28);
      case SkillStatus.locked:
        circleDecoration = BoxDecoration(
          color: const Color(0xFF27272A),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1),
        );
        circleContent = const Icon(Icons.lock_outline_rounded,
            color: AppColors.textMuted, size: 22);
    }

    final Widget circle;

    if (status == SkillStatus.completed) {
      circle = SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(72, 72),
              painter: _ArcProgressPainter(
                progress: skill.sessionsCompleted / 3,
              ),
            ),
            Container(
              width: 62,
              height: 62,
              decoration: circleDecoration,
              child: Center(child: circleContent),
            ),
          ],
        ),
      );
    } else {
      circle = Container(
        width: 72,
        height: 72,
        decoration: circleDecoration,
        child: Center(child: circleContent),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          const SizedBox(height: 8),
          SizedBox(
            width: 88,
            child: Text(
              node.title,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: status == SkillStatus.locked
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Arc progress painter (completed nodes) ───────────────────────────────────

class _ArcProgressPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0

  const _ArcProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Track ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF3F3F46)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcProgressPainter old) =>
      old.progress != progress;
}

// ─── Tree line painter ────────────────────────────────────────────────────────

class _TreeLinePainter extends CustomPainter {
  final Map<String, Offset> positions;
  final List<Skill> skills;

  const _TreeLinePainter({required this.positions, required this.skills});

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in kSkillTree) {
      for (final prereqId in node.prerequisiteIds) {
        final from = positions[prereqId];
        final to = positions[node.id];
        if (from == null || to == null) continue;

        Skill? fromSkill;
        Skill? toSkill;
        try {
          fromSkill = skills.firstWhere((s) => s.id == prereqId);
        } catch (_) {}
        try {
          toSkill = skills.firstWhere((s) => s.id == node.id);
        } catch (_) {}

        final bothActive =
            (fromSkill?.status == SkillStatus.completed ||
                fromSkill?.status == SkillStatus.mastered) &&
            (toSkill?.status == SkillStatus.completed ||
                toSkill?.status == SkillStatus.mastered);
        final parentActive = fromSkill?.status == SkillStatus.completed ||
            fromSkill?.status == SkillStatus.mastered;

        final Color lineColor;
        if (bothActive) {
          lineColor = AppColors.accent.withValues(alpha: 0.8);
        } else if (parentActive) {
          lineColor = AppColors.accent.withValues(alpha: 0.4);
        } else {
          lineColor = const Color(0xFF3F3F46);
        }

        final paint = Paint()
          ..color = lineColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(from, to, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
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
  bool shouldRepaint(covariant CustomPainter _) => false;
}
