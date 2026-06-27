import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';

class WorkoutGroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const WorkoutGroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(workoutGroupByIdProvider(groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: groupAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (e, _) => Center(
            child: Text(
              'Could not load this program.',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          data: (group) {
            if (group == null) {
              return Center(
                child: Text(
                  'Program not found.',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              );
            }
            final accent = group.accentColor;
            return CustomScrollView(
              slivers: [
                // ─── Top bar ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.textPrimary),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Hero ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(group.emoji,
                              style: const TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          group.title,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          group.tagline,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.fitness_center_rounded,
                                color: accent, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${group.workouts.length} workouts',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Icon(Icons.schedule_rounded,
                                color: AppColors.textMuted, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${group.totalMinutes} min total',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Section label ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Text(
                      'WORKOUTS IN THIS PROGRAM',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                // ─── Workouts list ───────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WorkoutRow(
                          workout: group.workouts[i],
                          accent: accent,
                        ),
                      ),
                      childCount: group.workouts.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  final Workout workout;
  final Color accent;
  const _WorkoutRow({required this.workout, required this.accent});

  @override
  Widget build(BuildContext context) {
    final (diffLabel, diffBg, diffFg) = switch (workout.difficulty) {
      'beginner' => (
          'BEGINNER',
          const Color(0xFF14532D),
          const Color(0xFF4ADE80)
        ),
      'intermediate' => (
          'INTERMEDIATE',
          const Color(0xFF7C2D12),
          AppColors.accent
        ),
      'advanced' => (
          'ADVANCED',
          const Color(0xFF450A0A),
          const Color(0xFFF87171)
        ),
      _ => (
          'ALL LEVELS',
          const Color(0xFF27272A),
          AppColors.textSecondary
        ),
    };

    return GestureDetector(
      onTap: () => context.push('/workout/play/${workout.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.play_arrow_rounded,
                  color: accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: diffBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          diffLabel,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: diffFg,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${workout.durationMinutes} min',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${workout.focusArea}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}
