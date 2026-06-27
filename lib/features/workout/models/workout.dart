import 'exercise.dart';

class Workout {
  final String id;
  final String title;
  final String description;
  final int? weekday; // 1 = Monday … 7 = Sunday — null for non-daily workouts
  final int durationMinutes;
  final String difficulty; // 'beginner' | 'intermediate' | 'advanced' | 'all'
  final String focusArea;
  final List<Exercise> exercises;

  /// Skills the workout assumes the user has mastered. If the user hasn't
  /// mastered all of them, an advisory is shown (the workout still starts).
  final List<String> prerequisiteSkillIds;

  const Workout({
    required this.id,
    required this.title,
    required this.description,
    this.weekday,
    required this.durationMinutes,
    required this.difficulty,
    required this.focusArea,
    required this.exercises,
    this.prerequisiteSkillIds = const [],
  });
}
