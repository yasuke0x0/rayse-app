class Challenge {
  final String id;
  final String title;
  final String description;
  final String type; // 'reps' | 'time' | 'streak'
  final int targetValue;
  final String unit;
  final int durationDays;
  final DateTime startDate;
  final int participantCount;
  final bool isActive;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.unit,
    required this.durationDays,
    required this.startDate,
    required this.participantCount,
    this.isActive = false,
  });

  DateTime get endDate => startDate.add(Duration(days: durationDays));

  int get daysLeft =>
      endDate.difference(DateTime.now()).inDays.clamp(0, durationDays);

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        type: json['type'] as String,
        targetValue: json['target_value'] as int,
        unit: json['unit'] as String,
        durationDays: json['duration_days'] as int,
        startDate: DateTime.parse(json['start_date'] as String),
        participantCount: json['participant_count'] as int,
        isActive: json['is_active'] as bool? ?? false,
      );
}
