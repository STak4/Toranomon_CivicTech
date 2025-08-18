// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchUserDataHash() => r'277d78686d2284f68a2a753ab650fa3a4c734a52';

/// See also [fetchUserData].
@ProviderFor(fetchUserData)
final fetchUserDataProvider = AutoDisposeFutureProvider<String>.internal(
  fetchUserData,
  name: r'fetchUserDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fetchUserDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FetchUserDataRef = AutoDisposeFutureProviderRef<String>;
String _$counterHash() => r'ffef49674420958a1ecdba48de65b184eb9638e1';

/// See also [Counter].
@ProviderFor(Counter)
final counterProvider = AutoDisposeNotifierProvider<Counter, int>.internal(
  Counter.new,
  name: r'counterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$counterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Counter = AutoDisposeNotifier<int>;
String _$userStateHash() => r'f39c9f769b7caad54ad11fcb83d2077af8826670';

/// See also [UserState].
@ProviderFor(UserState)
final userStateProvider = AutoDisposeNotifierProvider<UserState, User>.internal(
  UserState.new,
  name: r'userStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserState = AutoDisposeNotifier<User>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
