import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (_, state) {
      state.whenData((authState) {
        if (authState.session != null) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      });
    });

    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
