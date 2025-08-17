import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../utils/app_logger.dart';

class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;

  /// nonceを生成
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// SHA-256ハッシュを生成
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  Stream<User?> userChanges() => _auth.userChanges();
  User? get currentUser => _auth.currentUser;

  /// Googleサインイン
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // WebはPopupでOK
      final provider = GoogleAuthProvider();
      await _auth.signInWithPopup(provider);
      return;
    }

    // iOS/Android: google_sign_in でトークン取得→Firebaseに連携
    final googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Sign-in cancelled');
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  /// Appleサインイン
  Future<void> signInWithApple() async {
    if (kIsWeb) {
      throw Exception('Apple Sign-In is not supported on web');
    }

    // nonce（リプレイ対策）を生成
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    // iOS/Android: sign_in_with_apple でトークン取得→Firebaseに連携
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.fullName,
        AppleIDAuthorizationScopes.email,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // 初回サインイン時のみ名前を更新
    if (userCredential.user != null) {
      // 名前が提供されている場合（初回サインイン）のみ更新
      if (appleCredential.givenName?.isNotEmpty == true &&
          appleCredential.familyName?.isNotEmpty == true) {
        final displayName =
            '${appleCredential.givenName} ${appleCredential.familyName}'.trim();

        if (displayName.isNotEmpty) {
          // 初回サインイン時のみ名前を設定
          await userCredential.user!.updateDisplayName(displayName);
          await userCredential.user!.reload();
        }
      }
    }
  }

  Future<void> signOut() async {
    AppLogger.d('Auth - Starting sign out process');

    // 先にFirebaseをサインアウト
    await _auth.signOut();
    AppLogger.d('Auth - Firebase sign out completed');

    // Google側のセッションも切りたい場合（モバイルのみ推奨）
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      AppLogger.d('Auth - Google Sign-In session cleared');
    }

    AppLogger.d('Auth - Sign out completed successfully');
  }

  /// 表示名を更新
  Future<void> updateDisplayName(String displayName) async {
    AppLogger.d('Auth - Starting display name update: $displayName');

    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.d('Auth - No signed-in user found for display name update');
      throw Exception('No signed-in user');
    }

    // Firebase Authの表示名を更新
    await user.updateDisplayName(displayName);
    await user.reload();
    AppLogger.d('Auth - Display name updated successfully');
  }

  /// アカウント削除（再認証込み）
  Future<void> deleteAccountWithReauth() async {
    AppLogger.d('Auth - Starting account deletion process');

    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.d('Auth - No signed-in user found for account deletion');
      throw Exception('No signed-in user');
    }

    try {
      await user.delete();
      AppLogger.d('Auth - Account deleted successfully without reauth');
      return; // 再認証不要で消せたケース
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        AppLogger.d('Auth - Account deletion failed with error: ${e.code}');
        rethrow;
      }

      AppLogger.d('Auth - Re-authentication required for account deletion');
      // 再認証が必要
      if (kIsWeb) {
        AppLogger.d('Auth - Using Google re-auth for web');
        final provider = GoogleAuthProvider();
        await user.reauthenticateWithPopup(provider);
      } else {
        // ユーザーのプロバイダーに応じて再認証方法を選択
        final providers = user.providerData.map((p) => p.providerId).toList();
        AppLogger.d('Auth - User providers: $providers');

        if (providers.contains('apple.com')) {
          AppLogger.d('Auth - Using Apple re-auth');
          // Appleで再認証
          final appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );
          final oauthCredential = OAuthProvider('apple.com').credential(
            idToken: appleCredential.identityToken,
            accessToken: appleCredential.authorizationCode,
          );
          await user.reauthenticateWithCredential(oauthCredential);
        } else {
          AppLogger.d('Auth - Using Google re-auth');
          // Googleで再認証（デフォルト）
          final googleSignIn = GoogleSignIn();
          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          if (googleUser == null) {
            AppLogger.d('Auth - Re-auth cancelled by user');
            throw Exception('Re-auth cancelled');
          }
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await user.reauthenticateWithCredential(credential);
        }
      }

      AppLogger.d(
        'Auth - Re-authentication completed, retrying account deletion',
      );
      // 再試行
      await user.delete();
      AppLogger.d('Auth - Account deleted successfully after reauth');
    }
  }
}
