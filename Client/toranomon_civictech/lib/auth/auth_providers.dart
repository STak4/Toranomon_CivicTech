import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

// User? を流すStreamProvider（null = 未サインイン）
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

// サインイン状態のbool（便利用）
final isSignedInProvider = Provider<bool>((ref) {
  final auth = ref.watch(authStateProvider).asData?.value;
  return auth != null;
});

// 強制的にauthStateProviderを更新するためのProvider
final authStateRefreshProvider = StateProvider<int>((ref) => 0);

// 更新されたauthStateProvider（強制更新対応）
final authStateWithRefreshProvider = StreamProvider<User?>((ref) {
  // authStateRefreshProviderの変更を監視
  ref.watch(authStateRefreshProvider);

  return ref.watch(authRepositoryProvider).userChanges();
});
