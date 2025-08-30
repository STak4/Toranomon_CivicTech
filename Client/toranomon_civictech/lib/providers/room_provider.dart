import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/app_logger.dart';

/// RoomRepositoryのプロバイダー
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepositoryImpl();
});

/// ルーム状態管理クラス
class RoomState {
  const RoomState({
    required this.isLoading,
    this.currentRoom,
    required this.userRooms,
    required this.roomHistory,
    this.error,
  });

  final bool isLoading;
  final Room? currentRoom;
  final List<Room> userRooms;
  final List<String> roomHistory;
  final String? error;

  RoomState copyWith({
    bool? isLoading,
    Room? currentRoom,
    List<Room>? userRooms,
    List<String>? roomHistory,
    String? error,
  }) {
    return RoomState(
      isLoading: isLoading ?? this.isLoading,
      currentRoom: currentRoom ?? this.currentRoom,
      userRooms: userRooms ?? this.userRooms,
      roomHistory: roomHistory ?? this.roomHistory,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomState &&
        other.isLoading == isLoading &&
        other.currentRoom == currentRoom &&
        other.userRooms == userRooms &&
        other.roomHistory == roomHistory &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        isLoading,
        currentRoom,
        userRooms,
        roomHistory,
        error,
      );
}

/// ルーム状態管理プロバイダー
class RoomNotifier extends StateNotifier<RoomState> {
  final RoomRepository _repository;

  RoomNotifier(this._repository)
      : super(const RoomState(
          isLoading: false,
          userRooms: [],
          roomHistory: [],
        ));

