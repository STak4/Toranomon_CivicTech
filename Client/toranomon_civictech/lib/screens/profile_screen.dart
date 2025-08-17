import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateWithRefreshProvider);
    final repo = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ユーザー情報が取得できません'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // プロフィール情報
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.displayName ?? '名前なし',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () =>
                                  _showEditNameDialog(context, user, repo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'UID: ${user.uid}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // アクションボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('サインアウト'),
                    onPressed: () async {
                      final shouldSignOut = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('サインアウト'),
                          content: const Text('本当にサインアウトしますか？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('キャンセル'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('サインアウト'),
                            ),
                          ],
                        ),
                      );

                      if (shouldSignOut == true) {
                        try {
                          await repo.signOut();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('サインアウトに失敗しました: $e')),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text(
                      'アカウント削除',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('アカウント削除の確認'),
                          content: const Text(
                            'アカウントを完全に削除します。この操作は取り消せません。よろしいですか？',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('キャンセル'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('削除する'),
                            ),
                          ],
                        ),
                      );

                      if (ok != true) return;

                      try {
                        await repo.deleteAccountWithReauth();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('アカウントを削除しました')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('削除に失敗しました: $e')),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    User user,
    AuthRepository repo,
  ) {
    final nameController = TextEditingController(text: user.displayName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('名前を編集'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '表示名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await repo.updateDisplayName(newName);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    // 強制的にauthStateProviderを無効化して再読込
                    ref.invalidate(authStateWithRefreshProvider);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('名前を更新しました')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('名前の更新に失敗しました: $e')));
                  }
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
