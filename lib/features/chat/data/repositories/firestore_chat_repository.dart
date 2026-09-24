import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';

final class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> _taskMessages(
    String workspaceId,
    String projectId,
    String taskId,
  ) {
    return _firestoreService.collection(
      FirestorePaths.taskMessages(workspaceId, projectId, taskId),
    );
  }

  CollectionReference<Map<String, dynamic>> _workspaceMessages(
    String workspaceId,
  ) {
    return _firestoreService.collection(
      FirestorePaths.workspaceChatMessages(workspaceId),
    );
  }

  Query<Map<String, dynamic>> _pagedQuery(
    CollectionReference<Map<String, dynamic>> collection, {
    required int limit,
    DateTime? before,
  }) {
    Query<Map<String, dynamic>> query = collection.orderBy(
      'created_at',
      descending: true,
    );

    if (before != null) {
      query = query.where('created_at', isLessThan: Timestamp.fromDate(before));
    }

    return query.limit(limit);
  }

  @override
  Stream<List<ChatMessage>> watchTaskMessages({
    required String workspaceId,
    required String projectId,
    required String taskId,
    int limit = 20,
  }) {
    return _pagedQuery(
      _taskMessages(workspaceId, projectId, taskId),
      limit: limit,
    ).snapshots().map(_mapMessages);
  }

  @override
  Future<List<ChatMessage>> fetchOlderTaskMessages({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required DateTime before,
    int limit = 20,
  }) async {
    final snapshot = await _pagedQuery(
      _taskMessages(workspaceId, projectId, taskId),
      limit: limit,
      before: before,
    ).get();

    return _mapMessages(snapshot);
  }

  @override
  Future<void> createTaskMessage({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required ChatMessage message,
  }) async {
    final collection = _taskMessages(workspaceId, projectId, taskId);
    final doc = collection.doc();
    final model = ChatMessageModel.fromEntity(message.copyWith(id: doc.id));
    await doc.set(model.toCreateFirestore());
  }

  @override
  Future<void> updateTaskMessage({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required String messageId,
    required String content,
    required List<String> mentions,
  }) {
    return _taskMessages(workspaceId, projectId, taskId).doc(messageId).update({
      'content': content,
      'mentions': mentions,
      'updated_at': FieldValue.serverTimestamp(),
      'is_edited': true,
    });
  }

  @override
  Future<void> softDeleteTaskMessage({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required String messageId,
  }) {
    return _taskMessages(workspaceId, projectId, taskId).doc(messageId).update({
      'content': '',
      'mentions': const <String>[],
      'updated_at': FieldValue.serverTimestamp(),
      'is_deleted': true,
      'is_edited': false,
    });
  }

  @override
  Stream<List<ChatMessage>> watchWorkspaceMessages({
    required String workspaceId,
    int limit = 20,
  }) {
    return _pagedQuery(
      _workspaceMessages(workspaceId),
      limit: limit,
    ).snapshots().map(_mapMessages);
  }

  @override
  Future<List<ChatMessage>> fetchOlderWorkspaceMessages({
    required String workspaceId,
    required DateTime before,
    int limit = 20,
  }) async {
    final snapshot = await _pagedQuery(
      _workspaceMessages(workspaceId),
      limit: limit,
      before: before,
    ).get();

    return _mapMessages(snapshot);
  }

  @override
  Future<void> createWorkspaceMessage({
    required String workspaceId,
    required ChatMessage message,
  }) async {
    final collection = _workspaceMessages(workspaceId);
    final doc = collection.doc();
    final model = ChatMessageModel.fromEntity(message.copyWith(id: doc.id));
    await doc.set(model.toCreateFirestore());
  }

  @override
  Future<void> updateWorkspaceMessage({
    required String workspaceId,
    required String messageId,
    required String content,
    required List<String> mentions,
  }) {
    return _workspaceMessages(workspaceId).doc(messageId).update({
      'content': content,
      'mentions': mentions,
      'updated_at': FieldValue.serverTimestamp(),
      'is_edited': true,
    });
  }

  @override
  Future<void> softDeleteWorkspaceMessage({
    required String workspaceId,
    required String messageId,
  }) {
    return _workspaceMessages(workspaceId).doc(messageId).update({
      'content': '',
      'mentions': const <String>[],
      'updated_at': FieldValue.serverTimestamp(),
      'is_deleted': true,
      'is_edited': false,
    });
  }

  List<ChatMessage> _mapMessages(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(ChatMessageModel.fromSnapshot)
        .toList(growable: false);
  }
}
