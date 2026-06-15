import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/skill.dart';
import '../data/mock_skills.dart';
import '../repository/skill_progress_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────────

final skillProgressRepositoryProvider = Provider<SkillProgressRepository>(
  (_) => SkillProgressRepository(),
);

// ─── XP provider ──────────────────────────────────────────────────────────────

class XPNotifier extends StateNotifier<int> {
  XPNotifier() : super(0);
  void addXP(int amount) => state = state + amount;
  void setXP(int amount) => state = amount;
}

final xpProvider = StateNotifierProvider<XPNotifier, int>(
  (ref) => XPNotifier(),
);

// ─── Skills provider ──────────────────────────────────────────────────────────

class SkillsNotifier extends StateNotifier<List<Skill>> {
  final Ref _ref;

  SkillsNotifier(this._ref) : super(buildMockSkills()) {
    _loadFromDatabase();
  }

  // ── Load saved progress from Supabase on startup ──────────────────────────

  Future<void> _loadFromDatabase() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final repo = _ref.read(skillProgressRepositoryProvider);
      final rows = await repo.fetchProgress(userId);
      final xp = await repo.fetchXP(userId);

      if (rows.isEmpty) return; // new user — keep mock defaults

      final updated = state.map((skill) {
        try {
          final row = rows.firstWhere((r) => r['skill_id'] == skill.id);
          return skill.copyWith(
            sessionsCompleted: row['sessions_completed'] as int,
            status: _statusFromString(row['status'] as String),
          );
        } catch (_) {
          return skill; // skill not in DB yet, keep default
        }
      }).toList();

      state = updated;
      _ref.read(xpProvider.notifier).setXP(xp);
    } catch (_) {
      // Network error — silently keep local state
    }
  }

  // ── Complete a session ────────────────────────────────────────────────────

  void completeSession(String skillId, int repsLogged) {
    final idx = state.indexWhere((s) => s.id == skillId);
    if (idx == -1) return;

    final skill = state[idx];
    final newSessions = skill.sessionsCompleted + 1;
    final newStatus =
        newSessions >= 3 ? SkillStatus.mastered : SkillStatus.completed;

    final updatedSkills = List<Skill>.from(state);
    updatedSkills[idx] = skill.copyWith(
      sessionsCompleted: newSessions,
      status: newStatus,
    );

    // Unlock next skills (only if ALL prerequisites are mastered)
    final newlyUnlocked = <String>[];
    for (final unlockId in skill.unlockIds) {
      final unlockIdx = updatedSkills.indexWhere((s) => s.id == unlockId);
      if (unlockIdx == -1 ||
          updatedSkills[unlockIdx].status != SkillStatus.locked) {
        continue;
      }

      final allPrereqsMastered = updatedSkills
          .where((s) => s.unlockIds.contains(unlockId))
          .every((s) => s.status == SkillStatus.mastered);
      if (allPrereqsMastered) {
        updatedSkills[unlockIdx] = updatedSkills[unlockIdx].copyWith(
          status: SkillStatus.available,
        );
        newlyUnlocked.add(unlockId);
      }
    }

    state = updatedSkills;

    _ref.read(xpProvider.notifier).addXP(skill.xpReward);
    final totalXP = _ref.read(xpProvider);

    _persistToDatabase(
      skillId: skillId,
      newSessions: newSessions,
      newStatus: newStatus,
      newlyUnlocked: newlyUnlocked,
      totalXP: totalXP,
    );
  }

  // ── Persist to Supabase (fire-and-forget, UI already updated) ─────────────

  Future<void> _persistToDatabase({
    required String skillId,
    required int newSessions,
    required SkillStatus newStatus,
    required List<String> newlyUnlocked,
    required int totalXP,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final repo = _ref.read(skillProgressRepositoryProvider);

    try {
      await repo.upsertProgress(
        userId: userId,
        skillId: skillId,
        sessionsCompleted: newSessions,
        status: newStatus.name,
      );

      for (final unlockId in newlyUnlocked) {
        await repo.upsertProgress(
          userId: userId,
          skillId: unlockId,
          sessionsCompleted: 0,
          status: 'available',
        );
      }

      await repo.upsertXP(userId: userId, totalXP: totalXP);
    } catch (_) {
      // Silently fail — local state is already correct
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Skill? getSkillById(String id) {
    try {
      return state.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static SkillStatus _statusFromString(String s) {
    switch (s) {
      case 'available':
        return SkillStatus.available;
      case 'completed':
        return SkillStatus.completed;
      case 'mastered':
        return SkillStatus.mastered;
      default:
        return SkillStatus.locked;
    }
  }
}

final skillsProvider = StateNotifierProvider<SkillsNotifier, List<Skill>>(
  (ref) => SkillsNotifier(ref),
);
