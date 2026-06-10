import '../models/challenge.dart';
import '../models/leaderboard_entry.dart';

final mockChallenges = [
  Challenge(
    id: 'ch_001',
    title: '100 Double Unders',
    description:
        'Hit 100 consecutive double unders without stopping. Technique over speed — control your breathing and wrist rotation.',
    type: 'reps',
    targetValue: 100,
    unit: 'reps',
    durationDays: 7,
    startDate: DateTime.now().subtract(const Duration(days: 2)),
    participantCount: 1284,
    isActive: true,
  ),
  Challenge(
    id: 'ch_002',
    title: '30-Day Jump Streak',
    description:
        'Jump every single day for 30 days. Even 5 minutes counts — consistency is the skill.',
    type: 'streak',
    targetValue: 30,
    unit: 'days',
    durationDays: 30,
    startDate: DateTime.now().subtract(const Duration(days: 5)),
    participantCount: 3471,
    isActive: false,
  ),
  Challenge(
    id: 'ch_003',
    title: '500 Single Bounces',
    description:
        'Complete 500 single bounces in one session. Great for building endurance and rhythmic footwork.',
    type: 'reps',
    targetValue: 500,
    unit: 'reps',
    durationDays: 3,
    startDate: DateTime.now().subtract(const Duration(days: 1)),
    participantCount: 892,
    isActive: false,
  ),
  Challenge(
    id: 'ch_004',
    title: 'Speed DU — Under 60s',
    description:
        '50 double unders as fast as possible. Post your time in the community and see how you rank.',
    type: 'time',
    targetValue: 60,
    unit: 'seconds',
    durationDays: 14,
    startDate: DateTime.now().subtract(const Duration(days: 3)),
    participantCount: 614,
    isActive: false,
  ),
];

final mockLeaderboard = [
  const LeaderboardEntry(rank: 1, username: 'samsjump', score: 100, unit: 'reps'),
  const LeaderboardEntry(rank: 2, username: 'jumpqueen', score: 98, unit: 'reps'),
  const LeaderboardEntry(rank: 3, username: 'ropemaster_x', score: 94, unit: 'reps'),
  const LeaderboardEntry(rank: 4, username: 'you', score: 87, unit: 'reps', isCurrentUser: true),
  const LeaderboardEntry(rank: 5, username: 'flyjumper22', score: 82, unit: 'reps'),
];
