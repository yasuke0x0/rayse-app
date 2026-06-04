import 'package:go_router/go_router.dart';
import 'package:rayse/features/auth/screens/splash_screen.dart';
import 'package:rayse/features/auth/screens/onboarding_screen.dart';
import 'package:rayse/features/content/screens/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
