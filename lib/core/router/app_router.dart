import 'package:go_router/go_router.dart';
import 'package:rayse/features/auth/screens/auth_gate.dart';
import 'package:rayse/features/auth/screens/login_screen.dart';
import 'package:rayse/features/auth/screens/onboarding_screen.dart';
import 'package:rayse/features/auth/screens/signup_screen.dart';
import 'package:rayse/features/auth/screens/splash_screen.dart';
import 'package:rayse/features/content/screens/home_screen.dart';

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
  ],
);
