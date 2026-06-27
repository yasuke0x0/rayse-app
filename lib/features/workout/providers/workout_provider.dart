import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../challenges/providers/challenge_provider.dart';
import '../../challenges/utils/tier_utils.dart';
import '../../skill_tree/providers/skill_provider.dart';
import '../data/challenge_prep_builder.dart';
import '../models/workout.dart';
import '../models/workout_group.dart';
import '../repository/workout_repository.dart';

final workoutRepositoryProvider =
    Provider<WorkoutRepository>((_) => WorkoutRepository());

/// Active challenge skill id for the current user's tier, or null if no
/// active challenge exists for that tier this week.
final _activeChallengeSkillProvider = Provider<String?>((ref) {
  final challenges = ref.watch(challengesProvider).valueOrNull ?? const [];
  final skills = ref.watch(skillsProvider);
  final tier = highestMasteredTier(skills);
  final match = challenges
      .where((c) => c.isCurrentWeek && tierForSkill(c.skillId) == tier)
      .firstOrNull;
  return match?.skillId;
});

/// Challenge Prep group rebuilt whenever the active challenge skill changes.
final challengePrepGroupProvider = Provider<WorkoutGroup>((ref) {
  final skillId = ref.watch(_activeChallengeSkillProvider);
  return buildChallengePrepGroup(skillId: skillId);
});

final workoutGroupsProvider = FutureProvider<List<WorkoutGroup>>((ref) async {
  final staticGroups = await ref.read(workoutRepositoryProvider).getGroups();
  final prepGroup = ref.watch(challengePrepGroupProvider);
  // Append the dynamic Challenge Prep group after the static ones.
  return [...staticGroups, prepGroup];
});

final workoutGroupByIdProvider =
    Provider.family<WorkoutGroup?, String>((ref, id) {
  // Challenge Prep is derived; everything else from the repo.
  if (id == 'challenge_prep') {
    return ref.watch(challengePrepGroupProvider);
  }
  final groupsAsync = ref.watch(workoutGroupsProvider);
  return groupsAsync.maybeWhen(
    data: (groups) => groups.where((g) => g.id == id).firstOrNull,
    orElse: () => null,
  );
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
