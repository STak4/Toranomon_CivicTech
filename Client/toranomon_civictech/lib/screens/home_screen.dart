import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_providers.dart';
import '../utils/app_logger.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateWithRefreshProvider);
    final repo = ref.watch(authRepositoryProvider);

    // 画面表示時のログ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authState.whenData((user) {
        AppLogger.d(
          'Screen - Home screen displayed for user: ${user?.uid ?? "not_signed_in"}',
        );
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              AppLogger.d('Action - User initiated sign out from home screen');
              try {
                await repo.signOut();
                AppLogger.d('Action - Sign out completed successfully');
              } catch (e) {
                AppLogger.d('Action - Sign out failed: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('サインアウトに失敗しました: $e')));
                }
              }
            },
          ),
        ],
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (user) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ユーザー情報
                if (user != null) ...[
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName ?? '名前なし',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          user.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // メニューカード
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildMenuCard(
                        context,
                        'プロフィール',
                        Icons.person,
                        Colors.blue,
                        () {
                          AppLogger.d(
                            'Navigation - User navigated to profile screen',
                          );
                          context.goNamed('profile');
                        },
                      ),
                      _buildMenuCard(
                        context,
                        'Unity起動',
                        Icons.games,
                        Colors.green,
                        () {
                          AppLogger.d(
                            'Navigation - User navigated to Unity screen',
                          );
                          context.goNamed('unity');
                        },
                      ),
                      _buildMenuCard(
                        context,
                        '地図',
                        Icons.map,
                        Colors.orange,
                        () {
                          AppLogger.d(
                            'Navigation - User navigated to map screen',
                          );
                          context.goNamed('map');
                        },
                      ),
                      _buildMenuCard(
                        context,
                        '設定',
                        Icons.settings,
                        Colors.grey,
                        () {
                          // TODO: 設定画面を実装
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('設定画面は未実装です')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
