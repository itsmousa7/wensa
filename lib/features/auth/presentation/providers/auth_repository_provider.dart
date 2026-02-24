import 'package:future_riverpod/features/auth/domain/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';

part 'auth_repository_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(supabaseProvider));
}

@riverpod
Stream<User?> authStateStream(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges.map((data) => data.session?.user);
}
