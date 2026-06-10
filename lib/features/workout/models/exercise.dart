class Exercise {
  final String id;
  final String name;
  final String instruction;
  final int sets;
  final int? reps; // null if duration-based
  final int? durationSeconds; // null if reps-based
  final int restSeconds;

  const Exercise({
    required this.id,
    required this.name,
    required this.instruction,
    required this.sets,
    this.reps,
    this.durationSeconds,
    this.restSeconds = 30,
  });

  String get targetLabel {
    if (reps != null) return '$sets × $reps reps';
    if (durationSeconds != null) {
      final s = durationSeconds!;
      return '$sets × ${s >= 60 ? '${s ~/ 60}min' : '${s}s'}';
    }
    return '$sets sets';
  }
}
