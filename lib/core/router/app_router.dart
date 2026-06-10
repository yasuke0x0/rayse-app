import 'package:go_router/go_router.dart';
import 'package:rayse/features/auth/screens/auth_gate.dart';
import 'package:rayse/features/auth/screens/login_screen.dart';
import 'package:rayse/features/auth/screens/onboarding_screen.dart';
import 'package:rayse/features/auth/screens/signup_screen.dart';
import 'package:rayse/features/auth/screens/splash_screen.dart';
import 'package:rayse/features/content/screens/home_screen.dart';
import 'package:rayse/features/content/screens/tutorial_detail_screen.dart';
import 'package:rayse/features/workout/screens/daily_workout_screen.dart';
import 'package:rayse/features/workout/screens/workout_player_screen.dart';

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
  ],
);
