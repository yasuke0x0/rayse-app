import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../community/providers/community_provider.dart';
import '../models/workout_group.dart';
import '../providers/workout_provider.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(workoutGroupsProvider);
    final todayAsync = ref.watch(todayWorkoutProvider);
    final userTier = ref.watch(userTierProvider).valueOrNull ?? 'free';
    final isPremium = userTier == 'premium';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _GridOverlay()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ─── Header ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROGRAMS',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pick a track, train your way',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Today's recommended ─────────────────────────────
                SliverToBoxAdapter(
                  child: todayAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (workout) => Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: _TodayHero(
                        workoutId: workout.id,
                        title: workout.title,
                        durationMinutes: workout.durationMinutes,
                        focusArea: workout.focusArea,
                      ),
                    ),
                  ),
                ),

                // ─── Section label ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text(
                      'PROGRAM GROUPS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                // ─── Group grid ──────────────────────────────────────
                groupsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load programs.',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  data: (groups) => SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _GroupCard(
                          group: groups[i],
                          isUnlocked: isPremium || groups[i].isFreeTier,
                        ),
                        childCount: groups.length,
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

// ─── Today's hero card ────────────────────────────────────────────────────

class _TodayHero extends StatelessWidget {
  final String workoutId;
  final String title;
  final int durationMinutes;
  final String focusArea;

  const _TodayHero({
    required this.workoutId,
    required this.title,
    required this.durationMinutes,
    required this.focusArea,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/workout/play/$workoutId'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "TODAY'S WORKOUT",
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$durationMinutes min · $focusArea',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Group card ───────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final WorkoutGroup group;
  final bool isUnlocked;

  const _GroupCard({required this.group, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    final accent = group.accentColor;
    return GestureDetector(
      onTap: isUnlocked
          ? () => context.push('/workout/group/${group.id}')
          : () => context.push('/paywall'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? accent.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji + lock badge
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(group.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
                const Spacer(),
                if (!isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F3F46),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            color: AppColors.textMuted, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          'PREMIUM',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              group.title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              group.tagline,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.fitness_center_rounded,
                    color: accent, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${group.workouts.length} workouts',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.schedule_rounded,
                    color: AppColors.textMuted, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${group.totalMinutes} min',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grid overlay (reused theme) ──────────────────────────────────────────

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
