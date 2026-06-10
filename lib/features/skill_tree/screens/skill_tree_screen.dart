import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../data/skill_tree_data.dart';
import '../models/skill_node.dart';
import '../providers/skill_tree_provider.dart';

const double _topPad = 80;
const double _tierGap = 150;
const double _bottomPad = 80;
const double _nodeRadius = 36;

class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(skillTreeProvider);
    final total = kSkillTree.length;
    final mastered = completed.length;
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

                        // Build positions map
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
                              // Connector lines
                              CustomPaint(
                                size: Size(width, canvasHeight),
                                painter: _TreeLinePainter(
                                  positions: positions,
                                  completed: completed,
                                ),
                              ),
                              // Nodes
                              for (final node in kSkillTree)
                                Positioned(
                                  left: positions[node.id]!.dx - _nodeRadius,
                                  top: positions[node.id]!.dy - _nodeRadius,
                                  child: _SkillNodeWidget(
                                    node: node,
                                    completed: completed,
                                    onTap: () => _showSkillSheet(
                                      context,
                                      ref,
                                      node,
                                      completed,
                                    ),
                                  ),
                                ),
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
}

// ─── Skill node widget ────────────────────────────────────────────────────────

class _SkillNodeWidget extends StatelessWidget {
  final SkillNode node;
  final Set<String> completed;
  final VoidCallback onTap;

  const _SkillNodeWidget({
    required this.node,
    required this.completed,
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

  Color _iconColorFor(String id) {
    switch (id) {
      case 'basic_bounce':
      case 'double_unders':
      case 'triple_unders':
      case 'freestyle':
        return AppColors.accent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = completed.contains(node.id);
    final isUnlocked = node.isUnlocked(completed);

    Widget circleContent;
    BoxDecoration circleDecoration;

    if (isCompleted) {
      circleDecoration = const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      );
      circleContent = const Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: 28,
      );
    } else if (isUnlocked) {
      circleDecoration = BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 2),
      );
      circleContent = Icon(
        _iconFor(node.id),
        color: _iconColorFor(node.id),
        size: 28,
      );
    } else {
      circleDecoration = BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      );
      circleContent = const Icon(
        Icons.lock_outline,
        color: AppColors.textMuted,
        size: 22,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: circleDecoration,
            child: Center(child: circleContent),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 88,
            child: Text(
              node.title,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
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

// ─── Skill detail bottom sheet ────────────────────────────────────────────────

void _showSkillSheet(
  BuildContext context,
  WidgetRef ref,
  SkillNode node,
  Set<String> completed,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _SkillSheet(node: node, completed: completed, ref: ref),
  );
}

class _SkillSheet extends StatelessWidget {
  final SkillNode node;
  final Set<String> completed;
  final WidgetRef ref;

  const _SkillSheet({
    required this.node,
    required this.completed,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = completed.contains(node.id);
    final isUnlocked = node.isUnlocked(completed);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag pill
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3F3F46),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle badge row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: isUnlocked
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Text(
                  node.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isUnlocked ? Colors.white : AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF166534),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'MASTERED',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4ADE80),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            node.title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            node.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Locked: show prerequisites
          if (!isUnlocked) ...[
            Text(
              'PREREQUISITES REQUIRED',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: node.prerequisiteIds.map((pid) {
                final prereq = kSkillTree.firstWhere((n) => n.id == pid);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    prereq.title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Action button
          if (!isCompleted && isUnlocked)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  ref
                      .read(skillTreeProvider.notifier)
                      .toggleSkill(node.id);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'MARK AS MASTERED',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

          if (isCompleted)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  ref
                      .read(skillTreeProvider.notifier)
                      .toggleSkill(node.id);
                  Navigator.pop(context);
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
                  'MARK INCOMPLETE',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Tree line painter ────────────────────────────────────────────────────────

class _TreeLinePainter extends CustomPainter {
  final Map<String, Offset> positions;
  final Set<String> completed;

  const _TreeLinePainter({
    required this.positions,
    required this.completed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in kSkillTree) {
      for (final prereqId in node.prerequisiteIds) {
        final from = positions[prereqId];
        final to = positions[node.id];
        if (from == null || to == null) continue;

        final bothCompleted =
            completed.contains(prereqId) && completed.contains(node.id);
        final parentCompleted = completed.contains(prereqId);

        final Color lineColor;
        if (bothCompleted) {
          lineColor = AppColors.accent.withValues(alpha: 0.8);
        } else if (parentCompleted) {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
