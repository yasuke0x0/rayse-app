import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/skill_tree_data.dart';

final skillTreeProvider = NotifierProvider<SkillTreeNotifier, Set<String>>(
  SkillTreeNotifier.new,
);

class SkillTreeNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggleSkill(String id) {
    final node = kSkillTree.firstWhere((n) => n.id == id);
    if (!node.isUnlocked(state)) return;

    if (state.contains(id)) {
      state = state.difference(_dependents(id));
    } else {
      state = {...state, id};
    }
  }

  Set<String> _dependents(String id) {
    final result = <String>{id};
    for (final node in kSkillTree) {
      if (node.prerequisiteIds.contains(id)) {
        result.addAll(_dependents(node.id));
      }
    }
    return result;
  }
}
