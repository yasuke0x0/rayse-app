import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/skill.dart';
import '../data/mock_skills.dart';

// ─── XP provider ──────────────────────────────────────────────────────────────

class XPNotifier extends StateNotifier<int> {
  XPNotifier() : super(0);
  void addXP(int amount) => state = state + amount;
}

final xpProvider = StateNotifierProvider<XPNotifier, int>(
  (ref) => XPNotifier(),
);

// ─── User tier provider (free for now, will connect to RevenueCat) ────────────

final userTierProvider = Provider<String>((ref) => 'free');

// ─── Skills provider ──────────────────────────────────────────────────────────

class SkillsNotifier extends StateNotifier<List<Skill>> {
  final Ref _ref;
  SkillsNotifier(this._ref) : super(buildMockSkills());

  Skill? getSkillById(String id) {
    try {
      return state.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void completeSession(String skillId, int repsLogged) {
    final idx = state.indexWhere((s) => s.id == skillId);
    if (idx == -1) return;

    final skill = state[idx];
    final newSessions = skill.sessionsCompleted + 1;
    final newStatus =
        newSessions >= 3 ? SkillStatus.mastered : SkillStatus.completed;

    // Update the skill
    final updatedSkills = List<Skill>.from(state);
    updatedSkills[idx] = skill.copyWith(
      sessionsCompleted: newSessions,
      status: newStatus,
    );

    // Unlock next skills on first completion
    for (final unlockId in skill.unlockIds) {
      final unlockIdx = updatedSkills.indexWhere((s) => s.id == unlockId);
      if (unlockIdx != -1 &&
          updatedSkills[unlockIdx].status == SkillStatus.locked) {
        updatedSkills[unlockIdx] = updatedSkills[unlockIdx].copyWith(
          status: SkillStatus.available,
        );
      }
    }

    state = updatedSkills;

    // Award XP
    _ref.read(xpProvider.notifier).addXP(skill.xpReward);
  }
}

final skillsProvider = StateNotifierProvider<SkillsNotifier, List<Skill>>(
  (ref) => SkillsNotifier(ref),
);
