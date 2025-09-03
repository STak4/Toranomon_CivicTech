import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../utils/app_logger.dart';
import 'post_repository.dart';

/// 投稿リポジトリの実装クラス
/// 
/// Firestoreを使用した投稿データのCRUD操作と
/// Firebase Storageを使用した画像アップロード機能を提供
class PostRepositoryImpl implements PostRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const String _postsCollection = 'posts';
  static const String _roomsCollection = 'rooms';
  static const String _storagePostsPath = 'posts';

  PostRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<List<Post>> getPosts({
    LatLngBounds? bounds,
    String? roomId,
    int limit = 20,
    int offset = 0,
    PostOrderBy orderBy = PostOrderBy.createdAtDesc,
  }) async {
    try {
      AppLogger.i('投稿取得開始 - roomId: $roomId, bounds: $bounds');

      Query query = _firestore.collection(_postsCollection);

      // ルームIDでフィルタリング
      if (roomId != null && roomId.isNotEmpty) {
        query = query.where('roomId', isEqualTo: roomId);
      }

      // 地理的範囲でフィルタリング（インデックス作成まで一時的に無効化）
      // TODO: Firebase Console でインデックス作成後に有効化
      // if (bounds != null) {
      //   query = query
      //       .where('latitude', isGreaterThanOrEqualTo: bounds.southwest.latitude)
      //       .where('latitude', isLessThanOrEqualTo: bounds.northeast.latitude);
      // }

      // ソート順を適用（地理的フィルタリング無効時のみ）
      if (bounds == null) {
        query = _applyOrderBy(query, orderBy);
      }

      // ページネーション適用（FirestoreではstartAfterを使用）
      // offset機能は現在のFirestoreバージョンでは利用できないため、
      // 実際のアプリではstartAfterDocumentを使用してページネーションを実装
      // 現在は簡易実装としてlimitのみ使用
      query = query.limit(limit);

      final querySnapshot = await query.get();
      final posts = <Post>[];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          // 経度の範囲チェック（Firestoreの制限により後処理）
          if (bounds != null) {
            final longitude = data['longitude'] as double;
            if (longitude < bounds.southwest.longitude ||
                longitude > bounds.northeast.longitude) {
              continue;
            }
          }

          final post = Post.fromJson(data);
          posts.add(post);
        } catch (e, stackTrace) {
          AppLogger.e('投稿データの変換に失敗: ${doc.id}', e, stackTrace);
        }
      }

      AppLogger.i('投稿取得完了 - 件数: ${posts.length}');
      return posts;
    } catch (e, stackTrace) {
      AppLogger.e('投稿取得に失敗', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Post> createPost(CreatePostRequest request) async {
    try {
      AppLogger.i('投稿作成開始 - title: ${request.title}');

      // 画像をアップロード（存在する場合）
      String? imageUrl;
      if (request.imageFile != null) {
        try {
          imageUrl = await _uploadImage(request.imageFile!);
        } catch (e, stackTrace) {
          AppLogger.w('画像アップロードに失敗しましたが、投稿は続行します', e, stackTrace);
          // 画像アップロードに失敗しても投稿作成は続行
          imageUrl = null;
        }
      }

      // 投稿データを作成
      final postData = {
        'userId': 'current_user_id', // TODO: 認証システムから取得
        'title': request.title,
        'description': request.description,
        'imageUrl': imageUrl,
        'latitude': request.latitude,
        'longitude': request.longitude,
        'anchorId': request.anchorId,
        'roomId': request.roomId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        // Firestoreに保存を試行
        final docRef = await _firestore.collection(_postsCollection).add(postData);

        // 作成された投稿を取得
        final doc = await docRef.get();
        final data = doc.data()!;
        data['id'] = doc.id;
        
        // createdAtがServerTimestampの場合の処理
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        } else {
          data['createdAt'] = DateTime.now().toIso8601String();
        }

        final post = Post.fromJson(data);

        // ルームに投稿を追加
        try {
          await addPostToRoom(request.roomId, post.id);
        } catch (e, stackTrace) {
          AppLogger.w('ルームへの投稿追加に失敗しましたが、投稿作成は完了しました', e, stackTrace);
        }

        AppLogger.i('投稿作成完了 - id: ${post.id}');
        return post;
      } catch (firestoreError, stackTrace) {
        // Firestore データベースが存在しない場合の処理
        if (firestoreError.toString().contains('NOT_FOUND') || 
            firestoreError.toString().contains('database (default) does not exist')) {
          AppLogger.e('Firestore データベースが存在しません。Firebase Console で Firestore を有効化してください。', firestoreError, stackTrace);
          
          // 開発段階用：ローカルでモック投稿を作成
          final mockPost = Post(
            id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
            userId: 'current_user_id',
            title: request.title,
            description: request.description,
            imageUrl: imageUrl,
            latitude: request.latitude,
            longitude: request.longitude,
            anchorId: request.anchorId,
            roomId: request.roomId,
            createdAt: DateTime.now(),
          );
          
          AppLogger.w('モック投稿を作成しました（Firestore未設定のため）- id: ${mockPost.id}');
          return mockPost;
        } else {
          // その他のFirestoreエラーは再スロー
          rethrow;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e('投稿作成に失敗', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      AppLogger.i('投稿削除開始 - id: $postId');

      // 投稿データを取得
      final doc = await _firestore.collection(_postsCollection).doc(postId).get();
      if (!doc.exists) {
        throw Exception('投稿が見つかりません: $postId');
      }

      final data = doc.data()!;
      final imageUrl = data['imageUrl'] as String?;
      final roomId = data['roomId'] as String;

      // 画像を削除（存在する場合）
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _deleteImage(imageUrl);
      }

      // ルームから投稿を削除
      await removePostFromRoom(roomId, postId);

      // Firestoreから投稿を削除
      await _firestore.collection(_postsCollection).doc(postId).delete();

      AppLogger.i('投稿削除完了 - id: $postId');
    } catch (e, stackTrace) {
      AppLogger.e('投稿削除に失敗', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<Post>> getPostsStream({
    LatLngBounds? bounds,
    String? roomId,
  }) {
    try {
      AppLogger.i('投稿ストリーム開始 - roomId: $roomId, bounds: $bounds');

      Query query = _firestore.collection(_postsCollection);

      // ルームIDでフィルタリング
      if (roomId != null && roomId.isNotEmpty) {
        query = query.where('roomId', isEqualTo: roomId);
      }

      // 地理的範囲でフィルタリング（インデックス作成まで一時的に無効化）
      // TODO: Firebase Console でインデックス作成後に有効化
      // if (bounds != null) {
      //   query = query
      //       .where('latitude', isGreaterThanOrEqualTo: bounds.southwest.latitude)
      //       .where('latitude', isLessThanOrEqualTo: bounds.northeast.latitude);
      // }

      // 作成日時で降順ソート（地理的フィルタリング無効時のみ）
      if (bounds == null) {
        query = query.orderBy('createdAt', descending: true);
      }

      return query.snapshots().map((snapshot) {
        final posts = <Post>[];

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;

            // 経度の範囲チェック（後処理）
            if (bounds != null) {
              final longitude = data['longitude'] as double;
              if (longitude < bounds.southwest.longitude ||
                  longitude > bounds.northeast.longitude) {
                continue;
              }
            }

            // createdAtがServerTimestampの場合の処理
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
            }

            final post = Post.fromJson(data);
            posts.add(post);
          } catch (e, stackTrace) {
            AppLogger.e('投稿データの変換に失敗: ${doc.id}', e, stackTrace);
          }
        }

        return posts;
      });
    } catch (e, stackTrace) {
      AppLogger.e('投稿ストリーム開始に失敗', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> generateRoomId() async {
    try {
      AppLogger.i('ルームID生成開始');

      // ランダムな8文字の英数字を生成
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();
      String roomId;

      // 重複チェック付きでルームIDを生成
      do {
        roomId = List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
      } while (await _roomExists(roomId));

      // ルームドキュメントを作成
      await _firestore.collection(_roomsCollection).doc(roomId).set({
        'id': roomId,
        'createdBy': 'current_user_id', // TODO: 認証システムから取得
        'createdAt': FieldValue.serverTimestamp(),
        'postIds': <String>[],
      });

      AppLogger.i('ルームID生成完了 - id: $roomId');
      return roomId;
    } catch (e, stackTrace) {
      AppLogger.e('ルームID生成に失敗', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> validateRoomId(String roomId) async {
    try {
      AppLogger.i('ルームID検証開始 - id: $roomId');

      if (roomId.isEmpty || roomId.length != 8) {
        return false;
      }

      final exists = await _roomExists(roomId);
      AppLogger.i('ルームID検証完了 - id: $roomId, exists: $exists');
      return exists;
    } catch (e, stackTrace) {
      AppLogger.e('ルームID検証に失敗', e, stackTrace);
      return false;
    }
  }

  @override
  Future<List<Post>> getPostsInRoom(String roomId) async {
    try {
      AppLogger.i('ルーム内投稿取得開始 - roomId: $roomId');

      final query = _firestore
          .collection(_postsCollection)
          .where('roomId', isEqualTo: roomId)
          .orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();
      final posts = <Post>[];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;

          // createdAtがServerTimestampの場合の処理
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }

          final post = Post.fromJson(data);
          posts.add(post);
        } catch (e, stackTrace) {
          AppLogger.e('投稿データの変換に失敗: ${doc.id}', e, stackTrace);
        }
      }

      AppLogger.i('ルーム内投稿取得完了 - roomId: $roomId, 件数: ${posts.length}');
      return posts;
    } catch (e, stackTrace) {
      AppLogger.e('ルーム内投稿取得に失敗', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addPostToRoom(String roomId, String postId) async {
    try {
      AppLogger.i('ルームに投稿追加開始 - roomId: $roomId, postId: $postId');

      // ルームが存在するかチェック
      final roomDoc = await _firestore.collection(_roomsCollection).doc(roomId).get();
      
      if (!roomDoc.exists) {
        // ルームが存在しない場合は作成
        AppLogger.i('ルームが存在しないため作成します - roomId: $roomId');
        await _firestore.collection(_roomsCollection).doc(roomId).set({
          'id': roomId,
          'createdBy': 'system', // システムによる自動作成
          'createdAt': FieldValue.serverTimestamp(),
          'postIds': [postId],
        });
        AppLogger.i('ルーム作成完了 - roomId: $roomId');
      } else {
        // ルームが存在する場合は投稿IDを追加
        await _firestore.collection(_roomsCollection).doc(roomId).update({
          'postIds': FieldValue.arrayUnion([postId]),
        });
      }

      AppLogger.i('ルームに投稿追加完了 - roomId: $roomId, postId: $postId');
    } catch (e, stackTrace) {
      AppLogger.e('ルームに投稿追加に失敗', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removePostFromRoom(String roomId, String postId) async {
    try {
      AppLogger.i('ルームから投稿削除開始 - roomId: $roomId, postId: $postId');

      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'postIds': FieldValue.arrayRemove([postId]),
      });

      AppLogger.i('ルームから投稿削除完了 - roomId: $roomId, postId: $postId');
    } catch (e, stackTrace) {
      AppLogger.e('ルームから投稿削除に失敗', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Post?> getPostById(String postId) async {
    try {
      AppLogger.i('投稿詳細取得開始 - id: $postId');

      final doc = await _firestore.collection(_postsCollection).doc(postId).get();
      if (!doc.exists) {
        AppLogger.w('投稿が見つかりません - id: $postId');
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      // createdAtがServerTimestampの場合の処理
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }

      final post = Post.fromJson(data);
      AppLogger.i('投稿詳細取得完了 - id: $postId');
      return post;
    } catch (e, stackTrace) {
      AppLogger.e('投稿詳細取得に失敗', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Post> updatePost(Post post) async {
    try {
      AppLogger.i('投稿更新開始 - id: ${post.id}');

      final updateData = post.toJson();
      updateData.remove('id'); // IDは更新しない
      updateData.remove('createdAt'); // 作成日時は更新しない
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_postsCollection).doc(post.id).update(updateData);

      // 更新された投稿を取得
      final updatedPost = await getPostById(post.id);
      if (updatedPost == null) {
        throw Exception('更新された投稿の取得に失敗しました');
      }

      AppLogger.i('投稿更新完了 - id: ${post.id}');
      return updatedPost;
    } catch (e, stackTrace) {
      AppLogger.e('投稿更新に失敗', e, stackTrace);
      rethrow;
    }
  }

  /// Firebase Storage の設定状況をテスト
  Future<bool> testStorageConnection() async {
    try {
      AppLogger.i('Firebase Storage 接続テストを開始');
      
      // テスト用の小さなファイルを作成
      final testData = 'Firebase Storage connection test';
      final testRef = _storage.ref().child('test/connection_test.txt');
      
      // アップロードテスト
      await testRef.putString(testData);
      AppLogger.i('Firebase Storage アップロードテスト成功');
      
      // ダウンロードテスト
      final downloadUrl = await testRef.getDownloadURL();
      AppLogger.i('Firebase Storage ダウンロードテスト成功 - URL: $downloadUrl');
      
      // テストファイルを削除
      await testRef.delete();
      AppLogger.i('Firebase Storage 削除テスト成功');
      
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('Firebase Storage 接続テストに失敗', e, stackTrace);
      return false;
    }
  }

  /// 画像をFirebase Storageにアップロード
  /// 現在は開発段階のため使用していないが、将来的に有効化予定
  // ignore: unused_element
  Future<String> _uploadImage(XFile imageFile) async {
    try {
      AppLogger.i('画像アップロード開始 - path: ${imageFile.path}');

      final file = File(imageFile.path);
      
      // ファイルの存在確認
      if (!await file.exists()) {
        throw Exception('アップロード対象のファイルが存在しません: ${imageFile.path}');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final storageRef = _storage.ref().child('$_storagePostsPath/$fileName');

      AppLogger.i('Firebase Storage参照パス: $_storagePostsPath/$fileName');

      // メタデータを設定
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // ファイルをアップロード
      AppLogger.i('ファイルアップロード開始...');
      final uploadTask = storageRef.putFile(file, metadata);
      
      // アップロード進行状況を監視
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        AppLogger.d('アップロード進行状況: ${progress.toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.i('画像アップロード完了 - url: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.e('画像アップロードに失敗', e, stackTrace);
      
      // より詳細なエラー情報をログ出力
      if (e.toString().contains('object-not-found')) {
        AppLogger.e('Firebase Storage バケットまたはパスが見つかりません。Firebase Console でStorage設定を確認してください。');
      } else if (e.toString().contains('permission-denied')) {
        AppLogger.e('Firebase Storage への書き込み権限がありません。Security Rules を確認してください。');
      } else if (e.toString().contains('unauthenticated')) {
        AppLogger.e('Firebase 認証が必要です。ユーザーがログインしているか確認してください。');
      }
      
      rethrow;
    }
  }

  /// Firebase Storageから画像を削除
  Future<void> _deleteImage(String imageUrl) async {
    try {
      AppLogger.i('画像削除開始 - url: $imageUrl');

      // URLからストレージパスを抽出
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Firebase StorageのURLからファイルパスを取得
      if (pathSegments.length >= 4 && pathSegments[0] == 'v0' && pathSegments[1] == 'b') {
        final filePath = pathSegments.skip(4).join('/');
        final decodedPath = Uri.decodeComponent(filePath);
        
        final storageRef = _storage.ref().child(decodedPath);
        await storageRef.delete();
        
        AppLogger.i('画像削除完了 - path: $decodedPath');
      } else {
        AppLogger.w('無効な画像URL形式 - url: $imageUrl');
      }
    } catch (e, stackTrace) {
      AppLogger.e('画像削除に失敗', e, stackTrace);
      // 画像削除の失敗は投稿削除を阻害しないようにする
    }
  }

  /// ルームが存在するかチェック
  Future<bool> _roomExists(String roomId) async {
    final doc = await _firestore.collection(_roomsCollection).doc(roomId).get();
    return doc.exists;
  }

  /// ソート順をクエリに適用
  Query _applyOrderBy(Query query, PostOrderBy orderBy) {
    switch (orderBy) {
      case PostOrderBy.createdAtAsc:
        return query.orderBy('createdAt', descending: false);
      case PostOrderBy.createdAtDesc:
        return query.orderBy('createdAt', descending: true);
      case PostOrderBy.titleAsc:
        return query.orderBy('title', descending: false);
      case PostOrderBy.titleDesc:
        return query.orderBy('title', descending: true);
    }
  }

  @override
  Future<PostPaginationResult> getPostsPaginated({
    LatLngBounds? bounds,
    String? roomId,
    int limit = 20,
    int offset = 0,
    PostOrderBy orderBy = PostOrderBy.createdAtDesc,
  }) async {
    try {
      AppLogger.i('ページネーション投稿取得開始 - roomId: $roomId, limit: $limit, offset: $offset');

      Query query = _firestore.collection(_postsCollection);

      // ルームIDでフィルタリング
      if (roomId != null && roomId.isNotEmpty) {
        query = query.where('roomId', isEqualTo: roomId);
      }

      // 地理的範囲でフィルタリング（インデックス作成まで一時的に無効化）
      // TODO: Firebase Console でインデックス作成後に有効化
      // if (bounds != null) {
      //   query = query
      //       .where('latitude', isGreaterThanOrEqualTo: bounds.southwest.latitude)
      //       .where('latitude', isLessThanOrEqualTo: bounds.northeast.latitude);
      // }

      // 総数を取得するためのクエリ
      final countQuery = query;
      final countSnapshot = await countQuery.count().get();
      final totalCount = countSnapshot.count ?? 0;

      // ソート順を適用（地理的フィルタリング無効時のみ）
      if (bounds == null) {
        query = _applyOrderBy(query, orderBy);
      }

      // ページネーション適用（FirestoreではstartAfterを使用）
      // offset機能は現在のFirestoreバージョンでは利用できないため、
      // 実際のアプリではstartAfterDocumentを使用してページネーションを実装
      // 現在は簡易実装としてlimitのみ使用
      query = query.limit(limit);

      final querySnapshot = await query.get();
      final posts = <Post>[];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          // 経度の範囲チェック（Firestoreの制限により後処理）
          if (bounds != null) {
            final longitude = data['longitude'] as double;
            if (longitude < bounds.southwest.longitude ||
                longitude > bounds.northeast.longitude) {
              continue;
            }
          }

          final post = Post.fromJson(data);
          posts.add(post);
        } catch (e, stackTrace) {
          AppLogger.e('投稿データの変換に失敗: ${doc.id}', e, stackTrace);
        }
      }

      final hasMore = (offset + posts.length) < totalCount;

      final result = PostPaginationResult(
        posts: posts,
        hasMore: hasMore,
        totalCount: totalCount,
        currentOffset: offset,
        limit: limit,
      );

      AppLogger.i('ページネーション投稿取得完了 - 件数: ${posts.length}, hasMore: $hasMore, total: $totalCount');
      return result;
    } catch (e, stackTrace) {
      AppLogger.e('ページネーション投稿取得に失敗', e, stackTrace);
      rethrow;
    }
  }
}