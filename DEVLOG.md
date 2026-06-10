
## 2026-06-04 — Phase 1: Theme + Splash + Onboarding

### What was built
- Full dark theme system (AppColors + AppTheme) with zinc-950 background, orange accent, Poppins headings, Inter body
- go_router with /splash → /onboarding → /home routes
- ProviderScope + Supabase.initialize wired in main.dart
- Splash screen: animated fade-in wordmark, grid CustomPainter overlay, 2.5s auto-navigate
- Onboarding: 3-page PageView (Level / Goal / Challenge) with animated pill selectors and dot indicators
- Home screen: 4-tab BottomNavigationBar placeholder (Home / Learn / Challenges / Profile)

### Files touched
- pubspec.yaml (added flutter_riverpod, go_router, google_fonts, supabase_flutter)
- lib/main.dart
- lib/core/theme/app_colors.dart
- lib/core/theme/app_theme.dart
- lib/core/router/app_router.dart
- lib/features/auth/screens/splash_screen.dart
- lib/features/auth/screens/onboarding_screen.dart
- lib/features/content/screens/home_screen.dart
- test/widget_test.dart (replaced stale counter test)

### Decisions
- Used `publishableKey` instead of deprecated `anonKey` in Supabase.initialize
- Unselected onboarding pills keep orange 1px border (matches the brand energy even when inactive)
- Grid painter uses `withValues(alpha:)` (null-safe modern API) instead of deprecated `withOpacity`

## 2026-06-04 — Phase 2: Supabase Auth

### What was built
- SupabaseService: static client getter wrapping Supabase.instance.client
- AuthRepository: signIn / signUp / signOut / getCurrentUser with AuthException handling
- authRepositoryProvider + authStateProvider (StreamProvider on onAuthStateChange)
- AuthGateScreen: watches auth state, redirects to /home or /login
- LoginScreen: email + password fields, sign-in CTA, forgot password, "create account" outlined button, loading + error states
- SignupScreen: name + email + password fields, create account CTA, terms text, back arrow
- Router updated: /auth-gate, /login, /signup routes added
- Splash now navigates to /auth-gate (not /onboarding) — returning users skip onboarding
- Onboarding "LET'S GO" navigates to /login instead of /home

### Files touched
- lib/core/services/supabase_service.dart (new)
- lib/features/auth/repository/auth_repository.dart (new)
- lib/features/auth/providers/auth_provider.dart (new)
- lib/features/auth/screens/auth_gate.dart (new)
- lib/features/auth/screens/login_screen.dart (new)
- lib/features/auth/screens/signup_screen.dart (new)
- lib/core/router/app_router.dart (updated)
- lib/features/auth/screens/splash_screen.dart (updated nav target)
- lib/features/auth/screens/onboarding_screen.dart (updated nav target)
- CLAUDE.md (Phase 2 checked off)

### Gotchas
- supabase_flutter v2 uses onAuthStateChange stream returning AuthState objects; session != null means signed in
- AuthGate uses ref.listen (not ref.watch) for navigation side-effects — avoids calling context.go during build

## 2026-06-04 — Phase 3: Home screen + Content library

### What was built
- Tutorial model with fromJson/toJson
- 6 mock tutorials (placeholder @samsjump YouTube IDs — replace when verified)
- ContentRepository: getTutorials / getTutorialsByLevel / getTutorialById (mock data, Supabase-ready)
- Riverpod providers: tutorialsProvider, tutorialsByLevelProvider, tutorialByIdProvider (family)
- TutorialCard widget: 200px wide, YouTube thumbnail via cached_network_image, level badge, duration badge, tap → /tutorial/:id
- HomeScreen rebuilt: greeting header, featured challenge card, "Free Tutorials" horizontal scroll, "Your Level" filtered scroll, IndexedStack for tab persistence
- TutorialDetailScreen: YoutubePlayerBuilder + YoutubePlayer, back arrow overlay, badges, description, "More Like This" related cards
- Router: /tutorial/:id route added
- AppColors: levelBeginner / levelIntermediate / levelAdvanced added

### Files touched
- pubspec.yaml (added youtube_player_flutter, cached_network_image)
- lib/core/theme/app_colors.dart
- lib/core/router/app_router.dart
- lib/features/content/models/tutorial.dart (new)
- lib/features/content/data/mock_tutorials.dart (new)
- lib/features/content/repository/content_repository.dart (new)
- lib/features/content/providers/content_provider.dart (new)
- lib/features/content/widgets/tutorial_card.dart (new)
- lib/features/content/screens/home_screen.dart (rewritten)
- lib/features/content/screens/tutorial_detail_screen.dart (new)
- CLAUDE.md

### Gotchas
- youtube_player_flutter uses flutter_inappwebview which prints a Swift Package Manager warning on iOS — not an error, safe to ignore until plugin updates
- Video playback works on Android/iOS only; web shows a blank player area
- Mock YouTube IDs are placeholders — user should replace with real @samsjump video IDs
- Dart 3 wildcard `_` can be repeated in param lists; `(_, __)` → `(_, _)` to satisfy unnecessary_underscores lint

## 2026-06-10 — Phase 4: Skill tree + Profile tab

