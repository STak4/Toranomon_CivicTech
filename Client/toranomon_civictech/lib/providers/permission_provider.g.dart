// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appLifecycleHash() => r'232b0970551c2d0c916bcf2d953c48ef979e3311';

/// アプリライフサイクル状態プロバイダー
///
/// Copied from [appLifecycle].
@ProviderFor(appLifecycle)
final appLifecycleProvider = AutoDisposeProvider<AppLifecycleState>.internal(
  appLifecycle,
  name: r'appLifecycleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appLifecycleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppLifecycleRef = AutoDisposeProviderRef<AppLifecycleState>;
String _$galleryPermissionHash() => r'68f5cac84ab3c08478937b27a026c979d405d6f6';

/// ギャラリー権限プロバイダー
///
/// ギャラリー保存に必要な権限の状態を管理する
///
/// Copied from [GalleryPermission].
@ProviderFor(GalleryPermission)
final galleryPermissionProvider =
    AutoDisposeAsyncNotifierProvider<
      GalleryPermission,
      PermissionInfo
    >.internal(
      GalleryPermission.new,
      name: r'galleryPermissionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$galleryPermissionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$GalleryPermission = AutoDisposeAsyncNotifier<PermissionInfo>;
String _$permissionWatcherHash() => r'a3e1e5ee52d82364a5c491461df28f4ab2eee002';

/// 権限状態の監視プロバイダー
///
/// アプリがフォアグラウンドに戻った時などに権限状態を自動更新
///
/// Copied from [PermissionWatcher].
@ProviderFor(PermissionWatcher)
final permissionWatcherProvider =
    AutoDisposeNotifierProvider<PermissionWatcher, bool>.internal(
      PermissionWatcher.new,
      name: r'permissionWatcherProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$permissionWatcherHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PermissionWatcher = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
