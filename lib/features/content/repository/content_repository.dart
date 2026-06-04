import '../data/mock_tutorials.dart';
import '../models/tutorial.dart';

class ContentRepository {
  Future<List<Tutorial>> getTutorials() async {
    // Returns mock data — will connect to Supabase in a future phase
    return mockTutorials;
  }

  Future<List<Tutorial>> getTutorialsByLevel(String level) async {
    return mockTutorials.where((t) => t.level == level).toList();
  }

  Future<Tutorial?> getTutorialById(String id) async {
    try {
      return mockTutorials.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
