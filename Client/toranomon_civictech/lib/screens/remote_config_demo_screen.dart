import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firebase_remote_config_provider.dart';

class RemoteConfigDemoScreen extends ConsumerStatefulWidget {
  const RemoteConfigDemoScreen({super.key});

  @override
  ConsumerState<RemoteConfigDemoScreen> createState() =>
      _RemoteConfigDemoScreenState();
}

class _RemoteConfigDemoScreenState
    extends ConsumerState<RemoteConfigDemoScreen> {
  @override
  Widget build(BuildContext context) {
    final remoteConfigState = ref.watch(remoteConfigStateProvider);
    final welcomeMessage = ref.watch(welcomeMessageProvider);
    final featureFlagNewUI = ref.watch(featureFlagNewUIProvider);
    final isMaintenanceMode = ref.watch(isMaintenanceModeProvider);
    final maintenanceMessage = ref.watch(maintenanceMessageProvider);
    final showAds = ref.watch(showAdsProvider);
    final adFrequency = ref.watch(adFrequencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RemoteConfig デモ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(remoteConfigStateProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状態表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RemoteConfig 状態',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('初期化済み: ${remoteConfigState.isInitialized}'),
                    Text('読み込み中: ${remoteConfigState.isLoading}'),
                    if (remoteConfigState.lastFetchTime != null)
                      Text('最終更新: ${remoteConfigState.lastFetchTime}'),
                    if (remoteConfigState.error != null)
                      Text(
                        'エラー: ${remoteConfigState.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 設定値表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('設定値', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildConfigItem('ウェルカムメッセージ', welcomeMessage),
                    _buildConfigItem('新UI機能フラグ', featureFlagNewUI.toString()),
                    _buildConfigItem('メンテナンスモード', isMaintenanceMode.toString()),
                    _buildConfigItem('メンテナンスメッセージ', maintenanceMessage),
                    _buildConfigItem('広告表示', showAds.toString()),
                    _buildConfigItem('広告頻度', adFrequency.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 機能デモ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('機能デモ', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),

                    // ウェルカムメッセージ
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        welcomeMessage,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 新UI機能フラグ
                    if (featureFlagNewUI)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Text(
                          '🎉 新UI機能が有効です！',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // メンテナンスモード
                    if (isMaintenanceMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              maintenanceMessage,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 広告表示
                    if (showAds)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.ads_click,
                              color: Colors.purple,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '広告が表示されます（頻度: $adFrequency回/セッション）',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
