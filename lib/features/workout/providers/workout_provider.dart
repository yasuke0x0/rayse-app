import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../models/workout_group.dart';
import '../repository/workout_repository.dart';

final workoutRepositoryProvider =
    Provider<WorkoutRepository>((_) => WorkoutRepository());

final workoutGroupsProvider = FutureProvider<List<WorkoutGroup>>((ref) {
  return ref.read(workoutRepositoryProvider).getGroups();
});

final workoutGroupByIdProvider =
    FutureProvider.family<WorkoutGroup?, String>((ref, id) {
  return ref.read(workoutRepositoryProvider).getGroupById(id);
});

final allWorkoutsProvider = FutureProvider<List<Workout>>((ref) {
  return ref.read(workoutRepositoryProvider).getWorkouts();
});

final todayWorkoutProvider = FutureProvider<Workout>((ref) {
  return ref.read(workoutRepositoryProvider).getTodayWorkout();
});

final workoutByIdProvider =
    FutureProvider.family<Workout?, String>((ref, id) {
  return ref.read(workoutRepositoryProvider).getWorkoutById(id);
});

// Tracks which workout IDs the user has completed today (in-memory until Supabase)
final completedWorkoutsProvider =
    NotifierProvider<CompletedWorkoutsNotifier, Set<String>>(
        CompletedWorkoutsNotifier.new);

class CompletedWorkoutsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void markComplete(String workoutId) =>
      state = {...state, workoutId};
}
