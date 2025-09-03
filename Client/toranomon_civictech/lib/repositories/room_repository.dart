import '../models/models.dart';

/// ルームリポジトリインターフェース
/// 
/// ルームの作成、管理、投稿の関連付け機能を提供するインターフェース
abstract class RoomRepository {
  /// 新しいルームを作成
  /// 
  /// 戻り値: 作成されたルームID
  Future<String> createRoom();

  /// ルームが存在するかどうかを確認
  /// 
  /// [roomId] 確認するルームID
  /// 戻り値: ルームが存在するかどうか
  Future<bool> roomExists(String roomId);

  /// 投稿をルームに追加
  /// 
  /// [roomId] ルームID
  /// [postId] 追加する投稿のID
  Future<void> addPostToRoom(String roomId, String postId);

  /// ルーム内の投稿IDリストを取得
  /// 
  /// [roomId] ルームID
  /// 戻り値: ルーム内の投稿IDのリスト
  Future<List<String>> getPostIdsInRoom(String roomId);

  /// ルームの詳細情報を取得
  /// 
  /// [roomId] ルームID
  /// 戻り値: ルームの詳細情報（存在しない場合はnull）
  Future<Room?> getRoomById(String roomId);

  /// ルームを削除
  /// 
  /// [roomId] 削除するルームID
  Future<void> deleteRoom(String roomId);

  /// 投稿をルームから削除
  /// 
  /// [roomId] ルームID
  /// [postId] 削除する投稿のID
  Future<void> removePostFromRoom(String roomId, String postId);

  /// ユーザーが作成したルームのリストを取得
  /// 
  /// [userId] ユーザーID
  /// 戻り値: ユーザーが作成したルームのリスト
  Future<List<Room>> getRoomsByUser(String userId);

  /// ルーム情報を更新
  /// 
  /// [room] 更新するルーム情報
  /// 戻り値: 更新されたルーム情報
  Future<Room> updateRoom(Room room);

  /// ルームの投稿数を取得
  /// 
  /// [roomId] ルームID
  /// 戻り値: ルーム内の投稿数
  Future<int> getPostCountInRoom(String roomId);

  /// ランダムなルームIDを生成
  /// 
  /// 戻り値: 生成されたユニークなルームID
  Future<String> generateUniqueRoomId();
}