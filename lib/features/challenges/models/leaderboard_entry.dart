class LeaderboardEntry {
  final int rank;
  final String username;
  final int score;
  final String unit;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.score,
    required this.unit,
    this.isCurrentUser = false,
  });
}
