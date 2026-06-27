import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_group.dart';

const _skillLabels = <String, String>{
  'basic_bounce': 'Basic Bounce',
  'forward_jump': 'Forward Jump',
  'backward_jump': 'Backward Jump',
  'alt_steps': 'Alternating Steps',
  'double_unders': 'Double Unders',
  'cross_overs': 'Cross Overs',
  'side_swing': 'Side Swing',
  'triple_unders': 'Triple Unders',
  'cross_double': 'Cross Double',
  'releases': 'Releases',
  'freestyle': 'Freestyle',
};

String skillLabel(String? skillId) =>
    skillId == null ? '' : (_skillLabels[skillId] ?? skillId);

/// Build the Challenge Prep group, customised for the active challenge skill.
/// When [skillId] is null, returns the generic fallback (no live challenge).
WorkoutGroup buildChallengePrepGroup({String? skillId}) {
  final hasSkill = skillId != null;
  final name = hasSkill ? skillLabel(skillId) : null;

  return WorkoutGroup(
    id: 'challenge_prep',
    title: 'CHALLENGE PREP',
    tagline: hasSkill
        ? "Train for this week's $name challenge."
        : "Train for this week's challenge.",
    emoji: '🏆',
    accentColor: const Color(0xFFF97316),
    isFreeTier: false,
    workouts: [
      Workout(
        id: 'prep_weekly',
        title: hasSkill ? '$name Prep' : 'Weekly Skill Prep',
        description: hasSkill
            ? 'Focused $name drill before submitting your video.'
            : 'A focused drill on the active challenge skill.',
        durationMinutes: 12,
        difficulty: 'all',
        focusArea: hasSkill ? name! : 'Challenge',
        exercises: [
          const Exercise(
            id: 'pw_1',
            name: 'Skill Warmup',
            instruction:
                'Light bounce for 2 minutes. Loosen up wrists and shoulders.',
            sets: 1,
            reps: 1,
            restSeconds: 30,
          ),
          Exercise(
            id: 'pw_2',
            name: hasSkill ? '$name Drill' : 'Active Skill Drill',
            instruction: hasSkill
                ? 'Focus reps on $name. 5 sets of 10.'
                : 'Focus reps on the active challenge skill. 5 sets of 10.',
            sets: 5,
            reps: 10,
            restSeconds: 60,
          ),
        ],
      ),
      Workout(
        id: 'prep_routine',
        title: hasSkill ? 'Pre-Submission: $name' : 'Pre-Submission Routine',
        description: 'Quick prep before recording your challenge video.',
        durationMinutes: 8,
        difficulty: 'all',
        focusArea: hasSkill ? name! : 'Challenge',
        exercises: [
          Exercise(
            id: 'pr_1',
            name: 'Camera-Ready Set',
            instruction: hasSkill
                ? 'Two clean $name attempts. Rest 60s between.'
                : 'Two clean attempts at the skill. Rest 60s between.',
            sets: 2,
            reps: 1,
            restSeconds: 60,
          ),
        ],
      ),
      Workout(
        id: 'prep_power',
        title: hasSkill ? '$name Power Hour' : 'Power Hour',
        description: '45 minutes of peak-performance practice.',
        durationMinutes: 45,
        difficulty: 'advanced',
        focusArea: hasSkill ? name! : 'Challenge',
        exercises: [
          Exercise(
            id: 'pp_1',
            name: hasSkill ? '$name Cycle' : 'Full-Skill Cycle',
            instruction: hasSkill
                ? 'Cycle through $name drills at increasing intensity. 5 mins each.'
                : 'Cycle through every active challenge skill. 5 mins each.',
            sets: 1,
            reps: 1,
            restSeconds: 120,
          ),
        ],
      ),
    ],
  );
}
