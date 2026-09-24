import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

abstract interface class StorageService {
  FirebaseStorage get instance;

  Reference ref(String path);

  UploadTask uploadData({
    required String path,
    required Uint8List data,
    SettableMetadata? metadata,
  });

  Future<String> getDownloadUrl(String path);
}

final class FirebaseStorageService implements StorageService {
  FirebaseStorageService({FirebaseStorage? instance})
    : _instance = instance ?? FirebaseStorage.instance;

  final FirebaseStorage _instance;

  @override
  FirebaseStorage get instance => _instance;

  @override
  Reference ref(String path) => _instance.ref(path);

  @override
  UploadTask uploadData({
    required String path,
    required Uint8List data,
    SettableMetadata? metadata,
  }) {
    return ref(path).putData(data, metadata);
  }

  @override
  Future<String> getDownloadUrl(String path) {
    return ref(path).getDownloadURL();
  }
}
