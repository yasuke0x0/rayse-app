import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<void> signUp(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Sign up failed. Please try again.');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Sign in failed. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Sign out failed. Please try again.');
    }
  }

  User? getCurrentUser() => _client.auth.currentUser;
}
