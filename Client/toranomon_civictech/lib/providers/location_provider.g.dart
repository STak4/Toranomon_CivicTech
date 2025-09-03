// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationRepositoryHash() =>
    r'f22cdb60583343214c0a99db59a9c232e3a61290';

/// 位置情報リポジトリのプロバイダー
///
/// Copied from [locationRepository].
@ProviderFor(locationRepository)
final locationRepositoryProvider =
    AutoDisposeProvider<LocationRepository>.internal(
      locationRepository,
      name: r'locationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$locationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationRepositoryRef = AutoDisposeProviderRef<LocationRepository>;
String _$currentLocationHash() => r'479eb304952b5ad1a34fd04afb9a60746c4d611d';

/// 現在地を取得する便利なプロバイダー
///
/// Copied from [currentLocation].
@ProviderFor(currentLocation)
final currentLocationProvider = AutoDisposeFutureProvider<Position?>.internal(
  currentLocation,
  name: r'currentLocationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLocationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentLocationRef = AutoDisposeFutureProviderRef<Position?>;
String _$isLocationAvailableHash() =>
    r'3551740c9d2b453fb28ed9ddd8ed3b547b5749cc';

/// 位置情報が利用可能かどうかを確認する便利なプロバイダー
///
/// Copied from [isLocationAvailable].
@ProviderFor(isLocationAvailable)
final isLocationAvailableProvider = AutoDisposeProvider<bool>.internal(
  isLocationAvailable,
  name: r'isLocationAvailableProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isLocationAvailableHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsLocationAvailableRef = AutoDisposeProviderRef<bool>;
String _$locationNotifierHash() => r'd4e0ed96dbaf3cef3982fdd3210015b421da0793';

/// 位置情報状態管理のプロバイダー
///
/// Copied from [LocationNotifier].
@ProviderFor(LocationNotifier)
final locationNotifierProvider =
    AutoDisposeNotifierProvider<LocationNotifier, LocationState>.internal(
      LocationNotifier.new,
      name: r'locationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$locationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LocationNotifier = AutoDisposeNotifier<LocationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
