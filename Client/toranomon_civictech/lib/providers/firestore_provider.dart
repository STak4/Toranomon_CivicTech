import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firestore インスタンス
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Firestore サービス
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  // ドキュメントを取得
  Future<DocumentSnapshot> getDocument(
    String collection,
    String documentId,
  ) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }

  // ドキュメントを追加
  Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    return await _firestore.collection(collection).add(data);
  }

  // ドキュメントを設定（作成または更新）
  Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(documentId).set(data);
  }

  // ドキュメントを更新
  Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(documentId).update(data);
  }

  // ドキュメントを削除
  Future<void> deleteDocument(String collection, String documentId) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }

  // コレクションを取得
  Future<QuerySnapshot> getCollection(String collection) async {
    return await _firestore.collection(collection).get();
  }

  // クエリでコレクションを取得
  Future<QuerySnapshot> queryCollection({
    required String collection,
    String? field,
    Object? isEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object>? arrayContainsAny,
    List<Object>? whereIn,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    Query query = _firestore.collection(collection);

    if (field != null) {
      if (isEqualTo != null) {
        query = query.where(field, isEqualTo: isEqualTo);
      } else if (isLessThan != null) {
        query = query.where(field, isLessThan: isLessThan);
      } else if (isLessThanOrEqualTo != null) {
        query = query.where(field, isLessThanOrEqualTo: isLessThanOrEqualTo);
      } else if (isGreaterThan != null) {
        query = query.where(field, isGreaterThan: isGreaterThan);
      } else if (isGreaterThanOrEqualTo != null) {
        query = query.where(
          field,
          isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        );
      } else if (arrayContains != null) {
        query = query.where(field, arrayContains: arrayContains);
      } else if (arrayContainsAny != null) {
        query = query.where(field, arrayContainsAny: arrayContainsAny);
      } else if (whereIn != null) {
        query = query.where(field, whereIn: whereIn);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  // リアルタイムリスナーを設定
  Stream<DocumentSnapshot> documentStream(
    String collection,
    String documentId,
  ) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  // コレクションのリアルタイムリスナーを設定
  Stream<QuerySnapshot> collectionStream(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  // バッチ書き込み
  Future<void> batchWrite(List<BatchOperation> operations) async {
    final batch = _firestore.batch();

    for (final operation in operations) {
      final docRef = _firestore
          .collection(operation.collection)
          .doc(operation.documentId);

      switch (operation.type) {
        case BatchOperationType.set:
          batch.set(docRef, operation.data!);
          break;
        case BatchOperationType.update:
          batch.update(docRef, operation.data!);
          break;
        case BatchOperationType.delete:
          batch.delete(docRef);
          break;
      }
    }

    await batch.commit();
  }

  // トランザクション
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) updateFunction,
  ) async {
    return await _firestore.runTransaction(updateFunction);
  }
}

// バッチ操作の種類
enum BatchOperationType { set, update, delete }

// バッチ操作クラス
class BatchOperation {
  final BatchOperationType type;
  final String collection;
  final String documentId;
  final Map<String, dynamic>? data;

  BatchOperation.set({
    required this.collection,
    required this.documentId,
    required this.data,
  }) : type = BatchOperationType.set;

  BatchOperation.update({
    required this.collection,
    required this.documentId,
    required this.data,
  }) : type = BatchOperationType.update;

  BatchOperation.delete({required this.collection, required this.documentId})
    : type = BatchOperationType.delete,
      data = null;
}

// Firestore サービスプロバイダー
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.read(firestoreProvider));
});
