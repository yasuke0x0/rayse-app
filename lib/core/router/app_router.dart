import 'package:go_router/go_router.dart';
import 'package:rayse/features/auth/screens/auth_gate.dart';
import 'package:rayse/features/auth/screens/login_screen.dart';
import 'package:rayse/features/auth/screens/onboarding_screen.dart';
import 'package:rayse/features/auth/screens/signup_screen.dart';
import 'package:rayse/features/auth/screens/splash_screen.dart';
import 'package:rayse/features/content/screens/home_screen.dart';
import 'package:rayse/features/content/screens/tutorial_detail_screen.dart';
import 'package:rayse/features/skill_tree/screens/skill_detail_screen.dart';
import 'package:rayse/features/skill_tree/screens/practice_screen.dart';
import 'package:rayse/features/skill_tree/screens/result_screen.dart';
import 'package:rayse/features/skill_tree/screens/mastered_screen.dart';
import 'package:rayse/features/subscription/screens/paywall_screen.dart';
import 'package:rayse/features/workout/screens/daily_workout_screen.dart';
import 'package:rayse/features/workout/screens/workout_player_screen.dart';
import 'package:rayse/features/community/screens/submit_video_screen.dart';
import 'package:rayse/features/community/screens/admin_panel_screen.dart';
import 'package:rayse/features/community/screens/admin_users_screen.dart';
import 'package:rayse/features/community/screens/admin_user_detail_screen.dart';
import 'package:rayse/features/community/screens/community_screen.dart';
import 'package:rayse/features/community/screens/community_video_detail_screen.dart';
import 'package:rayse/features/community/models/community_video.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth-gate',
      builder: (context, state) => const AuthGateScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/tutorial/:id',
      builder: (context, state) => TutorialDetailScreen(
        id: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/workout',
      builder: (context, state) => const DailyWorkoutScreen(),
      routes: [
        GoRoute(
          path: 'play/:id',
          builder: (context, state) => WorkoutPlayerScreen(
            workoutId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/skill-detail/:skillId',
      builder: (context, state) => SkillDetailScreen(
        skillId: state.pathParameters['skillId']!,
      ),
    ),
    GoRoute(
      path: '/skill-practice/:skillId',
      builder: (context, state) => PracticeScreen(
        skillId: state.pathParameters['skillId']!,
      ),
    ),
    GoRoute(
      path: '/skill-result/:skillId',
      builder: (context, state) => ResultScreen(
        skillId: state.pathParameters['skillId']!,
      ),
    ),
    GoRoute(
      path: '/skill-mastered/:skillId',
      builder: (context, state) => MasteredScreen(
        skillId: state.pathParameters['skillId']!,
      ),
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const PaywallScreen(),
    ),
    GoRoute(
      path: '/submit-video/:skillId',
      builder: (context, state) => SubmitVideoScreen(
        skillId: state.pathParameters['skillId']!,
      ),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPanelScreen(),
      routes: [
        GoRoute(
          path: 'users',
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: 'user-detail',
          builder: (context, state) => AdminUserDetailScreen(
            user: state.extra as Map<String, dynamic>,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityScreen(),
    ),
    GoRoute(
      path: '/community-video',
      builder: (context, state) => CommunityVideoDetailScreen(
        video: state.extra as CommunityVideo,
      ),
    ),
  ],
);
