import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';

class DailyWorkoutScreen extends ConsumerWidget {
  const DailyWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayWorkoutProvider);
    final allAsync = ref.watch(allWorkoutsProvider);
    final completed = ref.watch(completedWorkoutsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _GridOverlay()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Icon(Icons.arrow_back,
                              color: AppColors.textPrimary, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'DAILY WORKOUT',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Today's workout ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: todayAsync.when(
                      loading: () => _SkeletonCard(height: 280),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (workout) => _TodayCard(
                        workout: workout,
                        isCompleted: completed.contains(workout.id),
                      ),
                    ),
                  ),
                ),

                // ── Week overview ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                    child: Text(
                      'THIS WEEK',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: allAsync.when(
                      loading: () => Column(
                        children: List.generate(
                          7,
                          (_) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SkeletonCard(height: 64),
                          ),
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (workouts) => Column(
                        children: workouts.map((w) {
                          final isToday =
                              w.weekday == DateTime.now().weekday;
                          final isDone = completed.contains(w.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _WeekRow(
                              workout: w,
                              isToday: isToday,
                              isCompleted: isDone,
                            ),
                          );
                        }).toList(),
                      ),
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

// ─── Today's workout card ─────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final Workout workout;
  final bool isCompleted;

  const _TodayCard({required this.workout, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF22C55E)
              : AppColors.accent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top badges
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF22C55E)
                      : AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCompleted ? 'COMPLETED ✓' : "TODAY'S WORKOUT",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              _DifficultyBadge(difficulty: workout.difficulty),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            workout.title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            workout.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              _StatChip(icon: Icons.schedule, label: '${workout.durationMinutes} min'),
              const SizedBox(width: 10),
              _StatChip(
                  icon: Icons.fitness_center_outlined,
                  label: '${workout.exercises.length} exercises'),
              const SizedBox(width: 10),
              _StatChip(
                  icon: Icons.bolt_outlined, label: workout.focusArea),
            ],
          ),
          const SizedBox(height: 20),

          // Exercise preview
          ...workout.exercises.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      e.targetLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 20),

          // CTA
          if (!isCompleted)
            GestureDetector(
              onTap: () => context.push('/workout/play/${workout.id}'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'START WORKOUT',
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
    );
  }
}

// ─── Week row ──────────────────────────────────────────────────────────────────

class _WeekRow extends StatelessWidget {
  final Workout workout;
  final bool isToday;
  final bool isCompleted;

  const _WeekRow({
    required this.workout,
    required this.isToday,
    required this.isCompleted,
  });

  static const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Day label
          SizedBox(
            width: 36,
            child: Text(
              _days[workout.weekday - 1],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isToday ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Workout name
          Expanded(
            child: Text(
              workout.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                color: isToday
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),

          // Duration
          Text(
            '${workout.durationMinutes}m',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),

          // Status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? const Color(0xFF22C55E)
                  : isToday
                      ? AppColors.accent
                      : AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      'beginner' => AppColors.levelBeginner,
      'intermediate' => AppColors.levelIntermediate,
      'advanced' => AppColors.levelAdvanced,
      _ => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
      );
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
