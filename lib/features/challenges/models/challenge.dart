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

  bool get isUpcoming {
    final now = DateTime.now().toUtc();
    final currentWeek = CommunityVideoRepository.isoWeek(now);
    if (weekYear > now.year) return true;
    if (weekYear < now.year) return false;
    return weekNumber > currentWeek;
  }

  bool get isPast => !isCurrentWeek && !isUpcoming;

  int get daysLeft {
    if (!isCurrentWeek) return 0;
    // Days until end of current ISO week (Sunday)
    final now = DateTime.now();
    return (7 - now.weekday).clamp(0, 7);
  }

  int get daysUntilStart {
    if (!isUpcoming) return 0;
    final now = DateTime.now().toUtc();
    final currentWeek = CommunityVideoRepository.isoWeek(now);
    // Approximate: weeks * 7 - days into current week
    final weeksAhead = weekYear == now.year
        ? weekNumber - currentWeek
        : (weekNumber + 52 - currentWeek);
    final daysIntoWeek = now.weekday;
    return (weeksAhead * 7 - daysIntoWeek + 1).clamp(0, 365);
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
