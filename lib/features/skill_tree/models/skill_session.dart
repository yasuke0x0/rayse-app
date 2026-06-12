import 'package:flutter/foundation.dart';

@immutable
class SkillSession {
  final String id;
  final String skillId;
  final String userId;
  final DateTime completedAt;
  final int repsLogged;

  const SkillSession({
    required this.id,
    required this.skillId,
    required this.userId,
    required this.completedAt,
    required this.repsLogged,
  });
}
