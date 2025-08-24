import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart' as dio;

import 'app_logger.dart';
import 'image_processing_optimizer.dart';
import 'brush_drawing_optimizer.dart';

/// リソース管理とクリーンアップユーティリティ
class ResourceManager {
  static ResourceManager? _instance;
  static ResourceManager get instance => _instance ??= ResourceManager._();
  
  ResourceManager._();

  /// アクティブなキャンセルトークン
  final Set<dio.CancelToken> _activeCancelTokens = {};
  
  /// 一時ファイルのトラッキング
  final Set<File> _tempFiles = {};
  
  /// アクティブなUI画像
  final Set<ui.Image> _activeImages = {};
  
  /// バックグラウンド移行時のコールバック
  final List<VoidCallback> _backgroundCallbacks = [];
  
  /// フォアグラウンド復帰時のコールバック
  final List<VoidCallback> _foregroundCallbacks = [];
  
  /// アプリライフサイクル監視
  WidgetsBindingObserver? _lifecycleObserver;
  
  /// メモリ警告監視タイマー
  Timer? _memoryMonitorTimer;
  
  /// 最後のクリーンアップ時刻
  DateTime? _lastCleanupTime;

  /// リソースマネージャーを初期化
  void initialize() {
    try {
      AppLogger.i('リソースマネージャーを初期化');
      
      // アプリライフサイクル監視を開始
      _startLifecycleMonitoring();
      
      // メモリ監視を開始
      _startMemoryMonitoring();
      
      // 定期クリーンアップを開始
      _startPeriodicCleanup();
      
      AppLogger.i('リソースマネージャー初期化完了');
    } catch (e, stackTrace) {
      AppLogger.e('リソースマネージャー初期化でエラー: $e', stackTrace);
    }
  }

  /// キャンセルトークンを登録
  void registerCancelToken(dio.CancelToken token) {
    try {
      _activeCancelTokens.add(token);
      AppLogger.d('キャンセルトークンを登録: ${_activeCancelTokens.length} active');
    } catch (e) {
      AppLogger.e('キャンセルトークン登録でエラー: $e');
    }
  }

  /// キャンセルトークンを解除
  void unregisterCancelToken(dio.CancelToken token) {
    try {
      _activeCancelTokens.remove(token);
      AppLogger.d('キャンセルトークンを解除: ${_activeCancelTokens.length} active');
    } catch (e) {
      AppLogger.e('キャンセルトークン解除でエラー: $e');
    }
  }

  /// 一時ファイルを登録
  void registerTempFile(File file) {
    try {
      _tempFiles.add(file);
      AppLogger.d('一時ファイルを登録: ${file.path}');
    } catch (e) {
      AppLogger.e('一時ファイル登録でエラー: $e');
    }
  }

  /// 一時ファイルを解除
  void unregisterTempFile(File file) {
    try {
      _tempFiles.remove(file);
      AppLogger.d('一時ファイルを解除: ${file.path}');
    } catch (e) {
      AppLogger.e('一時ファイル解除でエラー: $e');
    }
  }

  /// UI画像を登録
  void registerImage(ui.Image image) {
    try {
      _activeImages.add(image);
      AppLogger.d('UI画像を登録: ${_activeImages.length} active');
    } catch (e) {
      AppLogger.e('UI画像登録でエラー: $e');
    }
  }

  /// UI画像を解除
  void unregisterImage(ui.Image image) {
    try {
      _activeImages.remove(image);
      AppLogger.d('UI画像を解除: ${_activeImages.length} active');
    } catch (e) {
      AppLogger.e('UI画像解除でエラー: $e');
    }
  }

  /// バックグラウンド移行時のコールバックを登録
  void addBackgroundCallback(VoidCallback callback) {
    _backgroundCallbacks.add(callback);
  }

  /// フォアグラウンド復帰時のコールバックを登録
  void addForegroundCallback(VoidCallback callback) {
    _foregroundCallbacks.add(callback);
  }

  /// アプリライフサイクル監視を開始
  void _startLifecycleMonitoring() {
    try {
      _lifecycleObserver = _ResourceManagerObserver(this);
      WidgetsBinding.instance.addObserver(_lifecycleObserver!);
      
      AppLogger.d('アプリライフサイクル監視を開始');
    } catch (e) {
      AppLogger.e('ライフサイクル監視開始でエラー: $e');
    }
  }

