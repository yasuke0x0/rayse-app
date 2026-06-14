import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/providers/community_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../skill_tree/providers/skill_provider.dart';
import '../../skill_tree/screens/skill_tree_screen.dart';
import '../../challenges/screens/challenges_screen.dart';
import '../../community/screens/community_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../workout/providers/workout_provider.dart';
import '../providers/content_provider.dart';
import '../widgets/tutorial_card.dart';

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
          const CommunityScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: AppColors.border),
          BottomNavigationBar(
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline),
                activeIcon: Icon(Icons.play_circle),
                label: 'Learn',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events),
                label: 'Challenges',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING,';
    if (hour < 17) return 'GOOD AFTERNOON,';
    return 'GOOD EVENING,';
  }

  String get _displayName {
    final user = SupabaseService.client.auth.currentUser;
    final email = user?.email ?? '';
    if (email.isEmpty) return 'JUMPER';
    return email.split('@').first.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorialsAsync = ref.watch(tutorialsProvider);

    return Stack(
      children: [
        const Positioned.fill(child: _GridOverlay()),
        SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Greeting header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Today's workout card ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: _TodayWorkoutBanner(),
                ),
              ),

              // ── Featured challenge card ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: GestureDetector(
                    onTap: () => onSwitchTab(2),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.accent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "THIS WEEK'S CHALLENGE",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '100 Double Unders',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '7 days · Community challenge',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward,
                                color: AppColors.accent,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Free tutorials section ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FREE TUTORIALS',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'SEE ALL',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: tutorialsAsync.when(
                    loading: () => const _HorizontalLoadingRow(),
                    error: (_, _) => const _ErrorRow(),
                    data: (tutorials) => SizedBox(
                      height: 228,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: tutorials.length,
                        itemBuilder: (context, i) => Padding(
                          padding: EdgeInsets.only(
                              right: i < tutorials.length - 1 ? 12 : 0),
                          child: TutorialCard(tutorial: tutorials[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Your level section ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                  child: Text(
                    'YOUR LEVEL',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 32),
                  child: tutorialsAsync.when(
                    loading: () => const _HorizontalLoadingRow(),
                    error: (_, _) => const _ErrorRow(),
                    data: (tutorials) {
                      final filtered = tutorials
                          .where((t) => t.level == 'beginner')
                          .toList();
                      final display =
                          filtered.isNotEmpty ? filtered : tutorials;
                      return SizedBox(
                        height: 228,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: display.length,
                          itemBuilder: (context, i) => Padding(
                            padding: EdgeInsets.only(
                                right: i < display.length - 1 ? 12 : 0),
                            child: TutorialCard(tutorial: display[i]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Today's workout banner ───────────────────────────────────────────────────

class _TodayWorkoutBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayWorkoutProvider);
    final completed = ref.watch(completedWorkoutsProvider);

    return todayAsync.when(
      loading: () => Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (workout) {
        final isDone = completed.contains(workout.id);
        return GestureDetector(
          onTap: () => context.push('/workout'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone
                    ? const Color(0xFF22C55E)
                    : AppColors.accent.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                        : AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDone ? Icons.check : Icons.fitness_center_outlined,
                    color: isDone
                        ? const Color(0xFF22C55E)
                        : AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDone ? 'WORKOUT DONE' : "TODAY'S WORKOUT",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDone
                              ? const Color(0xFF22C55E)
                              : AppColors.accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workout.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${workout.durationMinutes} min',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textMuted, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}


// ─── Loading / error states ───────────────────────────────────────────────────

class _HorizontalLoadingRow extends StatelessWidget {
  const _HorizontalLoadingRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 228,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 3,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
          child: Container(
            width: 200,
            height: 228,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Failed to load tutorials.',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
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
