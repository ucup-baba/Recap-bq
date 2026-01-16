import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase Storage Data Source
/// Handles file uploads and downloads
class StorageDataSource {
  final FirebaseStorage _storage;

  StorageDataSource({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Upload file to storage
  /// Returns download URL
  Future<String> uploadFile({
    required String path,
    required dynamic file, // File for mobile, Uint8List for web
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    final ref = _storage.ref(path);

    UploadTask uploadTask;
    if (kIsWeb && file is Uint8List) {
      // Web: upload bytes
      final settableMetadata = SettableMetadata(
        contentType: contentType,
        customMetadata: metadata,
      );
      uploadTask = ref.putData(file, settableMetadata);
    } else if (file is File) {
      // Mobile: upload file
      final settableMetadata = SettableMetadata(
        contentType: contentType,
        customMetadata: metadata,
      );
      uploadTask = ref.putFile(file, settableMetadata);
    } else if (file is Uint8List) {
      // Fallback: upload bytes
      final settableMetadata = SettableMetadata(
        contentType: contentType,
        customMetadata: metadata,
      );
      uploadTask = ref.putData(file, settableMetadata);
    } else {
      throw ArgumentError('Unsupported file type: ${file.runtimeType}');
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete file from storage
  Future<void> deleteFile(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }

  /// Get download URL for a path
  Future<String> getDownloadUrl(String path) async {
    final ref = _storage.ref(path);
    return await ref.getDownloadURL();
  }

  /// Check if file exists
  Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref(path);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file metadata
  Future<FullMetadata?> getMetadata(String path) async {
    try {
      final ref = _storage.ref(path);
      return await ref.getMetadata();
    } catch (e) {
      return null;
    }
  }
}
