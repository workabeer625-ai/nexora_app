import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

final class ChatThreadController extends ChangeNotifier {
  ChatThreadController({
    required ChatRepository chatRepository,
    required this.workspaceId,
    required this.isWorkspaceChat,
    this.projectId,
    this.taskId,
    this.pageSize = 20,
  }) : _chatRepository = chatRepository;

  final ChatRepository _chatRepository;
  final String workspaceId;
  final String? projectId;
  final String? taskId;
  final bool isWorkspaceChat;
  final int pageSize;

  final List<ChatMessage> _olderMessages = <ChatMessage>[];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  List<ChatMessage> mergeWithLive(List<ChatMessage> liveMessages) {
    final seenIds = <String>{};
    final merged = <ChatMessage>[
      ..._olderMessages,
      ...liveMessages,
    ].where((message) => seenIds.add(message.id)).toList(growable: false);

    merged.sort(_sortMessagesAscending);
    return merged;
  }

  Future<void> loadOlder(List<ChatMessage> liveMessages) async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    final merged = mergeWithLive(liveMessages);
    if (merged.isEmpty) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    final before = merged.first.createdAt;
    if (before == null) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final olderMessages = isWorkspaceChat
          ? await _chatRepository.fetchOlderWorkspaceMessages(
              workspaceId: workspaceId,
              before: before,
              limit: pageSize,
            )
          : await _chatRepository.fetchOlderTaskMessages(
              workspaceId: workspaceId,
              projectId: projectId!,
              taskId: taskId!,
              before: before,
              limit: pageSize,
            );

      final existingIds = merged.map((message) => message.id).toSet();
      final appended = olderMessages
          .where((message) => !existingIds.contains(message.id))
          .toList(growable: false);

      _olderMessages.insertAll(0, appended);
      _hasMore = olderMessages.length == pageSize;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  int _sortMessagesAscending(ChatMessage left, ChatMessage right) {
    final leftTime = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final rightTime = right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return leftTime.compareTo(rightTime);
  }
}
