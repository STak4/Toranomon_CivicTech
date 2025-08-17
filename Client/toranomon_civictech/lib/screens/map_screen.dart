import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 画面表示時のログ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.d('Screen - Map screen displayed');
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('地図'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '地図機能は準備中です',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '今後、地域の情報やイベントが表示される予定です',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
