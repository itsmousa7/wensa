import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  final SupabaseClient _client;

  GoogleAuthService(this._client);

  Future<AuthResponse> signInWithGoogle() async {
    const iosClient =
        '722493133487-ok3rjruur8v11dd6int6e6v3945j37m6.apps.googleusercontent.com';
    const webClient =
        '722493133487-qcbnu0utooio62r15hi45pr5n11han9j.apps.googleusercontent.com';

    final google = GoogleSignIn.instance;

    await google.initialize(
      clientId: iosClient,
      serverClientId: webClient,
    );

    final GoogleSignInAccount googleUser = await google.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('Missing Google ID Token');

    return await _client.auth
        .signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception(
            'Sign-in timed out. Please try again.',
          ),
        );
  }
}
