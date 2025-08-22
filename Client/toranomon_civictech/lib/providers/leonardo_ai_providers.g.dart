// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leonardo_ai_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leonardoApiKeyHash() => r'd3eae884185051187fe40798e323c036ea0ed000';

/// Leonardo.ai APIキープロバイダー
///
/// 環境変数またはセキュアストレージからAPIキーを取得する
///
/// Copied from [leonardoApiKey].
@ProviderFor(leonardoApiKey)
final leonardoApiKeyProvider = AutoDisposeFutureProvider<String>.internal(
  leonardoApiKey,
  name: r'leonardoApiKeyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$leonardoApiKeyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeonardoApiKeyRef = AutoDisposeFutureProviderRef<String>;
String _$leonardoAiServiceHash() => r'271f44c057945bf7d45df532e06ee17c9e6f0cc7';

/// Leonardo.ai サービスプロバイダー
///
/// APIキーを使用してLeonardoAiServiceのインスタンスを提供する
///
/// Copied from [leonardoAiService].
@ProviderFor(leonardoAiService)
final leonardoAiServiceProvider =
    AutoDisposeProvider<LeonardoAiService>.internal(
      leonardoAiService,
      name: r'leonardoAiServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leonardoAiServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeonardoAiServiceRef = AutoDisposeProviderRef<LeonardoAiService>;
String _$leonardoAiRepositoryHash() =>
    r'163e0b58af4515ba9f1df54c057af8b7222f6d65';

/// Leonardo.ai リポジトリプロバイダー
///
/// LeonardoAiRepositoryのインスタンスを提供する
///
/// Copied from [leonardoAiRepository].
@ProviderFor(leonardoAiRepository)
final leonardoAiRepositoryProvider =
    AutoDisposeProvider<LeonardoAiRepository>.internal(
      leonardoAiRepository,
      name: r'leonardoAiRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leonardoAiRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeonardoAiRepositoryRef = AutoDisposeProviderRef<LeonardoAiRepository>;
String _$imageGenerationHash() => r'43cd8c782b8cc369397c3fc9cb3f736eed9584cc';

/// 画像生成プロバイダー
///
/// テキストプロンプトから画像を生成する機能を提供する
///
/// Copied from [ImageGeneration].
@ProviderFor(ImageGeneration)
final imageGenerationProvider =
    AutoDisposeAsyncNotifierProvider<ImageGeneration, GeneratedImage?>.internal(
      ImageGeneration.new,
      name: r'imageGenerationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$imageGenerationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ImageGeneration = AutoDisposeAsyncNotifier<GeneratedImage?>;
String _$imageEditingHash() => r'd922a4fcbb9bc6fb70b75929e65bd848b628ebb8';

/// 画像編集プロバイダー
///
/// 既存の画像を編集する機能を提供する
///
/// Copied from [ImageEditing].
@ProviderFor(ImageEditing)
final imageEditingProvider =
    AutoDisposeAsyncNotifierProvider<ImageEditing, EditedImage?>.internal(
      ImageEditing.new,
      name: r'imageEditingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$imageEditingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ImageEditing = AutoDisposeAsyncNotifier<EditedImage?>;
String _$gallerySaverProviderHash() =>
    r'bc6bee448ad99e800433e0607b7b7196ff7b1e66';

/// ギャラリー保存プロバイダー
///
/// 生成・編集された画像をデバイスのギャラリーに保存する
///
/// Copied from [GallerySaverProvider].
@ProviderFor(GallerySaverProvider)
final gallerySaverProviderProvider =
    AutoDisposeAsyncNotifierProvider<GallerySaverProvider, bool>.internal(
      GallerySaverProvider.new,
      name: r'gallerySaverProviderProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$gallerySaverProviderHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$GallerySaverProvider = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
