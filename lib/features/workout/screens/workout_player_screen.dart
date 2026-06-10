import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';

class WorkoutPlayerScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutPlayerScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutPlayerScreen> createState() =>
      _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends ConsumerState<WorkoutPlayerScreen> {
  int _exerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;

  void _advance(Workout workout) {
    final exercise = workout.exercises[_exerciseIndex];

    if (_isResting) {
      setState(() => _isResting = false);
      return;
    }

    if (_currentSet < exercise.sets) {
      if (exercise.restSeconds > 0) {
        setState(() => _isResting = true);
      } else {
        setState(() => _currentSet++);
      }
      return;
    }

    // Move to next exercise
    if (_exerciseIndex < workout.exercises.length - 1) {
      setState(() {
        _exerciseIndex++;
        _currentSet = 1;
        _isResting = false;
      });
    } else {
      // Workout done
      ref
          .read(completedWorkoutsProvider.notifier)
          .markComplete(workout.id);
      _showDoneDialog(workout);
    }
  }

  void _showDoneDialog(Workout workout) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    color: Color(0xFF22C55E), size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'WORKOUT DONE',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                workout.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  context.pop(); // close dialog
                  context.pop(); // back to daily workout
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'BACK TO WORKOUTS',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(workoutByIdProvider(widget.workoutId));

    return workoutAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Workout not found.',
              style: GoogleFonts.inter(color: AppColors.textMuted)),
        ),
      ),
      data: (workout) {
        if (workout == null) {
          return const Scaffold(backgroundColor: AppColors.background);
        }
        return _PlayerView(
          workout: workout,
          exerciseIndex: _exerciseIndex,
          currentSet: _currentSet,
          isResting: _isResting,
          onAdvance: () => _advance(workout),
          onExit: () => context.pop(),
        );
      },
    );
  }
}

// ─── Player view ──────────────────────────────────────────────────────────────

class _PlayerView extends StatelessWidget {
  final Workout workout;
  final int exerciseIndex;
  final int currentSet;
  final bool isResting;
  final VoidCallback onAdvance;
  final VoidCallback onExit;

  const _PlayerView({
    required this.workout,
    required this.exerciseIndex,
    required this.currentSet,
    required this.isResting,
    required this.onAdvance,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final exercise = workout.exercises[exerciseIndex];
    final total = workout.exercises.length;
    final progress = (exerciseIndex + 1) / total;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: onExit,
                    child: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      workout.title.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${exerciseIndex + 1}/$total',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Progress bar ─────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),

              // Progress dots
              Row(
                children: List.generate(total, (i) {
                  final done = i < exerciseIndex;
                  final current = i == exerciseIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: current ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: done || current
                            ? AppColors.accent
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 48),

              if (isResting)
                _RestView(exercise: exercise, currentSet: currentSet)
              else
                _ExerciseView(exercise: exercise, currentSet: currentSet),

              const Spacer(),

              // ── CTA ──────────────────────────────────────────────────────
              GestureDetector(
                onTap: onAdvance,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isResting
                        ? 'SKIP REST'
                        : currentSet < exercise.sets
                            ? 'SET DONE — NEXT SET'
                            : exerciseIndex < workout.exercises.length - 1
                                ? 'EXERCISE DONE — NEXT'
                                : 'FINISH WORKOUT',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Exercise view ────────────────────────────────────────────────────────────

class _ExerciseView extends StatelessWidget {
  final Exercise exercise;
  final int currentSet;

  const _ExerciseView({required this.exercise, required this.currentSet});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Set badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Text(
            'SET $currentSet OF ${exercise.sets}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Exercise name
        Text(
          exercise.name,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),

        // Target
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                exercise.targetLabel,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Instruction
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            exercise.instruction,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Rest view ────────────────────────────────────────────────────────────────

class _RestView extends StatelessWidget {
  final Exercise exercise;
  final int currentSet;

  const _RestView({required this.exercise, required this.currentSet});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'REST',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${exercise.restSeconds}s',
          style: GoogleFonts.poppins(
            fontSize: 64,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rest between sets',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'UP NEXT',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${exercise.name} — Set ${currentSet + 1} of ${exercise.sets}',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
