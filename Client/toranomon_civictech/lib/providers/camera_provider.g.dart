// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cameraRepositoryHash() => r'f37fffff07dc81b8457d09912a082acfb538d922';

/// カメラリポジトリのプロバイダー
///
/// Copied from [cameraRepository].
@ProviderFor(cameraRepository)
final cameraRepositoryProvider = AutoDisposeProvider<CameraRepository>.internal(
  cameraRepository,
  name: r'cameraRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cameraRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CameraRepositoryRef = AutoDisposeProviderRef<CameraRepository>;
String _$cameraNotifierHash() => r'58eaeb432c183f8fa605ba0bec9b188cd9249819';

/// カメラ状態管理のプロバイダー
///
/// Copied from [CameraNotifier].
@ProviderFor(CameraNotifier)
final cameraNotifierProvider =
    AutoDisposeNotifierProvider<CameraNotifier, CameraState>.internal(
      CameraNotifier.new,
      name: r'cameraNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cameraNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CameraNotifier = AutoDisposeNotifier<CameraState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
