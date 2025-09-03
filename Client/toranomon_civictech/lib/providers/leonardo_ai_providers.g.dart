// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leonardo_ai_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leonardoApiKeyHash() => r'315fdf4c83db97a5c35c974d1534a7276639880d';

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
String _$leonardoAiServiceHash() => r'33451622494fb5a6c4950fef055b41944f292199';

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
    r'ad5e1a12530e4fb456bda77162517c387e5469bb';

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
String _$gallerySaveProgressHash() =>
    r'e89f7ad6399b94e6760eaddd962363d4f66b99e1';

/// ギャラリー保存進行状況プロバイダー
///
/// Copied from [gallerySaveProgress].
@ProviderFor(gallerySaveProgress)
final gallerySaveProgressProvider =
    AutoDisposeProvider<GallerySaveProgress?>.internal(
      gallerySaveProgress,
      name: r'gallerySaveProgressProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$gallerySaveProgressHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GallerySaveProgressRef = AutoDisposeProviderRef<GallerySaveProgress?>;
String _$canvasInpaintingProgressHash() =>
    r'7b6dd0dba7b4865cb2fcad568bdbbcf6277fc667';

/// Canvas Inpainting進行状況プロバイダー
///
/// Copied from [canvasInpaintingProgress].
@ProviderFor(canvasInpaintingProgress)
final canvasInpaintingProgressProvider =
    AutoDisposeProvider<CanvasInpaintingProgress?>.internal(
      canvasInpaintingProgress,
      name: r'canvasInpaintingProgressProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$canvasInpaintingProgressHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanvasInpaintingProgressRef =
    AutoDisposeProviderRef<CanvasInpaintingProgress?>;
String _$imageGenerationHash() => r'79d8738ff448d4cb8d049c5a0472def48528f844';

/// 画像生成プロバイダー
///
/// テキストプロンプトから画像を生成する機能を提供する
///
/// Copied from [ImageGeneration].
@ProviderFor(ImageGeneration)
final imageGenerationProvider =
    AutoDisposeAsyncNotifierProvider<
      ImageGeneration,
      GenerationResult?
    >.internal(
      ImageGeneration.new,
      name: r'imageGenerationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$imageGenerationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ImageGeneration = AutoDisposeAsyncNotifier<GenerationResult?>;
String _$imageEditingHash() => r'863e53dcb80130d14d5e63d0ceb43899efb47c2a';

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
String _$gallerySaverHash() => r'0b870207ebc5e3c14df298cb94408ae502f4301a';

/// ギャラリー保存プロバイダー
///
/// 生成・編集された画像をデバイスのギャラリーに保存する
///
/// Copied from [GallerySaver].
@ProviderFor(GallerySaver)
final gallerySaverProvider =
    AutoDisposeAsyncNotifierProvider<GallerySaver, bool>.internal(
      GallerySaver.new,
      name: r'gallerySaverProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$gallerySaverHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$GallerySaver = AutoDisposeAsyncNotifier<bool>;
String _$selectedImageHash() => r'd3aab78287da1887fccf2f1ec190b8f14e917c28';

/// 選択画像プロバイダー
///
/// ギャラリーから選択した画像を管理する
///
/// Copied from [SelectedImage].
@ProviderFor(SelectedImage)
final selectedImageProvider =
    AutoDisposeNotifierProvider<SelectedImage, File?>.internal(
      SelectedImage.new,
      name: r'selectedImageProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedImageHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedImage = AutoDisposeNotifier<File?>;
String _$brushDrawingHash() => r'f420eb0322c8f2cebcb2841d3b1023d7dd4337d2';

/// ブラシ描画プロバイダー
///
/// ブラシサイズ、ストローク、描画状態を管理する
///
/// Copied from [BrushDrawing].
@ProviderFor(BrushDrawing)
final brushDrawingProvider =
    AutoDisposeNotifierProvider<BrushDrawing, BrushState>.internal(
      BrushDrawing.new,
      name: r'brushDrawingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$brushDrawingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BrushDrawing = AutoDisposeNotifier<BrushState>;
String _$canvasInpaintingHash() => r'28a7951313f900ae78d1ae59be3a86f09e6ba622';

/// Canvas Inpaintingプロバイダー
///
/// Canvas Inpainting処理を管理するAsyncNotifierプロバイダー
///
/// Copied from [CanvasInpainting].
@ProviderFor(CanvasInpainting)
final canvasInpaintingProvider =
    AutoDisposeAsyncNotifierProvider<
      CanvasInpainting,
      InpaintingResult?
    >.internal(
      CanvasInpainting.new,
      name: r'canvasInpaintingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$canvasInpaintingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CanvasInpainting = AutoDisposeAsyncNotifier<InpaintingResult?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
