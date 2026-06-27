import 'package:flutter/material.dart';
import 'workout.dart';

class WorkoutGroup {
  final String id;
  final String title;
  final String tagline;
  final String emoji;
  final Color accentColor;
  final bool isFreeTier;
  final List<Workout> workouts;

  const WorkoutGroup({
    required this.id,
    required this.title,
    required this.tagline,
    required this.emoji,
    required this.accentColor,
    required this.isFreeTier,
    required this.workouts,
  });

  int get totalMinutes =>
      workouts.fold(0, (sum, w) => sum + w.durationMinutes);
}
