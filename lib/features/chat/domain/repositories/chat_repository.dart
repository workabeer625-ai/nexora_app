import '../entities/chat_message.dart';

abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchTaskMessages({
    required String workspaceId,
    required String projectId,
    required String taskId,
    int limit = 20,
  });

  Future<List<ChatMessage>> fetchOlderTaskMessages({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required DateTime before,
    int limit = 20,
  });

  Future<void> createTaskMessage({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required ChatMessage message,
  });

  Future<void> updateTaskMessage({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required String messageId,
    required String content,
    required List<String> mentions,
  });

  Future<void> softDeleteTaskMessage({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required String messageId,
  });

  Stream<List<ChatMessage>> watchWorkspaceMessages({
    required String workspaceId,
    int limit = 20,
  });

  Future<List<ChatMessage>> fetchOlderWorkspaceMessages({
    required String workspaceId,
    required DateTime before,
    int limit = 20,
  });

  Future<void> createWorkspaceMessage({
    required String workspaceId,
    required ChatMessage message,
  });

  Future<void> updateWorkspaceMessage({
    required String workspaceId,
    required String messageId,
    required String content,
    required List<String> mentions,
  });

  Future<void> softDeleteWorkspaceMessage({
    required String workspaceId,
    required String messageId,
  });
}
