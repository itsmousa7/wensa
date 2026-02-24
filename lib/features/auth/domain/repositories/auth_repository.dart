import 'package:future_riverpod/features/auth/domain/repositories/exceptions_supabase.dart';
import 'package:future_riverpod/services/google_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
    } catch (e) {
      throw handleException(e);
    }
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw handleException(e);
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final googleAuthService = GoogleAuthService(_client);
      return await googleAuthService.signInWithGoogle();
    } catch (e) {
      throw handleException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw handleException(e);
    }
  }

  // Verify OTP
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
    } catch (e) {
      throw handleException(e);
    }
  }

  // Resend OTP
  Future<void> resendOTP({
    required String email,
    required OtpType type,
  }) async {
    try {
      await _client.auth.resend(
        email: email,
        type: type,
      );
    } catch (e) {
      throw handleException(e);
    }
  }

  Future<void> resetPasswordRequest({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw handleException(e);
    }
  }

  // Update Password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> updateUserProfile({
    required String firstName,
    required String secondName,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('No user logged in');

      // Update app_users table
      await _client
          .from('app_users')
          .update({
            'first_name': firstName,
            'second_name': secondName,
          })
          .eq('id', userId);
    } catch (e) {
      throw handleException(e);
    }
  }

  // Get Current User
  User? get currentUser => _client.auth.currentUser;

  // Get Current Session
  Session? get currentSession => _client.auth.currentSession;

  // Auth State Stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
