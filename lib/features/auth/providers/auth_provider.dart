import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../repository/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

final authStateProvider = StreamProvider<AuthState>(
  (_) => SupabaseService.client.auth.onAuthStateChange,
);
