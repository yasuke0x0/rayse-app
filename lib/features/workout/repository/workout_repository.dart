import '../data/mock_workout_groups.dart' as data;
import '../models/workout.dart';
import '../models/workout_group.dart';

class WorkoutRepository {
  Future<List<WorkoutGroup>> getGroups() async {
    return data.mockWorkoutGroups;
  }

  Future<List<Workout>> getWorkouts() async {
    return data.allWorkouts();
  }

  Future<Workout> getTodayWorkout() async {
    final today = DateTime.now().weekday;
    final all = data.allWorkouts();
    // Try to find a workout tagged for today's weekday
    final match = all.where((w) => w.weekday == today).toList();
    if (match.isNotEmpty) return match.first;
    // Fallback — first workout in the catalogue
    return all.first;
  }

  Future<Workout?> getWorkoutById(String id) async {
    try {
      return data.allWorkouts().firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<WorkoutGroup?> getGroupById(String id) async {
    try {
      return data.mockWorkoutGroups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
