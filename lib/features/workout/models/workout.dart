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

  const Workout({
    required this.id,
    required this.title,
    required this.description,
    this.weekday,
    required this.durationMinutes,
    required this.difficulty,
    required this.focusArea,
    required this.exercises,
  });
}
