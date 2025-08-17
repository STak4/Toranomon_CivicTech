import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

class LoggerDemoScreen extends StatelessWidget {
  const LoggerDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logger Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'AppLogger デモ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              '各ボタンをタップして、対応するログレベルをテストしてください。\nエラーログ（Error/Fatal）のみCrashlyticsに送信されます。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildLogButton(
              context,
              'Debug Log',
              Colors.blue,
              () => AppLogger.d('これはデバッグログです'),
            ),
            const SizedBox(height: 10),
            _buildLogButton(
              context,
              'Info Log',
              Colors.green,
              () => AppLogger.i('これは情報ログです'),
            ),
            const SizedBox(height: 10),
            _buildLogButton(
              context,
              'Warning Log',
              Colors.orange,
              () => AppLogger.w('これは警告ログです'),
            ),
            const SizedBox(height: 10),
            _buildLogButton(
              context,
              'Error Log',
              Colors.red,
              () => AppLogger.e('これはエラーログです', Exception('テストエラー')),
            ),
            const SizedBox(height: 10),
            _buildLogButton(
              context,
              'Fatal Log',
              Colors.purple,
              () => AppLogger.f('これは致命的エラーログです', Exception('テスト致命的エラー')),
            ),
            const SizedBox(height: 20),
            _buildLogButton(
              context,
              'Async Error Test',
              Colors.teal,
              () => _testAsyncError(),
            ),
            const SizedBox(height: 10),
            _buildLogButton(
              context,
              'Exception Test',
              Colors.indigo,
              () => _testException(),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ログの確認方法:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Debug/Info/Warning: コンソールに表示'),
                  Text('• Error/Fatal: コンソール + Crashlyticsに送信'),
                  Text('• 開発環境: すべてのログが表示'),
                  Text('• 本番環境: エラーログのみCrashlyticsに送信'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(text),
    );
  }

  void _testAsyncError() async {
    try {
      AppLogger.i('非同期エラーテストを開始');
      await Future.delayed(const Duration(seconds: 1));
      throw Exception('非同期処理でエラーが発生しました');
    } catch (e, stackTrace) {
      AppLogger.logAsyncError(e, stackTrace, context: '非同期エラーテスト');
    }
  }

  void _testException() {
    try {
      AppLogger.i('例外テストを開始');
      throw Exception('テスト例外が発生しました');
    } catch (e, stackTrace) {
      AppLogger.logException(e, stackTrace, reason: '例外テスト');
    }
  }
}