  /// アプリライフサイクル状態変更を処理
  void _handleAppLifecycleStateChanged(AppLifecycleState state) {
    try {
      AppLogger.i('アプリライフサイクル状態変更: $state');
      
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
          _handleAppBackground();
          break;
        case AppLifecycleState.resumed:
          _handleAppForeground();
          break;
        case AppLifecycleState.inactive:
          // 何もしない
          break;
        case AppLifecycleState.hidden:
          _handleAppBackground();
          break;
      }
    } catch (e) {
      AppLogger.e('ライフサイクル状態変更処理でエラー: $e');
    }
  }

  /// アプリバックグラウンド移行時の処理
  void _handleAppBackground() {
    try {
      AppLogger.i('アプリバックグラウンド移行処理を開始');
      
      // 進行中のリクエストをキャンセル
      _cancelActiveRequests();
      
      // メモリを最適化
      _optimizeMemoryForBackground();
      
      // バックグラウンドコールバックを実行
      for (final callback in _backgroundCallbacks) {
        try {
          callback();
        } catch (e) {
          AppLogger.e('バックグラウンドコールバック実行でエラー: $e');
        }
      }
      
      AppLogger.i('アプリバックグラウンド移行処理完了');
    } catch (e) {
      AppLogger.e('バックグラウンド移行処理でエラー: $e');
    }
  }

  /// アプリフォアグラウンド復帰時の処理
  void _handleAppForeground() {
    try {
      AppLogger.i('アプリフォアグラウンド復帰処理を開始');
      
      // フォアグラウンドコールバックを実行
      for (final callback in _foregroundCallbacks) {
        try {
          callback();
        } catch (e) {
          AppLogger.e('フォアグラウンドコールバック実行でエラー: $e');
        }
      }
      
      AppLogger.i('アプリフォアグラウンド復帰処理完了');
    } catch (e) {
      AppLogger.e('フォアグラウンド復帰処理でエラー: $e');
    }
  }

  /// 進行中のリクエストをキャンセル
  void _cancelActiveRequests() {
    try {
      AppLogger.i('進行中のリクエストをキャンセル: ${_activeCancelTokens.length} requests');
      
      final tokensToCancel = List<dio.CancelToken>.from(_activeCancelTokens);
      
      for (final token in tokensToCancel) {
        try {
          if (!token.isCancelled) {
            token.cancel('アプリがバックグラウンドに移行しました');
          }
        } catch (e) {
          AppLogger.e('リクエストキャンセルでエラー: $e');
        }
      }
      
      _activeCancelTokens.clear();
      AppLogger.i('リクエストキャンセル完了');
    } catch (e) {
      AppLogger.e('リクエストキャンセル処理でエラー: $e');
    }
  }

  /// バックグラウンド用メモリ最適化（軽量化）
  void _optimizeMemoryForBackground() {
    try {
      AppLogger.i('バックグラウンド用メモリ最適化を開始（軽量版）');
      
      // 軽量な最適化のみ実行
      // ブラシ描画キャッシュをクリア（コメントアウト）
      // BrushDrawingOptimizer.optimizeMemoryUsage();
      
      // 画像処理キャッシュをクリア（コメントアウト）
      // ImageProcessingOptimizer.clearTempFileCache();
      
      // UI画像を解放（コメントアウト）
      // _disposeActiveImages();
      
      // 古い一時ファイルのみ削除（これは実行）
      _cleanupOldTempFiles();
      
      AppLogger.i('バックグラウンド用メモリ最適化完了（軽量版）');
    } catch (e) {
      AppLogger.e('バックグラウンド用メモリ最適化でエラー: $e');
    }
  }

  /// アクティブなUI画像を解放
  void _disposeActiveImages() {
    try {
      AppLogger.d('アクティブなUI画像を解放: ${_activeImages.length} images');
      
      final imagesToDispose = List<ui.Image>.from(_activeImages);
      
      for (final image in imagesToDispose) {
        try {
          image.dispose();
        } catch (e) {
          AppLogger.e('UI画像解放でエラー: $e');
        }
      }
      
      _activeImages.clear();
      AppLogger.d('UI画像解放完了');
    } catch (e) {
      AppLogger.e('UI画像解放処理でエラー: $e');
    }
  }

  /// メモリ監視を開始
  void _startMemoryMonitoring() {
    if (!kDebugMode) return; // デバッグモードでのみ監視
    
    try {
      _memoryMonitorTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _checkMemoryUsage(),
      );
      
      AppLogger.d('メモリ監視を開始');
    } catch (e) {
      AppLogger.e('メモリ監視開始でエラー: $e');
    }
  }

  /// メモリ使用量をチェック
  void _checkMemoryUsage() {
    if (!kDebugMode) return;
    
    try {
      final memoryUsage = ProcessInfo.currentRss;
      final memoryMB = memoryUsage / (1024 * 1024);
      
      AppLogger.d('現在のメモリ使用量: ${memoryMB.toStringAsFixed(1)} MB');
      
      // 警告閾値を超えた場合は警告ログのみ出力
      if (memoryMB > 500) { // 500MB
        AppLogger.w('メモリ使用量が警告閾値を超えました: ${memoryMB.toStringAsFixed(1)} MB');
        // 最適化処理はコメントアウト（頻繁な実行を防ぐため）
        // _performEmergencyMemoryOptimization();
      }
    } catch (e) {
      AppLogger.e('メモリ使用量チェックでエラー: $e');
    }
  }

  /// 緊急メモリ最適化（コメントアウト - 頻繁な実行を防ぐため）
  // void _performEmergencyMemoryOptimization() {
  //   try {
  //     AppLogger.i('緊急メモリ最適化を実行');
      
  //     // 全キャッシュをクリア
  //     BrushDrawingOptimizer.clearCache();
  //     ImageProcessingOptimizer.clearTempFileCache();
      
  //     // 一時ファイルを削除
  //     _cleanupTempFiles();
      
  //     // ガベージコレクションを促進
  //     _forceGarbageCollection();
      
  //     AppLogger.i('緊急メモリ最適化完了');
  //   } catch (e) {
  //     AppLogger.e('緊急メモリ最適化でエラー: $e');
  //   }
  // }

  /// 定期クリーンアップを開始
  void _startPeriodicCleanup() {
    try {
      Timer.periodic(
        const Duration(minutes: 10),
        (_) => _performPeriodicCleanup(),
      );
      
      AppLogger.d('定期クリーンアップを開始');
    } catch (e) {
      AppLogger.e('定期クリーンアップ開始でエラー: $e');
    }
  }

  /// 定期クリーンアップを実行
  void _performPeriodicCleanup() {
    try {
      final now = DateTime.now();
      
      // 前回のクリーンアップから10分以上経過している場合のみ実行
      if (_lastCleanupTime != null &&
          now.difference(_lastCleanupTime!).inMinutes < 10) {
        return;
      }
      
      AppLogger.d('定期クリーンアップを実行');
      
      // 古い一時ファイルを削除
      _cleanupOldTempFiles();
      
      // 使用されていないキャンセルトークンを削除
      _cleanupCancelTokens();
      
      _lastCleanupTime = now;
      AppLogger.d('定期クリーンアップ完了');
    } catch (e) {
      AppLogger.e('定期クリーンアップでエラー: $e');
    }
  }

  /// 古い一時ファイルを削除
  void _cleanupOldTempFiles() {
    try {
      ImageProcessingOptimizer.cleanupOldTempFiles();
      
      // 登録された一時ファイルもチェック
      final filesToRemove = <File>[];
      
      for (final file in _tempFiles) {
        try {
          if (!file.existsSync()) {
            filesToRemove.add(file);
          } else {
            final stat = file.statSync();
            final age = DateTime.now().difference(stat.modified);
            
            // 1時間以上古いファイルを削除
            if (age.inHours >= 1) {
              file.deleteSync();
              filesToRemove.add(file);
              AppLogger.d('古い一時ファイルを削除: ${file.path}');
            }
          }
        } catch (e) {
          AppLogger.e('一時ファイル削除でエラー: ${file.path} - $e');
          filesToRemove.add(file);
        }
      }
      
      // 削除されたファイルを登録から除外
      for (final file in filesToRemove) {
        _tempFiles.remove(file);
      }
    } catch (e) {
      AppLogger.e('古い一時ファイルクリーンアップでエラー: $e');
    }
  }

  /// 一時ファイルを削除
  void _cleanupTempFiles() {
    try {
      AppLogger.d('一時ファイルを削除: ${_tempFiles.length} files');
      
      final filesToRemove = <File>[];
      
      for (final file in _tempFiles) {
        try {
          if (file.existsSync()) {
            file.deleteSync();
            AppLogger.d('一時ファイル削除: ${file.path}');
          }
          filesToRemove.add(file);
        } catch (e) {
          AppLogger.e('一時ファイル削除でエラー: ${file.path} - $e');
          filesToRemove.add(file);
        }
      }
      
      // 削除されたファイルを登録から除外
      for (final file in filesToRemove) {
        _tempFiles.remove(file);
      }
      
      AppLogger.d('一時ファイル削除完了');
    } catch (e) {
      AppLogger.e('一時ファイル削除処理でエラー: $e');
    }
  }

  /// 使用されていないキャンセルトークンを削除
  void _cleanupCancelTokens() {
    try {
      final tokensToRemove = <dio.CancelToken>[];
      
      for (final token in _activeCancelTokens) {
        if (token.isCancelled) {
          tokensToRemove.add(token);
        }
      }
      
      for (final token in tokensToRemove) {
        _activeCancelTokens.remove(token);
      }
      
      if (tokensToRemove.isNotEmpty) {
        AppLogger.d('使用済みキャンセルトークンを削除: ${tokensToRemove.length} tokens');
      }
    } catch (e) {
      AppLogger.e('キャンセルトークンクリーンアップでエラー: $e');
    }
  }

  /// ガベージコレクションを促進（コメントアウト）
  // void _forceGarbageCollection() {
  //   try {
  //     // Dartのガベージコレクションを促進
  //     // 注意: これは推奨されない方法ですが、緊急時のメモリ解放のため
  //     for (int i = 0; i < 3; i++) {
  //       final list = List.generate(1000, (index) => index);
  //       list.clear();
  //     }
      
  //     AppLogger.d('ガベージコレクションを促進');
  //   } catch (e) {
  //     AppLogger.e('ガベージコレクション促進でエラー: $e');
  //   }
  // }

  /// リソース統計を取得
  Map<String, dynamic> getResourceStats() {
    try {
      return {
        'activeCancelTokens': _activeCancelTokens.length,
        'tempFiles': _tempFiles.length,
        'activeImages': _activeImages.length,
        'backgroundCallbacks': _backgroundCallbacks.length,
        'foregroundCallbacks': _foregroundCallbacks.length,
        'lastCleanupTime': _lastCleanupTime?.toIso8601String(),
        'memoryMonitoringActive': _memoryMonitorTimer?.isActive ?? false,
      };
    } catch (e) {
      AppLogger.e('リソース統計取得でエラー: $e');
      return {};
    }
  }

  /// 手動クリーンアップを実行
  void performManualCleanup() {
    try {
      AppLogger.i('手動クリーンアップを実行');
      
      _cleanupTempFiles();
      _cleanupCancelTokens();
      _disposeActiveImages();
      
      BrushDrawingOptimizer.clearCache();
      ImageProcessingOptimizer.clearTempFileCache();
      
      AppLogger.i('手動クリーンアップ完了');
    } catch (e) {
      AppLogger.e('手動クリーンアップでエラー: $e');
    }
  }

  /// リソースマネージャーを破棄
  void dispose() {
    try {
      AppLogger.i('リソースマネージャーを破棄');
      
      // タイマーを停止
      _memoryMonitorTimer?.cancel();
      
      // ライフサイクル監視を停止
      if (_lifecycleObserver != null) {
        WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
      }
      
      // 全リソースをクリーンアップ
      _cancelActiveRequests();
      _cleanupTempFiles();
      _disposeActiveImages();
      
      // キャッシュをクリア
      BrushDrawingOptimizer.dispose();
      ImageProcessingOptimizer.dispose();
      
      // コールバックをクリア
      _backgroundCallbacks.clear();
      _foregroundCallbacks.clear();
      
      AppLogger.i('リソースマネージャー破棄完了');
    } catch (e) {
      AppLogger.e('リソースマネージャー破棄でエラー: $e');
    }
  }
}

/// ResourceManager用のWidgetsBindingObserver
class _ResourceManagerObserver extends WidgetsBindingObserver {
  final ResourceManager _resourceManager;
  
  _ResourceManagerObserver(this._resourceManager);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resourceManager._handleAppLifecycleStateChanged(state);
  }
}