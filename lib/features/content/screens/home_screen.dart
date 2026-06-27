import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../challenges/providers/challenge_provider.dart';
import '../../challenges/screens/challenges_screen.dart';
import '../../community/models/community_video.dart';
import '../../community/providers/community_provider.dart';
import '../../community/repository/community_video_repository.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../skill_tree/models/skill.dart';
import '../../skill_tree/providers/skill_provider.dart';
import '../../skill_tree/screens/skill_tree_screen.dart';
import '../../workout/providers/workout_provider.dart';
import '../../workout/screens/workouts_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Listen for external tab switch requests
    ref.listen(homeTabIndexProvider, (prev, next) {
      if (next != null) {
        setState(() => _currentIndex = next);
        ref.read(homeTabIndexProvider.notifier).state = null;
      }
    });

    ref.listen(authStateProvider, (prev, state) {
      state.whenData((authState) {
        if (authState.session == null) {
          // Invalidate all user-specific providers on logout
          ref.invalidate(profileProvider);
          ref.invalidate(userTierProvider);
          ref.invalidate(skillsProvider);
          ref.invalidate(xpProvider);
          ref.invalidate(myTotalSubmissionsProvider);
          ref.invalidate(mySkillVideosProvider);
          ref.invalidate(myAllVideosProvider);
          ref.invalidate(myReactionsProvider);
          ref.invalidate(pendingVideosProvider);
          ref.invalidate(isCreatorProvider);
          ref.invalidate(unreadNotificationCountProvider);
          ref.invalidate(notificationsProvider);
          ref.invalidate(challengesProvider);
          ref.invalidate(hasSubmittedChallengeProvider);
          ref.invalidate(challengeLeaderboardProvider);
          ref.invalidate(challengeParticipantCountProvider);
          ref.invalidate(myChallengePlacementProvider);
          ref.invalidate(myChallengeStatsProvider);
          ref.invalidate(myChallengeHistoryProvider);
          ref.invalidate(selectedChallengeTierProvider);
          context.go('/login');
        } else if (prev?.valueOrNull?.session == null &&
            authState.session != null) {
          // New login — invalidate stale data from previous user
          ref.invalidate(profileProvider);
          ref.invalidate(userTierProvider);
          ref.invalidate(skillsProvider);
          ref.invalidate(xpProvider);
          ref.invalidate(myTotalSubmissionsProvider);
          ref.invalidate(mySkillVideosProvider);
          ref.invalidate(myAllVideosProvider);
          ref.invalidate(myReactionsProvider);
          ref.invalidate(pendingVideosProvider);
          ref.invalidate(isCreatorProvider);
          ref.invalidate(unreadNotificationCountProvider);
          ref.invalidate(notificationsProvider);
          ref.invalidate(challengesProvider);
          ref.invalidate(hasSubmittedChallengeProvider);
          ref.invalidate(challengeLeaderboardProvider);
          ref.invalidate(challengeParticipantCountProvider);
          ref.invalidate(myChallengePlacementProvider);
          ref.invalidate(myChallengeStatsProvider);
          ref.invalidate(myChallengeHistoryProvider);
          ref.invalidate(selectedChallengeTierProvider);
        }
      });
    });
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTabBody(onSwitchTab: (i) => setState(() => _currentIndex = i)),
          const SkillTreeScreen(),
          const ChallengesScreen(),
          const WorkoutsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: AppColors.border),
          Builder(builder: (context) {
            final unreadCount =
                ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
            final hasUnread = unreadCount > 0;
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.accent,
              unselectedItemColor: AppColors.textMuted,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedLabelStyle:
                  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.play_circle_outline),
                  activeIcon: Icon(Icons.play_circle),
                  label: 'Learn',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events_outlined),
                  activeIcon: Icon(Icons.emoji_events),
                  label: 'Challenges',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center_outlined),
                  activeIcon: Icon(Icons.fitness_center),
                  label: 'Programs',
                ),
                BottomNavigationBarItem(
                  icon: _IconWithDot(
                    icon: Icons.person_outline,
                    showDot: hasUnread,
                  ),
                  activeIcon: _IconWithDot(
                    icon: Icons.person,
                    showDot: hasUnread,
                  ),
                  label: 'Profile',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Bottom nav icon with unread dot ──────────────────────────────────────────

class _IconWithDot extends StatelessWidget {
  final IconData icon;
  final bool showDot;

  const _IconWithDot({required this.icon, required this.showDot});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: Icon(icon)),
          if (showDot)
            Positioned(
              top: 0,
              right: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Home tab body ────────────────────────────────────────────────────────────

class _HomeTabBody extends ConsumerWidget {
  final ValueChanged<int> onSwitchTab;

  const _HomeTabBody({required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const Positioned.fill(child: _GridOverlay()),
        SafeArea(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _Greeting()),
              const SliverToBoxAdapter(child: _StatsStrip()),
              const SliverToBoxAdapter(child: _TodaysMission()),
              SliverToBoxAdapter(
                  child: _KeepLearning(onSwitchTab: onSwitchTab)),
              SliverToBoxAdapter(
                  child: _WeeklyChallenge(onSwitchTab: onSwitchTab)),
              const SliverToBoxAdapter(child: _Trending()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Greeting ─────────────────────────────────────────────────────────────────

class _Greeting extends ConsumerWidget {
  const _Greeting();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING,';
    if (hour < 17) return 'GOOD AFTERNOON,';
    return 'GOOD EVENING,';
  }

  String _displayName(WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final firstName = profile?['first_name'] as String? ?? '';
    if (firstName.isNotEmpty) return firstName.toUpperCase();
    final email = SupabaseService.client.auth.currentUser?.email ?? '';
    if (email.isEmpty) return 'JUMPER';
    return email.split('@').first.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _displayName(ref),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats strip (3 cards: XP / Mastered / Best placement) ────────────────────

class _StatsStrip extends ConsumerWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(xpProvider);
    final skills = ref.watch(skillsProvider);
    final mastered =
        skills.where((s) => s.status == SkillStatus.mastered).length;
    final total = skills.length;
    final statsAsync = ref.watch(myChallengeStatsProvider);
    final best = statsAsync.valueOrNull?.bestPlacement;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              value: _formatXp(xp),
              label: 'TOTAL XP',
              icon: Icons.bolt_rounded,
              iconColor: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              value: total == 0 ? '—' : '$mastered/$total',
              label: 'MASTERED',
              icon: Icons.workspace_premium_rounded,
              iconColor: const Color(0xFF4ADE80),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              value: best == null ? '—' : '#$best',
              label: 'BEST RANK',
              icon: Icons.emoji_events_rounded,
              iconColor: const Color(0xFFFBBF24),
            ),
          ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      final k = xp / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return '$xp';
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Today's mission (big card) ───────────────────────────────────────────────

class _TodaysMission extends ConsumerWidget {
  const _TodaysMission();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayWorkoutProvider);
    final completed = ref.watch(completedWorkoutsProvider);

    return todayAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (workout) {
        final isDone = completed.contains(workout.id);
        final accent =
            isDone ? const Color(0xFF22C55E) : AppColors.accent;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.55)),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isDone
                            ? Icons.check_rounded
                            : Icons.local_fire_department_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isDone ? 'MISSION COMPLETE' : "TODAY'S MISSION",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  workout.title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.durationMinutes} min',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '· ${workout.focusArea}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push('/workout/play/${workout.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isDone ? 'DO IT AGAIN' : 'START WORKOUT',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Keep learning (next skill) ───────────────────────────────────────────────

class _KeepLearning extends ConsumerWidget {
  final ValueChanged<int> onSwitchTab;
  const _KeepLearning({required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(skillsProvider);
    // Next = first available (unlocked but not mastered), else first completed
    // (passed but not yet earned mastery), else first non-mastered.
    Skill? next = skills
        .where((s) => s.status == SkillStatus.available)
        .toList()
        .firstOrNull;
    next ??= skills
        .where((s) => s.status == SkillStatus.completed)
        .toList()
        .firstOrNull;

    if (next == null) return const SizedBox.shrink();

    final progress = (next.sessionsCompleted / 5).clamp(0.0, 1.0);
    final progressPct = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KEEP LEARNING',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => onSwitchTab(1),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.school_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXT UP',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              next.title.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted, size: 22),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${next.sessionsCompleted}/5 sessions · $progressPct%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── This week's challenge ────────────────────────────────────────────────────

class _WeeklyChallenge extends ConsumerWidget {
  final ValueChanged<int> onSwitchTab;
  const _WeeklyChallenge({required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(activeChallengeProvider);
    if (challenge == null) return const SizedBox.shrink();

    final placementAsync =
        ref.watch(myChallengePlacementProvider(challenge.id));
    final placement = placementAsync.valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "THIS WEEK'S CHALLENGE",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => onSwitchTab(2),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MetaPill(
                        icon: Icons.schedule_rounded,
                        text: '${challenge.daysLeft}d left',
                      ),
                      const SizedBox(width: 8),
                      if (placement != null)
                        _MetaPill(
                          icon: Icons.local_fire_department_rounded,
                          text: "You're #$placement",
                          highlight: true,
                        )
                      else
                        _MetaPill(
                          icon: Icons.add_rounded,
                          text: 'Not entered',
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onSwitchTab(2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        placement != null
                            ? 'VIEW LEADERBOARD'
                            : 'SUBMIT YOUR VIDEO',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;
  const _MetaPill({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.accent : AppColors.textMuted;
    final bg = highlight
        ? AppColors.accent.withValues(alpha: 0.15)
        : const Color(0xFF1F1F23);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trending this week ───────────────────────────────────────────────────────

class _Trending extends ConsumerWidget {
  const _Trending();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now().toUtc();
    final weekKey = (CommunityVideoRepository.isoWeek(now), now.year);
    final videosAsync = ref.watch(approvedVideosProvider(weekKey));

    return videosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (videos) {
        if (videos.isEmpty) return const SizedBox.shrink();
        final top = [...videos]..sort((a, b) => b.score.compareTo(a.score));
        final top3 = top.take(3).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRENDING THIS WEEK',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < top3.length; i++) ...[
                      _TrendingRow(rank: i + 1, video: top3[i]),
                      if (i < top3.length - 1)
                        Container(
                          height: 1,
                          color: AppColors.border,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 14),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrendingRow extends StatelessWidget {
  final int rank;
  final CommunityVideo video;
  const _TrendingRow({required this.rank, required this.video});

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => const Color(0xFFFBBF24),
      2 => const Color(0xFFD4D4D8),
      3 => const Color(0xFFD97706),
      _ => AppColors.textMuted,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#$rank',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: medal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '@${video.username}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.local_fire_department_rounded,
              color: AppColors.accent, size: 16),
          const SizedBox(width: 4),
          Text(
            '${video.score}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid overlay ─────────────────────────────────────────────────────────────

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 80.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
