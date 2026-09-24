import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class FirestoreService {
  FirebaseFirestore get instance;

  CollectionReference<Map<String, dynamic>> collection(String path);

  DocumentReference<Map<String, dynamic>> document(String path);

  WriteBatch batch();
}

final class FirebaseFirestoreService implements FirestoreService {
  FirebaseFirestoreService({FirebaseFirestore? instance})
    : _instance = instance ?? FirebaseFirestore.instance;

  final FirebaseFirestore _instance;

  @override
  FirebaseFirestore get instance => _instance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _instance.collection(path);
  }

  @override
  DocumentReference<Map<String, dynamic>> document(String path) {
    return _instance.doc(path);
  }

  @override
  WriteBatch batch() => _instance.batch();
}
