import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tutorial.dart';
import '../repository/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (_) => ContentRepository(),
);

final tutorialsProvider = FutureProvider<List<Tutorial>>((ref) async {
  return ref.read(contentRepositoryProvider).getTutorials();
});

final tutorialsByLevelProvider =
    FutureProvider.family<List<Tutorial>, String>((ref, level) async {
  return ref.read(contentRepositoryProvider).getTutorialsByLevel(level);
});

final tutorialByIdProvider =
    FutureProvider.family<Tutorial?, String>((ref, id) async {
  return ref.read(contentRepositoryProvider).getTutorialById(id);
});
