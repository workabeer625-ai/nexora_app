import '../../../core/errors/app_exception.dart';
import '../../../core/validators/input_validators.dart';
import '../../notifications/domain/entities/app_notification.dart';
import '../../notifications/domain/repositories/notification_repository.dart';
import '../../tasks/domain/entities/task_item.dart';
import '../../users/domain/repositories/user_profile_repository.dart';
import '../../workspaces/domain/entities/workspace.dart';
import '../../workspaces/domain/repositories/workspace_repository.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/chat_repository.dart';

final class ChatService {
  ChatService({
    required ChatRepository chatRepository,
    required WorkspaceRepository workspaceRepository,
    required UserProfileRepository userProfileRepository,
    required NotificationRepository notificationRepository,
  }) : _chatRepository = chatRepository,
       _workspaceRepository = workspaceRepository,
       _userProfileRepository = userProfileRepository,
       _notificationRepository = notificationRepository;

  final ChatRepository _chatRepository;
  final WorkspaceRepository _workspaceRepository;
  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;

  Future<void> sendTaskMessage({
    required String workspaceId,
    required String projectId,
    required TaskItem task,
    required String senderId,
    required String content,
    List<String> mentions = const <String>[],
    String? replyToMessageId,
  }) async {
    final access = await _requireWorkspaceAccess(workspaceId, senderId);
    _ensureWorkspaceWritable(access.workspace);

    final senderName = await _resolveSenderName(senderId);
    final normalizedMentions = await _normalizeMentions(
      workspaceId: workspaceId,
      senderId: senderId,
      mentions: mentions,
    );

    await _chatRepository.createTaskMessage(
      workspaceId: workspaceId,
      projectId: projectId,
      taskId: task.id,
      message: ChatMessage(
        id: '',
        senderId: senderId,
        senderName: senderName,
        senderAvatar: null,
        content: _normalizeContent(content),
        type: ChatMessageType.text,
        isEdited: false,
        isDeleted: false,
        mentions: normalizedMentions,
        replyToMessageId: replyToMessageId?.trim().isEmpty == true
            ? null
            : replyToMessageId?.trim(),
      ),
    );

    await _notifyTaskMentions(
      senderName: senderName,
      task: task,
      mentions: normalizedMentions,
    );
    await _notifyTaskMessageTargets(
      senderId: senderId,
      senderName: senderName,
      task: task,
      excludedUserIds: normalizedMentions,
    );
  }

  Future<void> sendWorkspaceMessage({
    required String workspaceId,
    required String senderId,
    required String content,
    List<String> mentions = const <String>[],
    String? replyToMessageId,
  }) async {
    final access = await _requireWorkspaceAccess(workspaceId, senderId);
    _ensureWorkspaceWritable(access.workspace);

    final senderName = await _resolveSenderName(senderId);
    final normalizedMentions = await _normalizeMentions(
      workspaceId: workspaceId,
      senderId: senderId,
      mentions: mentions,
    );

    await _chatRepository.createWorkspaceMessage(
      workspaceId: workspaceId,
      message: ChatMessage(
        id: '',
        senderId: senderId,
        senderName: senderName,
        senderAvatar: null,
        content: _normalizeContent(content),
        type: ChatMessageType.text,
        isEdited: false,
        isDeleted: false,
        mentions: normalizedMentions,
        replyToMessageId: replyToMessageId?.trim().isEmpty == true
            ? null
            : replyToMessageId?.trim(),
      ),
    );

    await _notifyWorkspaceMentions(
      senderId: senderId,
      senderName: senderName,
      workspaceId: workspaceId,
      workspaceName: access.workspace.name,
      mentions: normalizedMentions,
    );
  }

  Future<void> updateTaskMessage({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required ChatMessage currentMessage,
    required String actorId,
    required String content,
    List<String> mentions = const <String>[],
  }) async {
    final access = await _requireWorkspaceAccess(workspaceId, actorId);
    _ensureWorkspaceWritable(access.workspace);

    if (currentMessage.senderId != actorId) {
      throw const PermissionDeniedException(
        'Only the original sender can edit this message.',
      );
    }

    await _chatRepository.updateTaskMessage(
      workspaceId: workspaceId,
      projectId: projectId,
      taskId: taskId,
      messageId: currentMessage.id,
      content: _normalizeContent(content),
      mentions: await _normalizeMentions(
        workspaceId: workspaceId,
        senderId: actorId,
        mentions: mentions,
      ),
    );
  }

  Future<void> updateWorkspaceMessage({
    required String workspaceId,
    required ChatMessage currentMessage,
    required String actorId,
    required String content,
    List<String> mentions = const <String>[],
  }) async {
    final access = await _requireWorkspaceAccess(workspaceId, actorId);
    _ensureWorkspaceWritable(access.workspace);

    if (currentMessage.senderId != actorId) {
      throw const PermissionDeniedException(
        'Only the original sender can edit this message.',
      );
    }

    await _chatRepository.updateWorkspaceMessage(
      workspaceId: workspaceId,
      messageId: currentMessage.id,
      content: _normalizeContent(content),
      mentions: await _normalizeMentions(
        workspaceId: workspaceId,
        senderId: actorId,
        mentions: mentions,
      ),
    );
  }

