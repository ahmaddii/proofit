import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Create user profile entry
      if (response.user != null) {
        await _supabase.from('user_profiles').insert({
          'id': response.user!.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('No user logged in');

      // Delete user profile and proofs (cascade delete via FK)
      await _supabase.from('user_profiles').delete().eq('id', userId);
      
      // Note: Actual user deletion from auth.users requires admin API
      // For now, just sign out
      await signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return currentUser != null;
  }

  // Get auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}