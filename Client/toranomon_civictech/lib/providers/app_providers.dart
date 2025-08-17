import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_providers.g.dart';

// 基本的なプロバイダーの例
@riverpod
class Counter extends _$Counter {
  @override
  int build() {
    return 0;
  }

  void increment() {
    state++;
  }

  void decrement() {
    state--;
  }
}

// 非同期プロバイダーの例
@riverpod
Future<String> fetchUserData(Ref ref) async {
  // 実際のAPI呼び出しやデータベースアクセスをここに実装
  await Future.delayed(const Duration(seconds: 2));
  return 'ユーザーデータ';
}

// 状態管理の例
@riverpod
class UserState extends _$UserState {
  @override
  User build() {
    return const User(name: '', email: '');
  }

  void updateUser(String name, String email) {
    state = User(name: name, email: email);
  }

  void clearUser() {
    state = const User(name: '', email: '');
  }
}

// ユーザーモデル
class User {
  final String name;
  final String email;

  const User({required this.name, required this.email});

  User copyWith({String? name, String? email}) {
    return User(name: name ?? this.name, email: email ?? this.email);
  }
}
