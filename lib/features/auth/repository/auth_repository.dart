import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<void> signUp(
    String email,
    String password, {
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      final userId = res.user?.id;
      if (userId != null) {
        await _client.from('profiles').update({
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
        }).eq('id', userId);
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Username is already taken.');
      }
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
