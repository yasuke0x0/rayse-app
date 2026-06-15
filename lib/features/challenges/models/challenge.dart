import '../../community/repository/community_video_repository.dart';

class Challenge {
  final String id;
  final String skillId;
  final String title;
  final String description;
  final int weekNumber;
  final int weekYear;
  final int xpReward;

  const Challenge({
    required this.id,
    required this.skillId,
    required this.title,
    required this.description,
    required this.weekNumber,
    required this.weekYear,
    required this.xpReward,
  });

  bool get isCurrentWeek {
    final now = DateTime.now().toUtc();
    return weekNumber == CommunityVideoRepository.isoWeek(now) &&
        weekYear == now.year;
  }

  int get daysLeft {
    if (!isCurrentWeek) return 0;
    // Days until end of current ISO week (Sunday)
    final now = DateTime.now();
    return (7 - now.weekday).clamp(0, 7);
  }

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'] as String,
        skillId: json['skill_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        weekNumber: json['week_number'] as int,
        weekYear: json['week_year'] as int,
        xpReward: json['xp_reward'] as int? ?? 50,
      );
}