  Future<void> deleteTaskMessage({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required ChatMessage message,
    required String actorId,
  }) async {
    final access = await _requireWorkspaceAccess(workspaceId, actorId);
    _ensureWorkspaceWritable(access.workspace);
    _ensureDeleteAllowed(access.member, message, actorId);

    await _chatRepository.softDeleteTaskMessage(
      workspaceId: workspaceId,
      projectId: projectId,
      taskId: taskId,
      messageId: message.id,
    );
  }

  Future<void> deleteWorkspaceMessage({
    required String workspaceId,
    required ChatMessage message,
    required String actorId,
  }) async {
    final access = await _requireWorkspaceAccess(workspaceId, actorId);
    _ensureWorkspaceWritable(access.workspace);
    _ensureDeleteAllowed(access.member, message, actorId);

    await _chatRepository.softDeleteWorkspaceMessage(
      workspaceId: workspaceId,
      messageId: message.id,
    );
  }

  Future<_WorkspaceAccess> _requireWorkspaceAccess(
    String workspaceId,
    String actorId,
  ) async {
    final workspace = await _workspaceRepository.fetchWorkspace(workspaceId);
    if (workspace == null) {
      throw const NotFoundException('Workspace not found.');
    }

    final member = await _workspaceRepository.fetchMember(workspaceId, actorId);
    if (member == null || member.status != WorkspaceMemberStatus.active) {
      throw const PermissionDeniedException(
        'You do not have access to this workspace chat.',
      );
    }

    return _WorkspaceAccess(workspace: workspace, member: member);
  }

  void _ensureWorkspaceWritable(Workspace workspace) {
    if (workspace.isArchived) {
      throw const ValidationException('Archived workspaces are read-only.');
    }
  }

  void _ensureDeleteAllowed(
    WorkspaceMember member,
    ChatMessage message,
    String actorId,
  ) {
    final isAuthor = message.senderId == actorId;
    final canModerate =
        member.role == WorkspaceRole.owner ||
        member.role == WorkspaceRole.admin;

    if (!isAuthor && !canModerate) {
      throw const PermissionDeniedException(
        'You can only delete your own messages.',
      );
    }
  }

  String _normalizeContent(String content) {
    return InputValidators.validateRequiredText(
      content,
      fieldName: 'Message',
      minLength: 1,
      maxLength: 2000,
    );
  }

  Future<List<String>> _normalizeMentions({
    required String workspaceId,
    required String senderId,
    required List<String> mentions,
  }) async {
    final normalized = <String>[];

    for (final userId
        in mentions
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)) {
      if (userId == senderId || normalized.contains(userId)) {
        continue;
      }

      final isMember = await _workspaceRepository.isActiveMember(
        workspaceId,
        userId,
      );
      if (isMember) {
        normalized.add(userId);
      }
    }

    return normalized;
  }

  Future<String> _resolveSenderName(String senderId) async {
    final profile = await _userProfileRepository.fetchProfile(senderId);
    final displayName = profile?.displayName.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final email = profile?.email.trim() ?? '';
    if (email.isNotEmpty) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) {
        return localPart;
      }
    }

    return 'Nexora member';
  }

  Future<void> _notifyTaskMentions({
    required String senderName,
    required TaskItem task,
    required List<String> mentions,
  }) async {
    for (final userId in mentions) {
      await _notificationRepository.createNotification(
        AppNotification(
          id: '',
          userId: userId,
          type: NotificationType.chatMention,
          title: 'You were mentioned',
          titleAr: 'تم ذكرك',
          body: '$senderName mentioned you in ${task.title}.',
          bodyAr: '$senderName ذكرك في ${task.title}.',
          entityType: NotificationEntityType.task,
          entityId: task.id,
          isRead: false,
        ),
      );
    }
  }

  Future<void> _notifyWorkspaceMentions({
    required String senderId,
    required String senderName,
    required String workspaceId,
    required String workspaceName,
    required List<String> mentions,
  }) async {
    for (final userId in mentions) {
      if (userId == senderId) {
        continue;
      }

      await _notificationRepository.createNotification(
        AppNotification(
          id: '',
          userId: userId,
          type: NotificationType.chatMention,
          title: 'You were mentioned',
          titleAr: 'تم ذكرك',
          body: '$senderName mentioned you in $workspaceName chat.',
          bodyAr: '$senderName ذكرك في دردشة $workspaceName.',
          entityType: NotificationEntityType.workspace,
          entityId: workspaceId,
          isRead: false,
        ),
      );
    }
  }

  Future<void> _notifyTaskMessageTargets({
    required String senderId,
    required String senderName,
    required TaskItem task,
    required List<String> excludedUserIds,
  }) async {
    final targets =
        <String>{task.createdBy, if (task.assignedTo != null) task.assignedTo!}
          ..remove(senderId)
          ..removeAll(excludedUserIds);

    for (final userId in targets) {
      await _notificationRepository.createNotification(
        AppNotification(
          id: '',
          userId: userId,
          type: NotificationType.taskMessageAdded,
          title: 'New task message',
          titleAr: 'رسالة جديدة في المهمة',
          body: '$senderName sent a new message in ${task.title}.',
          bodyAr: '$senderName أرسل رسالة جديدة في ${task.title}.',
          entityType: NotificationEntityType.task,
          entityId: task.id,
          isRead: false,
        ),
      );
    }
  }
}

final class _WorkspaceAccess {
  const _WorkspaceAccess({required this.workspace, required this.member});

  final Workspace workspace;
  final WorkspaceMember member;
}
