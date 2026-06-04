class Tutorial {
  final String id;
  final String title;
  final String description;
  final String youtubeId;
  final String level;
  final String category;
  final int durationMinutes;
  final String thumbnailUrl;
  final bool isFree;
  final DateTime createdAt;

  const Tutorial({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeId,
    required this.level,
    required this.category,
    required this.durationMinutes,
    required this.thumbnailUrl,
    required this.isFree,
    required this.createdAt,
  });

  factory Tutorial.fromJson(Map<String, dynamic> json) => Tutorial(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        youtubeId: json['youtube_id'] as String,
        level: json['level'] as String,
        category: json['category'] as String,
        durationMinutes: json['duration_minutes'] as int,
        thumbnailUrl: json['thumbnail_url'] as String,
        isFree: json['is_free'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'youtube_id': youtubeId,
        'level': level,
        'category': category,
        'duration_minutes': durationMinutes,
        'thumbnail_url': thumbnailUrl,
        'is_free': isFree,
        'created_at': createdAt.toIso8601String(),
      };
}
