import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'utils/app_logger.dart';
import 'utils/resource_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.d('App - Starting application initialization');
  // .envファイルを読み込み（ファイルが存在しない場合はスキップ）
  try {
    await dotenv.load(fileName: ".env");
    AppLogger.d('App - Environment variables loaded');

    // Google Maps APIキーの確認（iOS用）
    final iosApiKey = dotenv.env['GOOGLE_MAPS_KEY_IOS'];
    if (iosApiKey != null && iosApiKey.isNotEmpty) {
      AppLogger.d(
        'App - Google Maps iOS API Key loaded: ${iosApiKey.substring(0, 10)}...',
      );
    } else {
      AppLogger.w('App - Google Maps iOS API Key not found in .env file');
    }

    // Google Maps APIキーの確認（Android用）
    final androidApiKey = dotenv.env['GOOGLE_MAPS_KEY_ANDROID'];
    if (androidApiKey != null && androidApiKey.isNotEmpty) {
      AppLogger.d(
        'App - Google Maps Android API Key loaded: ${androidApiKey.substring(0, 10)}...',
      );
    } else {
      AppLogger.w('App - Google Maps Android API Key not found in .env file');
    }

    // Leonardo AI APIキーの確認
    final leonardoApiKey = dotenv.env['LEONARDO_API_KEY'];
    if (leonardoApiKey != null && leonardoApiKey.isNotEmpty) {
      AppLogger.d(
        'App - Leonardo AI API Key loaded: ${leonardoApiKey.substring(0, 10)}...',
      );
    } else {
      AppLogger.w('App - Leonardo AI API Key not found in .env file');
    }

    // 全体的なAPIキー状態の確認
    AppLogger.i('App - Environment variables status:');
    AppLogger.i(
      '  - GOOGLE_MAPS_KEY_IOS: ${iosApiKey != null ? "✓ Loaded" : "✗ Not found"}',
    );
    AppLogger.i(
      '  - GOOGLE_MAPS_KEY_ANDROID: ${androidApiKey != null ? "✓ Loaded" : "✗ Not found"}',
    );
    AppLogger.i(
      '  - LEONARDO_API_KEY: ${leonardoApiKey != null ? "✓ Loaded" : "✗ Not found"}',
    );

    // APIキーの長さ確認（基本的な検証）
    if (iosApiKey != null) {
      AppLogger.d('App - iOS API Key length: ${iosApiKey.length} characters');
    }
    if (androidApiKey != null) {
      AppLogger.d(
        'App - Android API Key length: ${androidApiKey.length} characters',
      );
    }
    if (leonardoApiKey != null) {
      AppLogger.d(
        'App - Leonardo AI API Key length: ${leonardoApiKey.length} characters',
      );
    }
  } catch (e) {
    AppLogger.w('App - .env file not found, using default values');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.d('App - Firebase initialized successfully');

  // リソースマネージャーを初期化
  ResourceManager.instance.initialize();
  AppLogger.d('App - Resource manager initialized successfully');

  // Google Maps SDKの初期化確認
  AppLogger.d('App - Google Maps SDK initialization check completed');

  AppLogger.d('App - Launching application');
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: 'Toranomon CivicTech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}