  /// 新しいルームを作成
  Future<String?> createRoom({String? userId}) async {
    try {
      AppLogger.i('ルーム作成開始 - userId: $userId');
      
      state = state.copyWith(isLoading: true, error: null);
      
      final roomId = await _repository.createRoom();
      
      // 作成されたルームの詳細を取得
      final room = await _repository.getRoomById(roomId);
      
      if (room != null) {
        // ユーザーのルーム一覧を更新
        final updatedUserRooms = [room, ...state.userRooms];
        
        // ルーム履歴を更新
        final updatedHistory = [roomId, ...state.roomHistory];
        
        state = state.copyWith(
          isLoading: false,
          currentRoom: room,
          userRooms: updatedUserRooms,
          roomHistory: updatedHistory,
        );
        
        AppLogger.i('ルーム作成完了 - roomId: $roomId');
        return roomId;
      } else {
        throw Exception('作成されたルームの取得に失敗しました');
      }
    } catch (e, stackTrace) {
      AppLogger.e('ルーム作成に失敗しました', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// ルームに参加
  Future<bool> joinRoom(String roomId) async {
    try {
      AppLogger.i('ルーム参加開始 - roomId: $roomId');
      
      state = state.copyWith(isLoading: true, error: null);
      
      // ルームの存在確認
      final exists = await _repository.roomExists(roomId);
      if (!exists) {
        state = state.copyWith(
          isLoading: false,
          error: 'ルームが存在しません: $roomId',
        );
        return false;
      }
      
      // ルーム詳細を取得
      final room = await _repository.getRoomById(roomId);
      if (room == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'ルーム情報の取得に失敗しました: $roomId',
        );
        return false;
      }
      
      // ルーム履歴を更新（重複を避ける）
      final updatedHistory = [roomId, ...state.roomHistory];
      final uniqueHistory = updatedHistory.toSet().toList();
      
      state = state.copyWith(
        isLoading: false,
        currentRoom: room,
        roomHistory: uniqueHistory,
      );
      
      AppLogger.i('ルーム参加完了 - roomId: $roomId');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム参加に失敗しました - roomId: $roomId', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 現在のルームを設定
  Future<void> setCurrentRoom(String? roomId) async {
    try {
      AppLogger.i('現在のルーム設定 - roomId: $roomId');
      
      if (roomId == null) {
        state = state.copyWith(currentRoom: null);
        return;
      }
      
      // 既に同じルームが設定されている場合はスキップ
      if (state.currentRoom?.id == roomId) {
        return;
      }
      
      state = state.copyWith(isLoading: true, error: null);
      
      final room = await _repository.getRoomById(roomId);
      if (room != null) {
        state = state.copyWith(
          isLoading: false,
          currentRoom: room,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'ルームが見つかりません: $roomId',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e('現在のルーム設定に失敗しました - roomId: $roomId', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// ユーザーのルーム一覧を読み込み
  Future<void> loadUserRooms(String userId) async {
    try {
      AppLogger.i('ユーザーのルーム一覧読み込み開始 - userId: $userId');
      
      state = state.copyWith(isLoading: true, error: null);
      
      final rooms = await _repository.getRoomsByUser(userId);
      
      state = state.copyWith(
        isLoading: false,
        userRooms: rooms,
      );
      
      AppLogger.i('ユーザーのルーム一覧読み込み完了 - userId: $userId, count: ${rooms.length}');
    } catch (e, stackTrace) {
      AppLogger.e('ユーザーのルーム一覧読み込みに失敗しました - userId: $userId', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// ルームを削除
  Future<bool> deleteRoom(String roomId) async {
    try {
      AppLogger.i('ルーム削除開始 - roomId: $roomId');
      
      state = state.copyWith(isLoading: true, error: null);
      
      await _repository.deleteRoom(roomId);
      
      // ユーザーのルーム一覧から削除
      final updatedUserRooms = state.userRooms
          .where((room) => room.id != roomId)
          .toList();
      
      // 現在のルームが削除されたルームの場合はクリア
      Room? updatedCurrentRoom = state.currentRoom;
      if (state.currentRoom?.id == roomId) {
        updatedCurrentRoom = null;
      }
      
      // ルーム履歴から削除
      final updatedHistory = state.roomHistory
          .where((id) => id != roomId)
          .toList();
      
      state = state.copyWith(
        isLoading: false,
        currentRoom: updatedCurrentRoom,
        userRooms: updatedUserRooms,
        roomHistory: updatedHistory,
      );
      
      AppLogger.i('ルーム削除完了 - roomId: $roomId');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム削除に失敗しました - roomId: $roomId', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 投稿をルームに追加
  Future<bool> addPostToRoom(String roomId, String postId) async {
    try {
      AppLogger.i('投稿をルームに追加 - roomId: $roomId, postId: $postId');
      
      await _repository.addPostToRoom(roomId, postId);
      
      // 現在のルームが更新対象の場合、ルーム情報を再読み込み
      if (state.currentRoom?.id == roomId) {
        final updatedRoom = await _repository.getRoomById(roomId);
        if (updatedRoom != null) {
          state = state.copyWith(currentRoom: updatedRoom);
        }
      }
      
      AppLogger.i('投稿のルームへの追加完了 - roomId: $roomId, postId: $postId');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('投稿のルームへの追加に失敗しました - roomId: $roomId, postId: $postId', e, stackTrace);
      return false;
    }
  }

  /// 投稿をルームから削除
  Future<bool> removePostFromRoom(String roomId, String postId) async {
    try {
      AppLogger.i('投稿をルームから削除 - roomId: $roomId, postId: $postId');
      
      await _repository.removePostFromRoom(roomId, postId);
      
      // 現在のルームが更新対象の場合、ルーム情報を再読み込み
      if (state.currentRoom?.id == roomId) {
        final updatedRoom = await _repository.getRoomById(roomId);
        if (updatedRoom != null) {
          state = state.copyWith(currentRoom: updatedRoom);
        }
      }
      
      AppLogger.i('投稿のルームからの削除完了 - roomId: $roomId, postId: $postId');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('投稿のルームからの削除に失敗しました - roomId: $roomId, postId: $postId', e, stackTrace);
      return false;
    }
  }

  /// ルーム履歴をクリア
  void clearRoomHistory() {
    AppLogger.i('ルーム履歴をクリア');
    state = state.copyWith(roomHistory: []);
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 状態をリセット
  void reset() {
    AppLogger.i('ルーム状態をリセット');
    state = const RoomState(
      isLoading: false,
      userRooms: [],
      roomHistory: [],
    );
  }

  /// ルーム情報を更新
  Future<bool> updateRoom(Room room) async {
    try {
      AppLogger.i('ルーム情報更新開始 - roomId: ${room.id}');
      
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedRoom = await _repository.updateRoom(room);
      
      // 現在のルームが更新対象の場合は更新
      Room? updatedCurrentRoom = state.currentRoom;
      if (state.currentRoom?.id == room.id) {
        updatedCurrentRoom = updatedRoom;
      }
      
      // ユーザーのルーム一覧を更新
      final updatedUserRooms = state.userRooms.map((r) {
        return r.id == updatedRoom.id ? updatedRoom : r;
      }).toList();
      
      state = state.copyWith(
        isLoading: false,
        currentRoom: updatedCurrentRoom,
        userRooms: updatedUserRooms,
      );
      
      AppLogger.i('ルーム情報更新完了 - roomId: ${room.id}');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム情報更新に失敗しました - roomId: ${room.id}', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

/// ルーム状態管理プロバイダー
final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  final repository = ref.read(roomRepositoryProvider);
  return RoomNotifier(repository);
});

/// 現在のルームプロバイダー
final currentRoomProvider = Provider<Room?>((ref) {
  return ref.watch(roomProvider).currentRoom;
});

/// 現在のルームIDプロバイダー
final currentRoomIdProvider = Provider<String?>((ref) {
  return ref.watch(roomProvider).currentRoom?.id;
});

/// ルーム存在確認プロバイダー
final roomExistsProvider = FutureProvider.family<bool, String>((ref, roomId) async {
  final repository = ref.read(roomRepositoryProvider);
  return repository.roomExists(roomId);
});

/// ルーム詳細取得プロバイダー
final roomDetailProvider = FutureProvider.family<Room?, String>((ref, roomId) async {
  final repository = ref.read(roomRepositoryProvider);
  return repository.getRoomById(roomId);
});

/// ルーム内投稿数プロバイダー
final roomPostCountProvider = FutureProvider.family<int, String>((ref, roomId) async {
  final repository = ref.read(roomRepositoryProvider);
  return repository.getPostCountInRoom(roomId);
});

/// ルーム内投稿ID一覧プロバイダー
final roomPostIdsProvider = FutureProvider.family<List<String>, String>((ref, roomId) async {
  final repository = ref.read(roomRepositoryProvider);
  return repository.getPostIdsInRoom(roomId);
});

/// ユーザーのルーム一覧プロバイダー
final userRoomsProvider = FutureProvider.family<List<Room>, String>((ref, userId) async {
  final repository = ref.read(roomRepositoryProvider);
  return repository.getRoomsByUser(userId);
});

/// ルーム統計データクラス
class RoomStats {
  const RoomStats({
    required this.totalRooms,
    required this.totalPosts,
    required this.averagePostsPerRoom,
    required this.mostActiveRoomId,
    required this.mostActiveRoomPostCount,
  });

  final int totalRooms;
  final int totalPosts;
  final double averagePostsPerRoom;
  final String? mostActiveRoomId;
  final int mostActiveRoomPostCount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomStats &&
        other.totalRooms == totalRooms &&
        other.totalPosts == totalPosts &&
        other.averagePostsPerRoom == averagePostsPerRoom &&
        other.mostActiveRoomId == mostActiveRoomId &&
        other.mostActiveRoomPostCount == mostActiveRoomPostCount;
  }

  @override
  int get hashCode => Object.hash(
        totalRooms,
        totalPosts,
        averagePostsPerRoom,
        mostActiveRoomId,
        mostActiveRoomPostCount,
      );
}

/// ルーム統計プロバイダー
final roomStatsProvider = Provider<RoomStats>((ref) {
  final rooms = ref.watch(roomProvider).userRooms;
  
  if (rooms.isEmpty) {
    return const RoomStats(
      totalRooms: 0,
      totalPosts: 0,
      averagePostsPerRoom: 0.0,
      mostActiveRoomId: null,
      mostActiveRoomPostCount: 0,
    );
  }
  
  final totalRooms = rooms.length;
  final totalPosts = rooms.fold<int>(0, (sum, room) => sum + room.postIds.length);
  final averagePostsPerRoom = totalPosts / totalRooms;
  
  // 最もアクティブなルームを見つける
  Room? mostActiveRoom;
  int maxPostCount = 0;
  
  for (final room in rooms) {
    if (room.postIds.length > maxPostCount) {
      maxPostCount = room.postIds.length;
      mostActiveRoom = room;
    }
  }
  
  return RoomStats(
    totalRooms: totalRooms,
    totalPosts: totalPosts,
    averagePostsPerRoom: averagePostsPerRoom,
    mostActiveRoomId: mostActiveRoom?.id,
    mostActiveRoomPostCount: maxPostCount,
  );
});

/// ルーム共有用データクラス
class RoomShareData {
  const RoomShareData({
    required this.roomId,
    required this.shareUrl,
    required this.qrCodeData,
  });

  final String roomId;
  final String shareUrl;
  final String qrCodeData;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomShareData &&
        other.roomId == roomId &&
        other.shareUrl == shareUrl &&
        other.qrCodeData == qrCodeData;
  }

  @override
  int get hashCode => Object.hash(roomId, shareUrl, qrCodeData);
}

/// ルーム共有データ生成プロバイダー
final roomShareDataProvider = Provider.family<RoomShareData?, String>((ref, roomId) {
  if (roomId.isEmpty) return null;
  
  // 簡易的な共有URL生成（実際のアプリでは適切なディープリンクを使用）
  final shareUrl = 'https://app.example.com/room/$roomId';
  final qrCodeData = shareUrl;
  
  return RoomShareData(
    roomId: roomId,
    shareUrl: shareUrl,
    qrCodeData: qrCodeData,
  );
});