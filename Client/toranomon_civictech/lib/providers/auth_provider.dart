import 'package:flutter_riverpod/flutter_riverpod.dart';

// 認証状態を表すクラス
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? email;

  const AuthState({required this.isAuthenticated, this.userId, this.email});

  AuthState copyWith({bool? isAuthenticated, String? userId, String? email}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
    );
  }
}

// 認証状態を管理するNotifierProvider
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isAuthenticated: false));

  // サインイン処理
  Future<void> signIn(String email, String password) async {
    // 実際の認証処理をここに実装
    // 今回は仮の実装として、少し待機してから認証成功とする
    await Future.delayed(const Duration(seconds: 1));

    state = AuthState(isAuthenticated: true, userId: 'user_123', email: email);
  }

  // サインアウト処理
  Future<void> signOut() async {
    // 実際のサインアウト処理をここに実装
    await Future.delayed(const Duration(milliseconds: 500));

    state = const AuthState(isAuthenticated: false);
  }

  // 認証状態をチェック（アプリ起動時など）
  Future<void> checkAuthStatus() async {
    // 実際の実装では、SharedPreferencesやSecureStorageから
    // 保存されたトークンを確認する
    await Future.delayed(const Duration(milliseconds: 300));

    // 仮の実装：常に未認証状態とする
    state = const AuthState(isAuthenticated: false);
  }
}

// 認証状態を管理するプロバイダー
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier();
});

// 認証済みかどうかを監視するプロバイダー
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});
