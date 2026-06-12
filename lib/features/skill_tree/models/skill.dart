import 'package:flutter/foundation.dart';

enum SkillStatus { locked, available, completed, mastered }

@immutable
class Skill {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final List<String> tips;
  final List<String> unlockIds;
  final int xpReward;
  final int orderIndex;
  final bool isFreeNode;
  final SkillStatus status;
  final int sessionsCompleted;

  const Skill({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.tips,
    required this.unlockIds,
    required this.xpReward,
    required this.orderIndex,
    required this.isFreeNode,
    required this.status,
    required this.sessionsCompleted,
  });

  Skill copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    List<String>? tips,
    List<String>? unlockIds,
    int? xpReward,
    int? orderIndex,
    bool? isFreeNode,
    SkillStatus? status,
    int? sessionsCompleted,
  }) {
    return Skill(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      tips: tips ?? this.tips,
      unlockIds: unlockIds ?? this.unlockIds,
      xpReward: xpReward ?? this.xpReward,
      orderIndex: orderIndex ?? this.orderIndex,
      isFreeNode: isFreeNode ?? this.isFreeNode,
      status: status ?? this.status,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
    );
  }
}
