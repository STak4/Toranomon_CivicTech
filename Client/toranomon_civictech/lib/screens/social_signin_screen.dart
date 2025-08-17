import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_providers.dart';
import '../utils/app_logger.dart';

class SocialSigninScreen extends ConsumerStatefulWidget {
  const SocialSigninScreen({super.key});

  @override
  ConsumerState<SocialSigninScreen> createState() => _SocialSigninScreenState();
}

class _SocialSigninScreenState extends ConsumerState<SocialSigninScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(authRepositoryProvider);

    // 画面表示時のログ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.d('Screen - Sign-in screen displayed');
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('サインイン'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Toranomon CivicTech',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'アプリにサインインしてください',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 48),

                    // Googleサインインボタン
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: const Text(
                          'Googleでサインイン',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () async {
                          AppLogger.d('Action - User initiated Google Sign-In');
                          setState(() => _loading = true);
                          try {
                            await repo.signInWithGoogle();
                            AppLogger.d(
                              'Action - Google Sign-In completed successfully',
                            );
                            // 強制的にauthStateProviderを無効化して再読込
                            ref.invalidate(authStateWithRefreshProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('サインインしました')),
                              );
                            }
                          } catch (e) {
                            AppLogger.d('Action - Google Sign-In failed: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('サインイン失敗: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Appleサインインボタン
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.apple, size: 24),
                        label: const Text(
                          'Appleでサインイン',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () async {
                          AppLogger.d('Action - User initiated Apple Sign-In');
                          setState(() => _loading = true);
                          try {
                            await repo.signInWithApple();
                            AppLogger.d(
                              'Action - Apple Sign-In completed successfully',
                            );
                            // 強制的にauthStateProviderを無効化して再読込
                            ref.invalidate(authStateWithRefreshProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('サインインしました')),
                              );
                            }
                          } catch (e) {
                            AppLogger.d('Action - Apple Sign-In failed: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('サインイン失敗: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
