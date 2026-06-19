import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppleAuthService {
  final SupabaseClient _client;

  AppleAuthService(this._client);

  /// Generates a cryptographically secure random nonce.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  Future<AuthResponse> signInWithApple() async {
    // Apple requires the request nonce to be SHA256-hashed; Supabase verifies
    // the returned token against the raw nonce we pass alongside the id token.
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256OfString(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) throw Exception('Missing Apple ID Token');

    final response = await _client.auth
        .signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception(
            'Sign-in timed out. Please try again.',
          ),
        );

    // Apple only returns the user's name + email on the FIRST authorization for
    // this app (Apple ID); every subsequent sign-in returns null for these.
    // Persist them now so the app never has to re-ask the user for information
    // the Authentication Services framework already provided (App Store Review
    // Guideline 4 — Sign in with Apple). Best-effort: a failure here must not
    // break the sign-in itself.
    await _persistAppleProfile(response, credential);

    return response;
  }

  /// Writes the Apple-provided full name (and email) into `profiles.app_users`
  /// when present, so the user isn't prompted to retype them afterwards.
  Future<void> _persistAppleProfile(
    AuthResponse response,
    AuthorizationCredentialAppleID credential,
  ) async {
    final userId = response.user?.id;
    if (userId == null) return;

    final firstName = credential.givenName?.trim() ?? '';
    final secondName = credential.familyName?.trim() ?? '';
    final email = (credential.email ?? response.user?.email)?.trim() ?? '';

    // Nothing useful to store (likely a returning user) — leave the existing
    // row untouched so we never overwrite a real name with blanks.
    if (firstName.isEmpty && secondName.isEmpty) return;

    try {
      await _client
          .schema('profiles')
          .from('app_users')
          .upsert({
            'id': userId,
            if (firstName.isNotEmpty) 'first_name': firstName,
            if (secondName.isNotEmpty) 'second_name': secondName,
            if (email.isNotEmpty) 'email': email,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'id')
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Swallow — sign-in already succeeded. Worst case the user completes
      // their name in the profile flow as before.
    }
  }
}