### What was built
- SkillNode model with id, title, description, level, isUnlocked, isCompleted, prerequisiteIds
- skill_tree_data.dart: static list of mock skill nodes (beginner → intermediate → advanced progression)
- skillTreeProvider (Riverpod): exposes skill node list, unlock/complete actions
- SkillTreeScreen: scrollable visual skill tree with node cards, lock/unlock states, progress indicators
- _ProfileTab wired into HomeScreen (Profile tab): shows current user email + LOG OUT button using authRepositoryProvider.signOut()
- Auth listener added to HomeScreen: redirects to /login when session ends
- Makefile: added `phone` target pointing to physical device ID; fixed missing newline at EOF

### Files touched
- lib/features/skill_tree/models/skill_node.dart (new)
- lib/features/skill_tree/data/skill_tree_data.dart (new)
- lib/features/skill_tree/providers/skill_tree_provider.dart (new)
- lib/features/skill_tree/screens/skill_tree_screen.dart (new)
- lib/features/content/screens/home_screen.dart (added SkillTreeScreen, _ProfileTab, auth listener)
- Makefile (added phone target, fixed EOF newline)
- CLAUDE.md (Phase 4 checked off)

### Gotchas
- SkillTreeScreen imported directly into home_screen.dart; no new router route needed (tab uses IndexedStack)
- Auth redirect uses ref.listen in build — consistent with the pattern established in Phase 2 (avoids calling context.go during build phase)

## 2026-06-10 — Phase 5: Challenges + Leaderboard

### What was built
- Challenge model with id, title, description, type (reps/time/streak), targetValue, unit, durationDays, startDate, participantCount, isActive; computed daysLeft and endDate
- LeaderboardEntry model with rank, username, score, unit, isCurrentUser flag
- 4 mock challenges: "100 Double Unders" (active), "30-Day Jump Streak", "500 Single Bounces", "Speed DU — Under 60s"
- Mock leaderboard with 5 entries including a "You" row highlighted in orange
- ChallengeRepository: getChallenges, getLeaderboard, joinChallenge, submitEntry (mock, Supabase-ready)
- challengesProvider (FutureProvider), leaderboardProvider (FutureProvider.family), joinedChallengesProvider (NotifierProvider<Set<String>>)
- ChallengesScreen: hero active challenge card (orange accent border, countdown, participant count, JOIN button), top-5 leaderboard with gold/silver/bronze rank colors, "More Challenges" list with per-card JOIN pills
- Removed _PlaceholderTab (fully unused after Phases 4 and 5)
- Wired ChallengesScreen into HomeScreen IndexedStack (tab index 2)

### Files touched
- lib/features/challenges/models/challenge.dart (new)
- lib/features/challenges/models/leaderboard_entry.dart (new)
- lib/features/challenges/data/mock_challenges.dart (new)
- lib/features/challenges/repository/challenge_repository.dart (new)
- lib/features/challenges/providers/challenge_provider.dart (new)
- lib/features/challenges/screens/challenges_screen.dart (new)
- lib/features/content/screens/home_screen.dart (wire ChallengesScreen, remove _PlaceholderTab)
- CLAUDE.md (Phase 5 checked off)

### Gotchas
- Leaderboard rank colors use `switch` expression (Dart 3) — gold #FBBF24, silver #94A3B8, bronze #D97706
- joinedChallengesProvider is in-memory only until Supabase challenge_participants table is wired in Phase 7+ work

## 2026-06-11 — Phase 6: Daily Workout Program

### What was built
- Exercise model: name, instruction, sets, reps (nullable), durationSeconds (nullable), restSeconds; computed targetLabel
- Workout model: id, title, description, weekday (1=Mon–7=Sun), durationMinutes, difficulty, focusArea, exercises list
- 7 mock workouts (Mon–Sun): Foundation, Endurance, Technique, Power, Flow, Challenge Day, Active Recovery — each with 3 exercises
- getTodayWorkout() helper that selects by DateTime.now().weekday
- WorkoutRepository: getWorkouts, getTodayWorkout, getWorkoutById (Supabase-ready)
- allWorkoutsProvider, todayWorkoutProvider, workoutByIdProvider (FutureProvider.family), completedWorkoutsProvider (NotifierProvider<Set<String>>)
- DailyWorkoutScreen: today's hero card (orange/green accent, exercise list, START WORKOUT CTA) + week overview rows with day labels, duration, and completion dot
- WorkoutPlayerScreen: step-through player with progress bar + dots, set counter, rest view (shows rest duration + "up next"), completion dialog; state managed with _exerciseIndex / _currentSet / _isResting
- _TodayWorkoutBanner widget on HomeScreen: tappable banner showing today's workout name, duration, and done/not-done state
- Router: /workout and /workout/play/:id routes added

### Files touched
- lib/features/workout/models/exercise.dart (new)
- lib/features/workout/models/workout.dart (new)
- lib/features/workout/data/mock_workouts.dart (new)
- lib/features/workout/repository/workout_repository.dart (new)
- lib/features/workout/providers/workout_provider.dart (new)
- lib/features/workout/screens/daily_workout_screen.dart (new)
- lib/features/workout/screens/workout_player_screen.dart (new)
- lib/core/router/app_router.dart (added /workout and /workout/play/:id)
- lib/features/content/screens/home_screen.dart (added _TodayWorkoutBanner)
- CLAUDE.md (Phase 6 checked off)

### Gotchas
- WorkoutRepository.getTodayWorkout() uses a namespaced import (data.getTodayWorkout()) to avoid infinite recursion with identically-named method
- completedWorkoutsProvider is in-memory only — needs Supabase workout_completions table before Phase 7
- WorkoutPlayerScreen uses setState (local UI state) — acceptable per conventions since _exerciseIndex/_currentSet/_isResting are purely local player state
