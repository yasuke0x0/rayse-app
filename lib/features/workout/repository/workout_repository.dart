import '../data/mock_workouts.dart' as data;
import '../models/workout.dart';

class WorkoutRepository {
  Future<List<Workout>> getWorkouts() async {
    // TODO: replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 200));
    return data.mockWorkouts;
  }

  Future<Workout> getTodayWorkout() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return data.getTodayWorkout();
  }

  Future<Workout?> getWorkoutById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return data.mockWorkouts.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }
}
