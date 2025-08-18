import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.d('App - Starting application initialization');
  // .envファイルを読み込み（ファイルが存在しない場合はスキップ）
  try {
    await dotenv.load(fileName: ".env");
    AppLogger.d('App - Environment variables loaded');

    // Google Maps APIキーの確認
    final apiKey = dotenv.env['GOOGLE_MAPS_KEY_IOS'];
    if (apiKey != null && apiKey.isNotEmpty) {
      AppLogger.d(
        'App - Google Maps API Key loaded: ${apiKey.substring(0, 10)}...',
      );
    } else {
      AppLogger.w('App - Google Maps API Key not found in .env file');
    }
  } catch (e) {
    AppLogger.w('App - .env file not found, using default values');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.d('App - Firebase initialized successfully');

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
