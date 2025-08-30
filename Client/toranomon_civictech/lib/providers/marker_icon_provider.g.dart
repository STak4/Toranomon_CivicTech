// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marker_icon_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$markerIconRepositoryHash() =>
    r'27f13916068968970d9efec651be0f45ac59f746';

/// マーカーアイコンリポジトリプロバイダー
///
/// Copied from [markerIconRepository].
@ProviderFor(markerIconRepository)
final markerIconRepositoryProvider =
    AutoDisposeProvider<MarkerIconRepository>.internal(
      markerIconRepository,
      name: r'markerIconRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$markerIconRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarkerIconRepositoryRef = AutoDisposeProviderRef<MarkerIconRepository>;
String _$postMarkerIconHash() => r'ae09a2cd3ff5bea63145cab9ddf0934addd68063';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 特定の投稿のアイコンを取得するプロバイダー
///
/// Copied from [postMarkerIcon].
@ProviderFor(postMarkerIcon)
const postMarkerIconProvider = PostMarkerIconFamily();

/// 特定の投稿のアイコンを取得するプロバイダー
///
/// Copied from [postMarkerIcon].
class PostMarkerIconFamily extends Family<BitmapDescriptor> {
  /// 特定の投稿のアイコンを取得するプロバイダー
  ///
  /// Copied from [postMarkerIcon].
  const PostMarkerIconFamily();

  /// 特定の投稿のアイコンを取得するプロバイダー
  ///
  /// Copied from [postMarkerIcon].
  PostMarkerIconProvider call(String postId) {
    return PostMarkerIconProvider(postId);
  }

  @override
  PostMarkerIconProvider getProviderOverride(
    covariant PostMarkerIconProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postMarkerIconProvider';
}

/// 特定の投稿のアイコンを取得するプロバイダー
///
/// Copied from [postMarkerIcon].
class PostMarkerIconProvider extends AutoDisposeProvider<BitmapDescriptor> {
  /// 特定の投稿のアイコンを取得するプロバイダー
  ///
  /// Copied from [postMarkerIcon].
  PostMarkerIconProvider(String postId)
    : this._internal(
        (ref) => postMarkerIcon(ref as PostMarkerIconRef, postId),
        from: postMarkerIconProvider,
        name: r'postMarkerIconProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postMarkerIconHash,
        dependencies: PostMarkerIconFamily._dependencies,
        allTransitiveDependencies:
            PostMarkerIconFamily._allTransitiveDependencies,
        postId: postId,
      );

  PostMarkerIconProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    BitmapDescriptor Function(PostMarkerIconRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostMarkerIconProvider._internal(
        (ref) => create(ref as PostMarkerIconRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<BitmapDescriptor> createElement() {
    return _PostMarkerIconProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostMarkerIconProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostMarkerIconRef on AutoDisposeProviderRef<BitmapDescriptor> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _PostMarkerIconProviderElement
    extends AutoDisposeProviderElement<BitmapDescriptor>
    with PostMarkerIconRef {
  _PostMarkerIconProviderElement(super.provider);

  @override
  String get postId => (origin as PostMarkerIconProvider).postId;
}

String _$postsMarkerIconsHash() => r'3188868ad7da4427bfb2ea0b97bfef40efdee3bf';

/// 複数投稿のアイコンを一括取得するプロバイダー
///
/// Copied from [postsMarkerIcons].
@ProviderFor(postsMarkerIcons)
const postsMarkerIconsProvider = PostsMarkerIconsFamily();

/// 複数投稿のアイコンを一括取得するプロバイダー
///
/// Copied from [postsMarkerIcons].
class PostsMarkerIconsFamily extends Family<Map<String, BitmapDescriptor>> {
  /// 複数投稿のアイコンを一括取得するプロバイダー
  ///
  /// Copied from [postsMarkerIcons].
  const PostsMarkerIconsFamily();

  /// 複数投稿のアイコンを一括取得するプロバイダー
  ///
  /// Copied from [postsMarkerIcons].
  PostsMarkerIconsProvider call(List<String> postIds) {
    return PostsMarkerIconsProvider(postIds);
  }

  @override
  PostsMarkerIconsProvider getProviderOverride(
    covariant PostsMarkerIconsProvider provider,
  ) {
    return call(provider.postIds);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postsMarkerIconsProvider';
}

/// 複数投稿のアイコンを一括取得するプロバイダー
///
/// Copied from [postsMarkerIcons].
class PostsMarkerIconsProvider
    extends AutoDisposeProvider<Map<String, BitmapDescriptor>> {
  /// 複数投稿のアイコンを一括取得するプロバイダー
  ///
  /// Copied from [postsMarkerIcons].
  PostsMarkerIconsProvider(List<String> postIds)
    : this._internal(
        (ref) => postsMarkerIcons(ref as PostsMarkerIconsRef, postIds),
        from: postsMarkerIconsProvider,
        name: r'postsMarkerIconsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postsMarkerIconsHash,
        dependencies: PostsMarkerIconsFamily._dependencies,
        allTransitiveDependencies:
            PostsMarkerIconsFamily._allTransitiveDependencies,
        postIds: postIds,
      );

  PostsMarkerIconsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postIds,
  }) : super.internal();

  final List<String> postIds;

  @override
  Override overrideWith(
    Map<String, BitmapDescriptor> Function(PostsMarkerIconsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostsMarkerIconsProvider._internal(
        (ref) => create(ref as PostsMarkerIconsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postIds: postIds,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Map<String, BitmapDescriptor>> createElement() {
    return _PostsMarkerIconsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsMarkerIconsProvider && other.postIds == postIds;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postIds.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostsMarkerIconsRef
    on AutoDisposeProviderRef<Map<String, BitmapDescriptor>> {
  /// The parameter `postIds` of this provider.
  List<String> get postIds;
}

class _PostsMarkerIconsProviderElement
    extends AutoDisposeProviderElement<Map<String, BitmapDescriptor>>
    with PostsMarkerIconsRef {
  _PostsMarkerIconsProviderElement(super.provider);

  @override
  List<String> get postIds => (origin as PostsMarkerIconsProvider).postIds;
}

String _$markerIconNotifierHash() =>
    r'aac3da7df65da88b054d24c9aab891b34263c00e';

/// マーカーアイコン状態管理プロバイダー
///
/// Copied from [MarkerIconNotifier].
@ProviderFor(MarkerIconNotifier)
final markerIconNotifierProvider =
    AutoDisposeNotifierProvider<MarkerIconNotifier, MarkerIconState>.internal(
      MarkerIconNotifier.new,
      name: r'markerIconNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$markerIconNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MarkerIconNotifier = AutoDisposeNotifier<MarkerIconState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
