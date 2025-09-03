import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/app_logger.dart';
import 'room_repository.dart';

/// ルームリポジトリの実装クラス
/// 
/// Firestoreを使用したルームデータのCRUD操作と
/// ルーム内投稿の管理機能を提供
class RoomRepositoryImpl implements RoomRepository {
  final FirebaseFirestore _firestore;

  static const String _roomsCollection = 'rooms';
  static const int _roomIdLength = 8;
  static const String _roomIdCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  RoomRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> createRoom() async {
    try {
      AppLogger.i('新しいルームの作成を開始');

      // ユニークなルームIDを生成
      final roomId = await generateUniqueRoomId();
      
      final room = Room(
        id: roomId,
        createdBy: '', // 現在のユーザーIDは後で設定
        createdAt: DateTime.now(),
        postIds: [],
      );

      // Firestoreにルームを保存
      await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .set(room.toJson());

      AppLogger.i('ルームが正常に作成されました - roomId: $roomId');
      return roomId;
    } catch (e, stackTrace) {
      AppLogger.e('ルームの作成に失敗しました', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> roomExists(String roomId) async {
    try {
      AppLogger.i('ルームの存在確認 - roomId: $roomId');

      final doc = await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .get();

      final exists = doc.exists;
      AppLogger.i('ルーム存在確認結果 - roomId: $roomId, exists: $exists');
      return exists;
    } catch (e, stackTrace) {
      AppLogger.e('ルームの存在確認に失敗しました - roomId: $roomId', e, stackTrace);
      return false;
    }
  }

  @override
  Future<void> addPostToRoom(String roomId, String postId) async {
    try {
      AppLogger.i('投稿をルームに追加 - roomId: $roomId, postId: $postId');

      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection(_roomsCollection).doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('ルームが存在しません: $roomId');
        }

        final room = Room.fromJson(roomDoc.data()!);
        final updatedPostIds = List<String>.from(room.postIds);
        
        if (!updatedPostIds.contains(postId)) {
          updatedPostIds.add(postId);
          
          final updatedRoom = room.copyWith(postIds: updatedPostIds);
          transaction.update(roomRef, updatedRoom.toJson());
        }
      });

      AppLogger.i('投稿がルームに正常に追加されました - roomId: $roomId, postId: $postId');
    } catch (e, stackTrace) {
      AppLogger.e('投稿のルームへの追加に失敗しました - roomId: $roomId, postId: $postId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<String>> getPostIdsInRoom(String roomId) async {
    try {
      AppLogger.i('ルーム内の投稿ID取得 - roomId: $roomId');

      final doc = await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .get();

      if (!doc.exists) {
        AppLogger.w('ルームが存在しません - roomId: $roomId');
        return [];
      }

      final room = Room.fromJson(doc.data()!);
      AppLogger.i('ルーム内投稿ID取得完了 - roomId: $roomId, count: ${room.postIds.length}');
      return room.postIds;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム内投稿ID取得に失敗しました - roomId: $roomId', e, stackTrace);
      return [];
    }
  }

  @override
  Future<Room?> getRoomById(String roomId) async {
    try {
      AppLogger.i('ルーム詳細取得 - roomId: $roomId');

      final doc = await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .get();

      if (!doc.exists) {
        AppLogger.w('ルームが存在しません - roomId: $roomId');
        return null;
      }

      final room = Room.fromJson(doc.data()!);
      AppLogger.i('ルーム詳細取得完了 - roomId: $roomId');
      return room;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム詳細取得に失敗しました - roomId: $roomId', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    try {
      AppLogger.i('ルーム削除開始 - roomId: $roomId');

      await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .delete();

      AppLogger.i('ルームが正常に削除されました - roomId: $roomId');
    } catch (e, stackTrace) {
      AppLogger.e('ルーム削除に失敗しました - roomId: $roomId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removePostFromRoom(String roomId, String postId) async {
    try {
      AppLogger.i('投稿をルームから削除 - roomId: $roomId, postId: $postId');

      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection(_roomsCollection).doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          throw Exception('ルームが存在しません: $roomId');
        }

        final room = Room.fromJson(roomDoc.data()!);
        final updatedPostIds = List<String>.from(room.postIds);
        
        if (updatedPostIds.contains(postId)) {
          updatedPostIds.remove(postId);
          
          final updatedRoom = room.copyWith(postIds: updatedPostIds);
          transaction.update(roomRef, updatedRoom.toJson());
        }
      });

      AppLogger.i('投稿がルームから正常に削除されました - roomId: $roomId, postId: $postId');
    } catch (e, stackTrace) {
      AppLogger.e('投稿のルームからの削除に失敗しました - roomId: $roomId, postId: $postId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Room>> getRoomsByUser(String userId) async {
    try {
      AppLogger.i('ユーザーのルーム一覧取得 - userId: $userId');

      final querySnapshot = await _firestore
          .collection(_roomsCollection)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final rooms = querySnapshot.docs
          .map((doc) => Room.fromJson(doc.data()))
          .toList();

      AppLogger.i('ユーザーのルーム一覧取得完了 - userId: $userId, count: ${rooms.length}');
      return rooms;
    } catch (e, stackTrace) {
      AppLogger.e('ユーザーのルーム一覧取得に失敗しました - userId: $userId', e, stackTrace);
      return [];
    }
  }

  @override
  Future<Room> updateRoom(Room room) async {
    try {
      AppLogger.i('ルーム更新開始 - roomId: ${room.id}');

      await _firestore
          .collection(_roomsCollection)
          .doc(room.id)
          .update(room.toJson());

      AppLogger.i('ルームが正常に更新されました - roomId: ${room.id}');
      return room;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム更新に失敗しました - roomId: ${room.id}', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getPostCountInRoom(String roomId) async {
    try {
      AppLogger.i('ルーム内投稿数取得 - roomId: $roomId');

      final room = await getRoomById(roomId);
      if (room == null) {
        AppLogger.w('ルームが存在しません - roomId: $roomId');
        return 0;
      }

      final count = room.postIds.length;
      AppLogger.i('ルーム内投稿数取得完了 - roomId: $roomId, count: $count');
      return count;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム内投稿数取得に失敗しました - roomId: $roomId', e, stackTrace);
      return 0;
    }
  }

  @override
  Future<String> generateUniqueRoomId() async {
    try {
      AppLogger.i('ユニークなルームID生成開始');

      String roomId;
      bool isUnique = false;
      int attempts = 0;
      const maxAttempts = 10;

      do {
        roomId = _generateRandomRoomId();
        isUnique = !(await roomExists(roomId));
        attempts++;

        if (attempts >= maxAttempts) {
          throw Exception('ユニークなルームIDの生成に失敗しました（最大試行回数に達しました）');
        }
      } while (!isUnique);

      AppLogger.i('ユニークなルームIDが生成されました - roomId: $roomId, attempts: $attempts');
      return roomId;
    } catch (e, stackTrace) {
      AppLogger.e('ユニークなルームID生成に失敗しました', e, stackTrace);
      rethrow;
    }
  }

  /// ランダムなルームIDを生成する内部メソッド
  String _generateRandomRoomId() {
    final random = Random();
    final buffer = StringBuffer();

    for (int i = 0; i < _roomIdLength; i++) {
      final randomIndex = random.nextInt(_roomIdCharacters.length);
      buffer.write(_roomIdCharacters[randomIndex]);
    }

    return buffer.toString();
  }
}