import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';
import '../screens/post_creation_screen.dart';
import '../utils/app_logger.dart';

/// 投稿作成関連のユーティリティ関数
class PostCreationUtils {
  /// 地図タップ時に投稿作成ダイアログを表示
  /// 
  /// [context] BuildContext
  /// [position] タップされた地図上の位置
  /// [roomId] 現在のルームID（デフォルトは'default'）
  /// 戻り値: 作成された投稿（キャンセルされた場合はnull）
  static Future<Post?> showPostCreationDialog(
    BuildContext context,
    LatLng position, {
    String roomId = 'default',
  }) async {
    try {
      AppLogger.i('投稿作成ダイアログ表示 - 位置: ${position.latitude}, ${position.longitude}');

      final result = await showDialog<Post>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PostCreationDialog(
          latitude: position.latitude,
          longitude: position.longitude,
          roomId: roomId,
        ),
      );

      if (result != null) {
        AppLogger.i('投稿作成完了 - id: ${result.id}');
      } else {
        AppLogger.i('投稿作成がキャンセルされました');
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.e('投稿作成ダイアログ表示に失敗', e, stackTrace);
      return null;
    }
  }

  /// 投稿作成画面に遷移
  /// 
  /// [context] BuildContext
  /// [position] タップされた地図上の位置
  /// [roomId] 現在のルームID（デフォルトは'default'）
  /// 戻り値: 作成された投稿（キャンセルされた場合はnull）
  static Future<Post?> navigateToPostCreationScreen(
    BuildContext context,
    LatLng position, {
    String roomId = 'default',
  }) async {
    try {
      AppLogger.i('投稿作成画面遷移 - 位置: ${position.latitude}, ${position.longitude}');

      final result = await Navigator.of(context).push<Post>(
        MaterialPageRoute(
          builder: (context) => PostCreationScreen(
            latitude: position.latitude,
            longitude: position.longitude,
            roomId: roomId,
          ),
        ),
      );

      if (result != null) {
        AppLogger.i('投稿作成完了 - id: ${result.id}');
      } else {
        AppLogger.i('投稿作成がキャンセルされました');
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.e('投稿作成画面遷移に失敗', e, stackTrace);
      return null;
    }
  }

  /// 投稿作成方法を選択するボトムシート
  /// 
  /// [context] BuildContext
  /// [position] タップされた地図上の位置
  /// [roomId] 現在のルームID（デフォルトは'default'）
  /// 戻り値: 作成された投稿（キャンセルされた場合はnull）
  static Future<Post?> showPostCreationOptions(
    BuildContext context,
    LatLng position, {
    String roomId = 'default',
  }) async {
    try {
      AppLogger.i('投稿作成オプション表示 - 位置: ${position.latitude}, ${position.longitude}');

      final option = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  '投稿を作成',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add_box),
                title: const Text('クイック投稿'),
                subtitle: const Text('ダイアログで簡単に投稿'),
                onTap: () => Navigator.of(context).pop('dialog'),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('詳細投稿'),
                subtitle: const Text('専用画面で詳細に投稿'),
                onTap: () => Navigator.of(context).pop('screen'),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('キャンセル'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );

      if (option == null) {
        return null;
      }

      if (!context.mounted) return null;
      
      switch (option) {
        case 'dialog':
          return await showPostCreationDialog(context, position, roomId: roomId);
        case 'screen':
          return await navigateToPostCreationScreen(context, position, roomId: roomId);
        default:
          return null;
      }
    } catch (e, stackTrace) {
      AppLogger.e('投稿作成オプション表示に失敗', e, stackTrace);
      return null;
    }
  }

  /// 投稿作成成功時のスナックバー表示
  /// 
  /// [context] BuildContext
  /// [post] 作成された投稿
  static void showPostCreatedSnackBar(BuildContext context, Post post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('投稿「${post.title}」を作成しました'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: '詳細',
          onPressed: () {
            // TODO: 投稿詳細画面への遷移
            AppLogger.i('投稿詳細表示 - id: ${post.id}');
          },
        ),
      ),
    );
  }

  /// 投稿作成エラー時のスナックバー表示
  /// 
  /// [context] BuildContext
  /// [error] エラーメッセージ
  static void showPostCreationErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('投稿作成に失敗しました: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 地図タップハンドラーの例
  /// 
  /// 地図画面で使用できるタップハンドラーの実装例
  /// [context] BuildContext
  /// [position] タップされた位置
  /// [currentRoomId] 現在のルームID
  static Future<void> handleMapTap(
    BuildContext context,
    LatLng position, {
    String? currentRoomId,
  }) async {
    try {
      final roomId = currentRoomId ?? 'default';
      
      // 投稿作成オプションを表示
      final post = await showPostCreationOptions(
        context,
        position,
        roomId: roomId,
      );

      if (post != null && context.mounted) {
        // 成功時のフィードバック
        showPostCreatedSnackBar(context, post);
      }
    } catch (e, stackTrace) {
      AppLogger.e('地図タップ処理に失敗', e, stackTrace);
      if (context.mounted) {
        showPostCreationErrorSnackBar(context, e.toString());
      }
    }
  }
}

/// 地図タップ時の投稿作成ミックスイン
/// 
/// 地図画面で使用できるミックスイン
mixin PostCreationMapMixin<T extends StatefulWidget> on State<T> {
  /// 現在のルームIDを取得（サブクラスで実装）
  String? get currentRoomId => null;

  /// 地図タップ時の処理
  Future<void> onMapTapped(LatLng position) async {
    await PostCreationUtils.handleMapTap(
      context,
      position,
      currentRoomId: currentRoomId,
    );
  }

  /// 投稿作成後の処理（サブクラスでオーバーライド可能）
  void onPostCreated(Post post) {
    PostCreationUtils.showPostCreatedSnackBar(context, post);
  }

  /// 投稿作成エラー時の処理（サブクラスでオーバーライド可能）
  void onPostCreationError(String error) {
    PostCreationUtils.showPostCreationErrorSnackBar(context, error);
  }
}