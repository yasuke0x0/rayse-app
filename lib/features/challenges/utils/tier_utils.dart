import '../../skill_tree/data/skill_tree_data.dart';
import '../../skill_tree/models/skill.dart';
import '../providers/challenge_provider.dart';

const tierLabels = <ChallengeTier, String>{
  ChallengeTier.beginner: 'BEGINNER',
  ChallengeTier.intermediate: 'INTERMEDIATE',
  ChallengeTier.advanced: 'ADVANCED',
};

ChallengeTier tierForSkill(String skillId) {
  final node = kSkillTree.where((n) => n.id == skillId).firstOrNull;
  final tier = node?.tier ?? 4;
  if (tier <= 1) return ChallengeTier.beginner;
  if (tier == 2) return ChallengeTier.intermediate;
  return ChallengeTier.advanced;
}

ChallengeTier highestMasteredTier(List<Skill> skills) {
  ChallengeTier best = ChallengeTier.beginner;
  for (final s in skills) {
    if (s.status != SkillStatus.mastered) continue;
    final t = tierForSkill(s.id);
    if (t.index > best.index) best = t;
  }
  return best;
}
