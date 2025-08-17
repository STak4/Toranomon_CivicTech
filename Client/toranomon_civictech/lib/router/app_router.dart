import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/auth_providers.dart';
import '../screens/home_screen.dart';
import '../screens/social_signin_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/unity_demo_screen.dart';
import '../screens/map_screen.dart';
import '../utils/app_logger.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    // User? の変化を購読してルーターに再評価させる
    _sub = ref.listen<User?>(
      authStateWithRefreshProvider.select((a) => a.asData?.value),
      (_, _) => notifyListeners(),
    );
  }
  final Ref ref;
  late final ProviderSubscription<User?> _sub;

  String? redirect(BuildContext context, GoRouterState state) {
    final user = ref.read(authStateWithRefreshProvider).asData?.value;
    final loggingIn = state.matchedLocation == '/signin';

    AppLogger.d(
      'Router - Checking auth state: user=${user?.uid != null ? "signed_in" : "not_signed_in"}, location=${state.matchedLocation}',
    );

    if (user == null && !loggingIn) {
      AppLogger.d('Router - Redirecting to signin page (user not signed in)');
      return '/signin'; // 未サインインはログインへ
    }
    if (user != null && loggingIn) {
      AppLogger.d('Router - Redirecting to home page (user already signed in)');
      return '/'; // サインイン済みが /signin に来たらトップへ
    }

    AppLogger.d('Router - No redirect needed');
    return null;
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/', // トップは /
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'unity',
            name: 'unity',
            builder: (context, state) => const UnityDemoScreen(),
          ),
          GoRoute(
            path: 'map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (context, state) => const SocialSigninScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Routing Error: ${state.error}'))),
  );
});
