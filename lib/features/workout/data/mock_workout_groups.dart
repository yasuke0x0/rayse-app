import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_group.dart';

/// 6 program groups (2 free + 4 premium). Each group holds 3-5 workouts.
///
/// One workout per group is tagged with a `weekday` (1-7) so the home tab's
/// "Today's Workout" banner can pick a daily recommendation from across the
/// whole catalog.
final mockWorkoutGroups = <WorkoutGroup>[
  // ═══════════════════════════════════════════════════════════════════════
  // FREE — Foundations
  // ═══════════════════════════════════════════════════════════════════════
  WorkoutGroup(
    id: 'foundations',
    title: 'FOUNDATIONS',
    tagline: 'Master your form. Build the base.',
    emoji: '🌱',
    accentColor: const Color(0xFF22C55E),
    isFreeTier: true,
    workouts: [
      const Workout(
        id: 'foundations_rhythm',
        title: 'Rhythm & Posture',
        description: 'Lock in clean form. Small movements, big consistency.',
        weekday: 1,
        durationMinutes: 8,
        difficulty: 'beginner',
        focusArea: 'Form',
        exercises: [
          Exercise(
            id: 'fr_1',
            name: 'Wrist Rotation Warmup',
            instruction:
                'Without the rope, rotate wrists in small circles. 30 each direction.',
            sets: 1,
            reps: 30,
            restSeconds: 10,
          ),
          Exercise(
            id: 'fr_2',
            name: 'Basic Bounce Slow',
            instruction:
                'Slow, steady bounce. Focus on landing softly on the balls of your feet.',
            sets: 3,
            reps: 30,
            restSeconds: 30,
          ),
          Exercise(
            id: 'fr_3',
            name: 'Tall Posture Hold',
            instruction:
                'Bounce with chin level, shoulders back, eyes forward. No looking down.',
            sets: 2,
            reps: 30,
            restSeconds: 30,
          ),
        ],
      ),
      const Workout(
        id: 'foundations_first_minute',
        title: 'First 1 Minute',
        description: 'Build the stamina to jump for one full minute unbroken.',
        weekday: 2,
        durationMinutes: 10,
        difficulty: 'beginner',
        focusArea: 'Endurance',
        exercises: [
          Exercise(
            id: 'ffm_1',
            name: '30 Second Builds',
            instruction:
                'Jump for 30 seconds straight. Rest 30. Repeat 4 times.',
            sets: 4,
            reps: 1,
            restSeconds: 30,
          ),
          Exercise(
            id: 'ffm_2',
            name: '45 Second Push',
            instruction: 'Extend to 45 seconds. 3 rounds.',
            sets: 3,
            reps: 1,
            restSeconds: 45,
          ),
          Exercise(
            id: 'ffm_3',
            name: 'Full Minute Attempt',
            instruction: 'One full minute, no breaks. Two attempts.',
            sets: 2,
            reps: 1,
            restSeconds: 60,
          ),
        ],
      ),
      const Workout(
        id: 'foundations_footwork',
        title: 'Footwork Basics',
        description: 'Develop coordination with alternating steps and shifts.',
        weekday: 3,
        durationMinutes: 12,
        difficulty: 'beginner',
        focusArea: 'Coordination',
        exercises: [
          Exercise(
            id: 'ffw_1',
            name: 'Alternating Steps',
            instruction:
                'Shift weight side to side as you jump. Like running in place.',
            sets: 3,
            reps: 30,
            restSeconds: 30,
          ),
          Exercise(
            id: 'ffw_2',
            name: 'Single Leg Hold',
            instruction:
                'Balance on one foot for 10 jumps, then switch. 3 rounds each leg.',
            sets: 3,
            reps: 10,
            restSeconds: 30,
          ),
        ],
      ),
      const Workout(
        id: 'foundations_tune_up',
        title: 'Form Tune-up',
        description: 'Refresh your fundamentals across all the basics.',
        durationMinutes: 15,
        difficulty: 'beginner',
        focusArea: 'Form',
        exercises: [
          Exercise(
            id: 'ftu_1',
            name: 'Slow Bounce Reset',
            instruction:
                '30 slow bounces focused on form. Reset whenever you feel off.',
            sets: 3,
            reps: 30,
            restSeconds: 30,
          ),
          Exercise(
            id: 'ftu_2',
            name: 'Forward Jump Drill',
            instruction:
                'Jump rope swinging forward. Build rhythm and find your timing.',
            sets: 3,
            reps: 20,
            restSeconds: 30,
          ),
          Exercise(
            id: 'ftu_3',
            name: 'Backward Jump',
            instruction:
                'Reverse the rope direction. Easier than it sounds with practice.',
            sets: 2,
            reps: 20,
            restSeconds: 30,
          ),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════
  // FREE — Quick Sessions
  // ═══════════════════════════════════════════════════════════════════════
  WorkoutGroup(
    id: 'quick_sessions',
    title: 'QUICK SESSIONS',
    tagline: '5-10 minutes. Daily-friendly.',
    emoji: '⚡',
    accentColor: const Color(0xFFFACC15),
    isFreeTier: true,
    workouts: [
      const Workout(
        id: 'quick_burner',
        title: '5-Minute Burner',
        description: 'Fast, intense, in and out. Perfect for busy days.',
        weekday: 4,
        durationMinutes: 5,
        difficulty: 'all',
        focusArea: 'Cardio',
        exercises: [
          Exercise(
            id: 'qb_1',
            name: 'Sprint Burst',
            instruction: '20 seconds max effort. Rest 10. Repeat 8 times.',
            sets: 8,
            reps: 1,
            restSeconds: 10,
          ),
        ],
      ),
      const Workout(
        id: 'quick_warmup',
        title: 'Pre-Game Warmup',
        description: 'Wake up the legs before practice or a workout.',
        durationMinutes: 7,
        difficulty: 'all',
        focusArea: 'Warmup',
        exercises: [
          Exercise(
            id: 'qw_1',
            name: 'Light Bounce',
            instruction:
                'Easy pace, get the blood moving. 60 seconds straight.',
            sets: 2,
            reps: 1,
            restSeconds: 30,
          ),
          Exercise(
            id: 'qw_2',
            name: 'Side-to-Side',
            instruction: 'Shift weight side to side as you jump.',
            sets: 2,
            reps: 20,
            restSeconds: 20,
          ),
        ],
      ),
      const Workout(
        id: 'quick_lunch',
        title: 'Lunch Break Set',
        description: 'Energizing midday session. No equipment changes.',
        durationMinutes: 10,
        difficulty: 'all',
        focusArea: 'Cardio',
        exercises: [
          Exercise(
            id: 'ql_1',
            name: '45/15 Intervals',
            instruction: '45 seconds on, 15 seconds off. 6 rounds.',
            sets: 6,
            reps: 1,
            restSeconds: 15,
          ),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════
  // PREMIUM — Cardio Burn
  // ═══════════════════════════════════════════════════════════════════════
  WorkoutGroup(
    id: 'cardio_burn',
    title: 'CARDIO BURN',
    tagline: 'High intensity. Real conditioning.',
    emoji: '🔥',
    accentColor: const Color(0xFFEF4444),
    isFreeTier: false,
    workouts: [
      const Workout(
        id: 'cardio_hiit',
        title: 'HIIT Intervals',
        description: '15 minutes of high-intensity intervals.',
        weekday: 5,
        durationMinutes: 15,
        difficulty: 'intermediate',
        focusArea: 'HIIT',
        exercises: [
          Exercise(
            id: 'ch_1',
            name: '40/20 Block A',
            instruction: '40 seconds hard, 20 seconds rest. 5 rounds.',
            sets: 5,
            reps: 1,
            restSeconds: 20,
          ),
          Exercise(
            id: 'ch_2',
            name: '40/20 Block B',
            instruction: 'Second block, same pattern.',
            sets: 5,
            reps: 1,
            restSeconds: 20,
          ),
        ],
      ),
      const Workout(
        id: 'cardio_sweat',
        title: '20-Min Sweat',
        description: 'Sustained moderate pace. Builds the engine.',
        durationMinutes: 20,
        difficulty: 'intermediate',
        focusArea: 'Endurance',
        exercises: [
          Exercise(
            id: 'cs_1',
            name: '4-Minute Block',
            instruction:
                'Sustained moderate pace for 4 minutes. Rest 1 minute. 4 rounds.',
            sets: 4,
            reps: 1,
            restSeconds: 60,
          ),
        ],
      ),
      const Workout(
        id: 'cardio_marathon',
        title: 'Endurance Marathon',
        description: '30 minutes. Pure stamina test.',
        durationMinutes: 30,
        difficulty: 'advanced',
        focusArea: 'Endurance',
        exercises: [
          Exercise(
            id: 'cm_1',
            name: 'Steady State',
            instruction: '10 minutes at a sustainable pace. 2-minute break.',
            sets: 3,
            reps: 1,
            restSeconds: 120,
          ),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════
  // PREMIUM — Skill Builders
  // ═══════════════════════════════════════════════════════════════════════
  WorkoutGroup(
    id: 'skill_builders',
    title: 'SKILL BUILDERS',
    tagline: 'Targeted drills for each move.',
    emoji: '🎯',
    accentColor: const Color(0xFF3B82F6),
    isFreeTier: false,
    workouts: [
      const Workout(
        id: 'skill_du',
        title: 'Double Under Drill',
        description: 'Build the timing and wrist speed for clean DUs.',
        weekday: 6,
        durationMinutes: 12,
        difficulty: 'intermediate',
        focusArea: 'Double Unders',
        exercises: [
          Exercise(
            id: 'sd_1',
            name: 'Wrist Speed Ladder',
            instruction:
                'Without rope, simulate fast wrist rotation. 30 seconds. 3 rounds.',
            sets: 3,
            reps: 1,
            restSeconds: 30,
          ),
          Exercise(
            id: 'sd_2',
            name: 'Single + Double Sets',
            instruction:
                'Pattern: 1 single, 1 double, repeat. Build coordination.',
            sets: 3,
            reps: 20,
            restSeconds: 45,
          ),
        ],
      ),
      const Workout(
        id: 'skill_co',
        title: 'Cross Over Lab',
        description: 'Lock in smooth, controlled cross overs.',
        durationMinutes: 15,
        difficulty: 'intermediate',
        focusArea: 'Cross Overs',
        exercises: [
          Exercise(
            id: 'sc_1',
            name: 'Cross Drill',
            instruction:
                'Cross arms in front of body as rope passes under. Slow and clean.',
            sets: 4,
            reps: 10,
            restSeconds: 45,
          ),
        ],
      ),
      const Workout(
        id: 'skill_tu',
        title: 'Triple Speed Work',
        description: 'Wrist speed and explosive jumps for triple unders.',
        durationMinutes: 18,
        difficulty: 'advanced',
        focusArea: 'Triple Unders',
        exercises: [
          Exercise(
            id: 'st_1',
            name: 'Jump Height Work',
            instruction:
                'Practice jumping higher without rope. 10 max-height jumps. 4 rounds.',
            sets: 4,
            reps: 10,
            restSeconds: 60,
          ),
          Exercise(
            id: 'st_2',
            name: 'Triple Attempts',
            instruction:
                'Single + single + triple pattern. 5 attempts. 3 rounds.',
            sets: 3,
            reps: 5,
            restSeconds: 90,
          ),
        ],
      ),
      const Workout(
        id: 'skill_release',
        title: 'Release Practice',
        description: 'Letting the rope go and catching it. Trick foundation.',
        durationMinutes: 15,
        difficulty: 'advanced',
        focusArea: 'Releases',
        exercises: [
          Exercise(
            id: 'sr_1',
            name: 'Side Swing Release',
            instruction: 'Swing rope to side, release, catch. 10 reps × 3.',
            sets: 3,
            reps: 10,
            restSeconds: 60,
          ),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════
  // PREMIUM — Freestyle Lab
  // ═══════════════════════════════════════════════════════════════════════
  WorkoutGroup(
    id: 'freestyle_lab',
    title: 'FREESTYLE LAB',
    tagline: 'Build combos. Find your style.',
    emoji: '🎨',
    accentColor: const Color(0xFFA855F7),
    isFreeTier: false,
    workouts: [
      const Workout(
        id: 'free_combo',
        title: 'Combo Architect',
        description: 'Sequence cross + double + release into a flow.',
        durationMinutes: 20,
        difficulty: 'advanced',
        focusArea: 'Freestyle',
        exercises: [
          Exercise(
            id: 'fc_1',
            name: 'Combo Drill',
            instruction: 'Cross → Double → Release. 5 clean reps. 4 rounds.',
            sets: 4,
            reps: 5,
            restSeconds: 90,
          ),
        ],
      ),
      const Workout(
        id: 'free_release',
        title: 'Release Flow',
        description: 'String multiple releases without losing tempo.',
        durationMinutes: 18,
        difficulty: 'advanced',
        focusArea: 'Releases',
        exercises: [
          Exercise(
            id: 'fr_1',
            name: 'Release Series',
            instruction: '3 releases in a row. 4 rounds.',
            sets: 4,
            reps: 3,
            restSeconds: 90,
          ),
        ],
      ),
      const Workout(
        id: 'free_show',
        title: 'Show-Style Practice',
        description: 'Perform a full 30-second flow for camera-ready content.',
        weekday: 7,
        durationMinutes: 25,
        difficulty: 'advanced',
        focusArea: 'Performance',
        exercises: [
          Exercise(
            id: 'fs_1',
            name: 'Routine Build',
            instruction:
                'Choreograph a 30-second flow combining 3+ skills.',
            sets: 3,
            reps: 1,
            restSeconds: 120,
          ),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════
  // PREMIUM — Challenge Prep is built dynamically in challenge_prep_builder.dart
  // (uses the user's tier's active challenge to inject the skill name).
  // The workoutGroupsProvider stitches it in at runtime.
  // ═══════════════════════════════════════════════════════════════════════
];

/// All workouts, flattened across groups (for player lookup, etc.)
List<Workout> allWorkouts() =>
    mockWorkoutGroups.expand((g) => g.workouts).toList();
