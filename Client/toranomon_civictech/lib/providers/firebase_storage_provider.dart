import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase Storage インスタンス
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// Storage サービス
class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  // ファイルをアップロード
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;

    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // バイトデータをアップロード
  Future<String> uploadBytes({
    required String path,
    required Uint8List data,
    String? contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;

    final uploadTask = ref.putData(data, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // ファイルをダウンロード
  Future<Uint8List?> downloadFile(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.getData();
  }

  // ダウンロードURLを取得
  Future<String> getDownloadURL(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.getDownloadURL();
  }

  // ファイルを削除
  Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }

  // フォルダ内のファイル一覧を取得
  Future<ListResult> listFiles(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.listAll();
  }

  // ファイルのメタデータを取得
  Future<FullMetadata> getMetadata(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.getMetadata();
  }

  // ファイルのメタデータを更新
  Future<FullMetadata> updateMetadata({
    required String path,
    required Map<String, String> customMetadata,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(customMetadata: customMetadata);
    return await ref.updateMetadata(metadata);
  }
}

// Storage サービスプロバイダー
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.read(firebaseStorageProvider));
});
