import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/localization/app_domain_localizations.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../tasks/domain/entities/task_item.dart';
import '../../../workspaces/domain/entities/workspace.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_participant.dart';
import '../controllers/chat_composer_controller.dart';
import '../controllers/chat_thread_controller.dart';

class TaskChatPanel extends StatelessWidget {
  const TaskChatPanel({
    super.key,
    required this.currentUserId,
    required this.workspaceId,
    required this.projectId,
    required this.task,
    required this.canAccess,
    required this.canModerate,
    required this.isReadOnly,
  });

  final String currentUserId;
  final String workspaceId;
  final String projectId;
  final TaskItem task;
  final bool canAccess;
  final bool canModerate;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = width >= 980 ? 720.0 : 620.0;

    return SizedBox(
      height: height,
      child: _ChatPanel(
        currentUserId: currentUserId,
        workspaceId: workspaceId,
        projectId: projectId,
        task: task,
        canAccess: canAccess,
        canModerate: canModerate,
        isReadOnly: isReadOnly || task.isArchived,
        title: context.tr(en: 'Task chat', ar: 'محادثة المهمة'),
        subtitle: context.tr(
          en: 'Keep decisions, blockers, and delivery context attached to the task.',
          ar: 'اجعل القرارات والعوائق وسياق التنفيذ مرتبطًا بهذه المهمة مباشرة.',
        ),
        emptyTitle: context.tr(
          en: 'Start the discussion around this task',
          ar: 'ابدأ النقاش حول هذه المهمة',
        ),
        emptyMessage: context.tr(
          en: 'The first message should make the next decision or unblock step obvious.',
          ar: 'اجعل أول رسالة توضّح القرار التالي أو خطوة إزالة العائق.',
        ),
        helperText: context.tr(
          en: 'Use @ to mention a teammate.',
          ar: 'استخدم @ لذكر عضو.',
        ),
        showSenderNames: false,
        isWorkspaceChat: false,
      ),
    );
  }
}

class WorkspaceChatTab extends StatelessWidget {
  const WorkspaceChatTab({
    super.key,
    required this.currentUserId,
    required this.workspace,
    required this.canAccess,
    required this.canModerate,
  });

  final String currentUserId;
  final Workspace workspace;
  final bool canAccess;
  final bool canModerate;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    void openChatPage() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WorkspaceChatPage(
            currentUserId: currentUserId,
            workspace: workspace,
            canAccess: canAccess,
            canModerate: canModerate,
          ),
        ),
      );
    }

    return StreamBuilder<List<ChatMessage>>(
      stream: services.chatRepository.watchWorkspaceMessages(
        workspaceId: workspace.id,
        limit: 12,
      ),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <ChatMessage>[];
        final latestMessage = messages.isEmpty ? null : messages.first;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            AppSurfaceCard(
              glow: true,
              backgroundColor: AppColors.surfaceGlassStrong.withValues(
                alpha: 0.94,
              ),
              borderColor: AppColors.outlineStrong,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: canModerate
                                ? AppColors.adminHeroGradient
                                : AppColors.memberHeroGradient,
                          ),
                          borderRadius: AppRadii.large,
                          boxShadow: AppShadows.soft,
                        ),
                        child: const Icon(
                          Icons.forum_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(en: 'Team chat', ar: 'دردشة الفريق'),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppColors.inkMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              workspace.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              context.tr(
                                en: 'See the room details here, then open the full conversation when you want to chat like a dedicated messaging screen.',
                                ar: 'شاهد تفاصيل الغرفة هنا، ثم افتح المحادثة الكاملة عندما تريد التحدث في شاشة واضحة ومخصصة مثل تطبيقات الدردشة.',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppStatusBadge(
                        label: context.tr(
                          en: '${workspace.memberCount} members',
                          ar: '${workspace.memberCount} أعضاء',
                        ),
                        backgroundColor: AppColors.infoSoft,
                        foregroundColor: AppColors.info,
                      ),
                      AppStatusBadge(
                        label: context.tr(
                          en: '${messages.length} recent messages',
                          ar: '${messages.length} رسالة حديثة',
                        ),
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primaryStrong,
                      ),
                      AppStatusBadge(
                        label: workspace.isArchived
                            ? context.tr(en: 'Read-only', ar: 'للقراءة فقط')
                            : context.tr(en: 'Active room', ar: 'غرفة نشطة'),
                        backgroundColor: workspace.isArchived
                            ? AppColors.surfaceMuted
                            : AppColors.successSoft,
                        foregroundColor: workspace.isArchived
                            ? AppColors.inkMuted
                            : AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canAccess ? openChatPage : null,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        canAccess
                            ? context.tr(
                                en: 'Open full chat',
                                ar: 'فتح المحادثة الكاملة',
                              )
                            : context.tr(
                                en: 'Available after approval',
                                ar: 'تتفعل بعد الموافقة',
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (latestMessage != null)
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(en: 'Latest activity', ar: 'آخر نشاط'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: AppRadii.pill,
                          ),
                          child: Text(
                            buildChatParticipantInitials(
                              latestMessage.senderName,
                            ),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latestMessage.senderName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                AppDateFormatter.dateTime(
                                  latestMessage.createdAt,
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.inkMuted),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                latestMessage.isDeleted
                                    ? context.tr(
                                        en: 'This message was deleted.',
                                        ar: 'تم حذف هذه الرسالة.',
                                      )
                                    : latestMessage.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              AppHintCard(
                title: context.tr(
                  en: 'No messages yet',
                  ar: 'لا توجد رسائل بعد',
                ),
                message: context.tr(
                  en: 'The room is ready. Open the full chat and send the first update, question, or handoff.',
                  ar: 'الغرفة جاهزة. افتح المحادثة الكاملة وأرسل أول تحديث أو سؤال أو عملية تسليم.',
                ),
                accentColor: AppColors.info,
                backgroundColor: AppColors.infoSoft,
              ),
          ],
        );
      },
    );
  }
}

class WorkspaceChatPage extends StatelessWidget {
  const WorkspaceChatPage({
    super.key,
    required this.currentUserId,
    required this.workspace,
    required this.canAccess,
    required this.canModerate,
  });

  final String currentUserId;
  final Workspace workspace;
  final bool canAccess;
  final bool canModerate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(workspace.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              context.tr(
                en: '${workspace.memberCount} members',
                ar: '${workspace.memberCount} أعضاء',
              ),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.pageGradient,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: _ChatPanel(
              currentUserId: currentUserId,
              workspaceId: workspace.id,
              workspace: workspace,
              canAccess: canAccess,
              canModerate: canModerate,
              isReadOnly: workspace.isArchived,
              title: context.tr(en: 'Workspace chat', ar: 'دردشة الفريق'),
              subtitle: context.tr(
                en: 'A dedicated team conversation inside the workspace.',
                ar: 'محادثة فريق كاملة داخل مساحة العمل.',
              ),
              emptyTitle: context.tr(
                en: 'No team messages yet',
                ar: 'لا توجد رسائل للفريق بعد',
              ),
              emptyMessage: context.tr(
                en: 'Start with the first update, handoff, or question so everyone stays aligned.',
                ar: 'ابدأ بأول تحديث أو تسليم أو سؤال حتى يبقى الجميع على نفس المسار.',
              ),
              helperText: context.tr(
                en: 'Use @ to mention a teammate.',
                ar: 'استخدم @ لذكر عضو.',
              ),
              showSenderNames: true,
              isWorkspaceChat: true,
              showHeader: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatPanel extends StatefulWidget {
  const _ChatPanel({
    required this.currentUserId,
    required this.workspaceId,
    required this.canAccess,
    required this.canModerate,
    required this.isReadOnly,
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.helperText,
    required this.showSenderNames,
    required this.isWorkspaceChat,
    this.showHeader = true,
    this.projectId,
    this.task,
    this.workspace,
  });

  final String currentUserId;
  final String workspaceId;
  final String? projectId;
  final TaskItem? task;
  final Workspace? workspace;
  final bool canAccess;
  final bool canModerate;
  final bool isReadOnly;
  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptyMessage;
  final String helperText;
  final bool showSenderNames;
  final bool isWorkspaceChat;
  final bool showHeader;

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final ScrollController _scrollController = ScrollController();

  late final ChatComposerController _composerController;
  late ChatThreadController _threadController;
  bool _initialized = false;
  bool _pendingAutoScroll = true;
  int _lastMessageCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final services = AppScope.of(context);
    _composerController = ChatComposerController();
    _threadController = ChatThreadController(
      chatRepository: services.chatRepository,
      workspaceId: widget.workspaceId,
      projectId: widget.projectId,
      taskId: widget.task?.id,
      isWorkspaceChat: widget.isWorkspaceChat,
    );
    _initialized = true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _composerController.dispose();
    _threadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    if (!widget.canAccess) {
      return AppSurfaceCard(
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.surfaceGlassStrong.withValues(alpha: 0.92),
        borderColor: AppColors.outlineStrong,
        glow: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = _useCompactChatLayout(context, constraints);
            return Column(
              children: [
                if (widget.showHeader)
                  _ChatHeader(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    messageCount: 0,
                    helperText: widget.helperText,
                    isWorkspaceChat: widget.isWorkspaceChat,
                    isCompact: isCompact,
                  ),
                _ChatInfoBanner(
                  backgroundColor: AppColors.warningSoft,
                  foregroundColor: AppColors.warning,
                  message: context.tr(
                    en: 'Only active workspace members can view or send messages here.',
                    ar: 'فقط أعضاء مساحة العمل النشطون يمكنهم رؤية الرسائل أو إرسالها هنا.',
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _ChatEmptyState(
                      title: widget.emptyTitle,
                      message: widget.emptyMessage,
                      helperText: widget.helperText,
                      isWorkspaceChat: widget.isWorkspaceChat,
                      isCompact: isCompact,
                    ),
                  ),
                ),
                _ChatFooterNotice(
                  message: context.tr(
                    en: 'Access to chat becomes available after you join this workspace.',
                    ar: 'يتفعل الوصول إلى الدردشة بعد الانضمام إلى هذه المساحة.',
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return StreamBuilder<List<ChatParticipant>>(
      stream: services.chatParticipantService.watchWorkspaceParticipants(
        widget.workspaceId,
      ),
      builder: (context, participantsSnapshot) {
        final participants =
            participantsSnapshot.data ?? const <ChatParticipant>[];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _composerController.setParticipants(participants);
        });

        final messagesStream = widget.isWorkspaceChat
            ? services.chatRepository.watchWorkspaceMessages(
                workspaceId: widget.workspaceId,
              )
            : services.chatRepository.watchTaskMessages(
                workspaceId: widget.workspaceId,
                projectId: widget.projectId!,
                taskId: widget.task!.id,
              );

        return StreamBuilder<List<ChatMessage>>(
          stream: messagesStream,
          builder: (context, messagesSnapshot) {
            if (messagesSnapshot.connectionState == ConnectionState.waiting &&
                !messagesSnapshot.hasData) {
              return AppSurfaceCard(
                child: AppLoadingState(
                  message: context.tr(
                    en: 'Loading chat...',
                    ar: 'يتم تحميل المحادثة...',
                  ),
                ),
              );
            }

            if (messagesSnapshot.hasError) {
              return AppSurfaceCard(
                child: AppErrorState(
                  message: messagesSnapshot.error.toString(),
                ),
              );
            }

            final liveMessages = messagesSnapshot.data ?? const <ChatMessage>[];
            final mergedMessages = _threadController.mergeWithLive(
              liveMessages,
            );
            _handleMessageCountChange(mergedMessages.length);

            return AnimatedBuilder(
              animation: Listenable.merge([
                _composerController,
                _threadController,
              ]),
              builder: (context, _) {
                final messages = _threadController.mergeWithLive(liveMessages);

                return AppSurfaceCard(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.surfaceGlassStrong.withValues(
                    alpha: 0.92,
                  ),
                  borderColor: AppColors.outlineStrong,
                  glow: true,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = _useCompactChatLayout(
                        context,
                        constraints,
                      );
                      return Column(
                        children: [
                          if (widget.showHeader)
                            _ChatHeader(
                              title: widget.title,
                              subtitle: widget.subtitle,
                              messageCount: messages.length,
                              helperText: widget.helperText,
                              isWorkspaceChat: widget.isWorkspaceChat,
                              isCompact: isCompact,
                            ),
                          if (!widget.canAccess)
                            _ChatInfoBanner(
                              backgroundColor: AppColors.warningSoft,
                              foregroundColor: AppColors.warning,
                              message: context.tr(
                                en: 'Only active workspace members can view or send messages here.',
                                ar: 'فقط أعضاء مساحة العمل النشطون يمكنهم رؤية الرسائل أو إرسالها هنا.',
                              ),
                            )
                          else if (widget.isReadOnly)
                            _ChatInfoBanner(
                              backgroundColor: AppColors.surfaceMuted,
                              foregroundColor: AppColors.inkMuted,
                              message: context.tr(
                                en: 'Workspace is archived. Chat is read-only.',
                                ar: 'مساحة العمل مؤرشفة. الشات للقراءة فقط.',
                              ),
                            ),
                          Expanded(
                            child: messages.isEmpty
                                ? Center(
                                    child: _ChatEmptyState(
                                      title: widget.emptyTitle,
                                      message: widget.emptyMessage,
                                      helperText: widget.helperText,
                                      isWorkspaceChat: widget.isWorkspaceChat,
                                      isCompact: isCompact,
                                    ),
                                  )
                                : _ChatMessageList(
                                    messages: messages,
                                    currentUserId: widget.currentUserId,
                                    canModerate: widget.canModerate,
                                    showSenderNames: widget.showSenderNames,
                                    isReadOnly: widget.isReadOnly,
                                    scrollController: _scrollController,
                                    isLoadingMore:
                                        _threadController.isLoadingMore,
                                    hasMore: _threadController.hasMore,
                                    onLoadMore: () => _threadController
                                        .loadOlder(liveMessages),
                                    onMessageLongPress: (message) =>
                                        _showMessageActions(
                                          context,
                                          message: message,
                                          participants: participants,
                                        ),
                                  ),
                          ),
                          if (widget.isReadOnly)
                            _ChatFooterNotice(
                              message: context.tr(
                                en: 'Archived workspaces keep chat visible for reference only.',
                                ar: 'في المساحات المؤرشفة تبقى المحادثة للقراءة فقط.',
                              ),
                            )
                          else
                            _ChatComposer(
                              controller: _composerController,
                              helperText: widget.helperText,
                              isWorkspaceChat: widget.isWorkspaceChat,
                              isEnabled: widget.canAccess && !widget.isReadOnly,
                              isCompact: isCompact,
                              onSend: () => _submitMessage(context),
                              onCancelEdit: () {
                                _composerController.cancelEditing(
                                  clearText: true,
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _submitMessage(BuildContext context) async {
    if (!_composerController.canSubmit) {
      return;
    }

    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final editingMessage = _composerController.editingMessage;
    final content = _composerController.textController.text.trim();
    final mentions = _composerController.resolveMentionIds();

    _composerController.markSending(true);
    try {
      if (editingMessage != null) {
        if (widget.isWorkspaceChat) {
          await services.chatService.updateWorkspaceMessage(
            workspaceId: widget.workspaceId,
            currentMessage: editingMessage,
            actorId: widget.currentUserId,
            content: content,
            mentions: mentions,
          );
        } else {
          await services.chatService.updateTaskMessage(
            workspaceId: widget.workspaceId,
            projectId: widget.projectId!,
            taskId: widget.task!.id,
            currentMessage: editingMessage,
            actorId: widget.currentUserId,
            content: content,
            mentions: mentions,
          );
        }
      } else if (widget.isWorkspaceChat) {
        await services.chatService.sendWorkspaceMessage(
          workspaceId: widget.workspaceId,
          senderId: widget.currentUserId,
          content: content,
          mentions: mentions,
        );
      } else {
        await services.chatService.sendTaskMessage(
          workspaceId: widget.workspaceId,
          projectId: widget.projectId!,
          task: widget.task!,
          senderId: widget.currentUserId,
          content: content,
          mentions: mentions,
        );
      }

      _pendingAutoScroll = true;
      _composerController.clearComposer();
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      _composerController.markSending(false);
    }
  }

  Future<void> _showMessageActions(
    BuildContext context, {
    required ChatMessage message,
    required List<ChatParticipant> participants,
  }) async {
    if (message.isDeleted || widget.isReadOnly || !widget.canAccess) {
      return;
    }

    final isAuthor = message.senderId == widget.currentUserId;
    final canDelete = isAuthor || widget.canModerate;
    final canEdit = isAuthor;
    if (!canDelete && !canEdit) {
      return;
    }

    final selection = await showModalBottomSheet<_MessageAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppSurfaceCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canEdit)
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(
                        context.tr(en: 'Edit message', ar: 'تعديل الرسالة'),
                      ),
                      onTap: () =>
                          Navigator.of(context).pop(_MessageAction.edit),
                    ),
                  if (canDelete)
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                      title: Text(
                        context.tr(en: 'Delete message', ar: 'حذف الرسالة'),
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: () =>
                          Navigator.of(context).pop(_MessageAction.delete),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!context.mounted || selection == null) {
      return;
    }

    if (selection == _MessageAction.edit) {
      _composerController.setParticipants(participants);
      _composerController.startEditing(message);
      _pendingAutoScroll = true;
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr(en: 'Delete message?', ar: 'حذف الرسالة؟')),
          content: Text(
            context.tr(
              en: 'This keeps the message in the thread but replaces it with a deleted state.',
              ar: 'سيبقى مكان الرسالة داخل المحادثة لكن ستظهر بحالة محذوفة.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr(en: 'Cancel', ar: 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(context.tr(en: 'Delete', ar: 'حذف')),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (widget.isWorkspaceChat) {
        await services.chatService.deleteWorkspaceMessage(
          workspaceId: widget.workspaceId,
          message: message,
          actorId: widget.currentUserId,
        );
      } else {
        await services.chatService.deleteTaskMessage(
          workspaceId: widget.workspaceId,
          projectId: widget.projectId!,
          taskId: widget.task!.id,
          message: message,
          actorId: widget.currentUserId,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _handleMessageCountChange(int count) {
    if (count == _lastMessageCount) {
      return;
    }

    final shouldScroll = _pendingAutoScroll || _isNearBottom();
    _lastMessageCount = count;
    if (!shouldScroll) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToBottom(animated: true);
      _pendingAutoScroll = false;
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }

    final distance =
        _scrollController.position.maxScrollExtent - _scrollController.offset;
    return distance < 140;
  }

  bool _useCompactChatLayout(BuildContext context, BoxConstraints constraints) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return viewInsets > 0 ||
        constraints.maxHeight < 620 ||
        MediaQuery.sizeOf(context).height < 740;
  }

  void _scrollToBottom({required bool animated}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final offset = _scrollController.position.maxScrollExtent;
    if (!animated) {
      _scrollController.jumpTo(offset);
      return;
    }

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.subtitle,
    required this.messageCount,
    required this.helperText,
    required this.isWorkspaceChat,
    this.isCompact = false,
  });

  final String title;
  final String subtitle;
  final int messageCount;
  final String helperText;
  final bool isWorkspaceChat;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isWorkspaceChat
                        ? AppColors.adminHeroGradient
                        : AppColors.memberHeroGradient,
                  ),
                  borderRadius: AppRadii.medium,
                  boxShadow: AppShadows.soft,
                ),
                child: const Icon(Icons.forum_outlined, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: isCompact ? 2 : null,
                      overflow: isCompact ? TextOverflow.ellipsis : null,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadii.pill,
                  border: Border.all(color: AppColors.outline),
                ),
                child: Text(
                  '$messageCount',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isCompact)
            AppStatusBadge(
              label: helperText,
              backgroundColor: AppColors.infoSoft,
              foregroundColor: AppColors.info,
              maxWidth: 220,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppStatusBadge(
                  label: isWorkspaceChat
                      ? context.tr(
                          en: 'Team alignment lives here',
                          ar: 'تنسيق الفريق هنا',
                        )
                      : context.tr(
                          en: 'Discuss the task here',
                          ar: 'ناقش المهمة هنا',
                        ),
                  backgroundColor: isWorkspaceChat
                      ? AppColors.adminSoft
                      : AppColors.memberSoft,
                  foregroundColor: isWorkspaceChat
                      ? AppColors.admin
                      : AppColors.member,
                  maxWidth: 180,
                ),
                AppStatusBadge(
                  label: helperText,
                  backgroundColor: AppColors.infoSoft,
                  foregroundColor: AppColors.info,
                  maxWidth: 220,
                ),
                AppStatusBadge(
                  label: context.tr(
                    en: 'Keep clarifications in context',
                    ar: 'أبقِ التوضيحات داخل السياق',
                  ),
                  backgroundColor: AppColors.surfaceMuted,
                  foregroundColor: AppColors.ink,
                  maxWidth: 210,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChatInfoBanner extends StatelessWidget {
  const _ChatInfoBanner({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.message,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadii.medium,
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ChatFooterNotice extends StatelessWidget {
  const _ChatFooterNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({
    required this.title,
    required this.message,
    required this.helperText,
    required this.isWorkspaceChat,
    this.isCompact = false,
  });

  final String title;
  final String message;
  final String helperText;
  final bool isWorkspaceChat;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final accentColor = isWorkspaceChat ? AppColors.admin : AppColors.member;
    final accentSoft = isWorkspaceChat
        ? AppColors.adminSoft
        : AppColors.memberSoft;

    return Padding(
      padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 56 : 68,
            height: isCompact ? 56 : 68,
            decoration: BoxDecoration(
              color: accentSoft,
              borderRadius: AppRadii.large,
            ),
            child: Icon(
              isWorkspaceChat
                  ? Icons.forum_outlined
                  : Icons.chat_bubble_outline_rounded,
              color: accentColor,
              size: isCompact ? 26 : 30,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: isCompact ? 2 : null,
            overflow: isCompact ? TextOverflow.ellipsis : null,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: isCompact ? 3 : null,
            overflow: isCompact ? TextOverflow.ellipsis : null,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isCompact)
            AppStatusBadge(
              label: helperText,
              backgroundColor: AppColors.infoSoft,
              foregroundColor: AppColors.info,
              maxWidth: 220,
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppStatusBadge(
                  label: helperText,
                  backgroundColor: AppColors.infoSoft,
                  foregroundColor: AppColors.info,
                  maxWidth: 220,
                ),
                AppStatusBadge(
                  label: isWorkspaceChat
                      ? context.tr(
                          en: 'Start team alignment here',
                          ar: 'ابدأ تنسيق الفريق هنا',
                        )
                      : context.tr(
                          en: 'Keep the task context visible',
                          ar: 'أبقِ سياق المهمة ظاهرًا',
                        ),
                  backgroundColor: AppColors.surfaceMuted,
                  foregroundColor: AppColors.ink,
                  maxWidth: 220,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChatMessageList extends StatelessWidget {
  const _ChatMessageList({
    required this.messages,
    required this.currentUserId,
    required this.canModerate,
    required this.showSenderNames,
    required this.isReadOnly,
    required this.scrollController,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onMessageLongPress,
  });

  final List<ChatMessage> messages;
  final String currentUserId;
  final bool canModerate;
  final bool showSenderNames;
  final bool isReadOnly;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final ValueChanged<ChatMessage> onMessageLongPress;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          if (isLoadingMore) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.tr(
                      en: 'Loading earlier messages...',
                      ar: 'يتم تحميل الرسائل الأقدم...',
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            );
          }

          if (hasMore) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Center(
                child: FilledButton.tonalIcon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_less_rounded),
                  label: Text(
                    context.tr(
                      en: 'Load earlier messages',
                      ar: 'تحميل الرسائل الأقدم',
                    ),
                  ),
                ),
              ),
            );
          }

          return const SizedBox(height: AppSpacing.xs);
        }

        final message = messages[index - 1];
        final previousMessage = index > 1 ? messages[index - 2] : null;

        return _ChatMessageTile(
          message: message,
          previousMessage: previousMessage,
          currentUserId: currentUserId,
          canModerate: canModerate,
          showSenderNames: showSenderNames,
          isReadOnly: isReadOnly,
          onLongPress: () => onMessageLongPress(message),
        );
      },
    );
  }
}

class _ChatMessageTile extends StatelessWidget {
  const _ChatMessageTile({
    required this.message,
    required this.previousMessage,
    required this.currentUserId,
    required this.canModerate,
    required this.showSenderNames,
    required this.isReadOnly,
    required this.onLongPress,
  });

  final ChatMessage message;
  final ChatMessage? previousMessage;
  final String currentUserId;
  final bool canModerate;
  final bool showSenderNames;
  final bool isReadOnly;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isOwn = message.senderId == currentUserId;
    final groupedWithPrevious = _isGroupedWithPrevious(
      previousMessage,
      message,
    );
    final canOpenActions =
        !isReadOnly && !message.isDeleted && (isOwn || canModerate);

    final bubbleBackground = message.isDeleted
        ? AppColors.surfaceMuted
        : isOwn
        ? AppColors.primaryStrong
        : AppColors.surface;
    final bubbleBorderColor = message.isDeleted
        ? AppColors.outline
        : isOwn
        ? AppColors.primaryStrong.withValues(alpha: 0.42)
        : AppColors.outlineStrong;
    final bubbleTextColor = message.isDeleted
        ? AppColors.inkMuted
        : isOwn
        ? Colors.white
        : AppColors.ink;
    final senderMetaColor = isOwn
        ? Colors.white.withValues(alpha: 0.86)
        : AppColors.inkMuted;
    final timestampLabel = _formatTime(context, message.createdAt);
    final sentLabel = context.tr(en: 'Sent', ar: 'أرسلت');
    final editedLabel = context.tr(en: 'Edited', ar: 'تم التعديل');
    final deletedLabel = context.tr(en: 'Deleted', ar: 'محذوفة');

    return Padding(
      padding: EdgeInsets.only(
        top: groupedWithPrevious ? AppSpacing.xs : AppSpacing.lg,
      ),
      child: GestureDetector(
        onLongPress: canOpenActions ? onLongPress : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isOwn
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isOwn) ...[
              _AvatarBadge(
                initials: buildChatParticipantInitials(message.senderName),
                visible: !groupedWithPrevious,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isOwn
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isOwn && !groupedWithPrevious && showSenderNames)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.sm,
                        left: AppSpacing.xs,
                        right: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              message.senderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            timestampLabel,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.inkMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: bubbleBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(24),
                        topRight: const Radius.circular(24),
                        bottomLeft: Radius.circular(isOwn ? 24 : 8),
                        bottomRight: Radius.circular(isOwn ? 8 : 24),
                      ),
                      border: Border.all(color: bubbleBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isOwn
                                      ? AppColors.primaryStrong
                                      : AppColors.navShadow)
                                  .withValues(alpha: isOwn ? 0.16 : 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.isDeleted)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.block_outlined,
                                    size: 16,
                                    color: senderMetaColor,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      context.tr(
                                        en: 'Message deleted',
                                        ar: 'تم حذف الرسالة',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: senderMetaColor,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              RichText(
                                text: _messageTextSpan(
                                  context,
                                  message.content,
                                  bubbleTextColor: bubbleTextColor,
                                  isOwn: isOwn,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: isOwn
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  _MessageMetaChip(
                                    label:
                                        groupedWithPrevious && !showSenderNames
                                        ? timestampLabel
                                        : '$sentLabel · $timestampLabel',
                                    foregroundColor: senderMetaColor,
                                    backgroundColor: isOwn
                                        ? Colors.white.withValues(alpha: 0.14)
                                        : AppColors.surfaceMuted,
                                  ),
                                  if (message.isEdited && !message.isDeleted)
                                    _MessageMetaChip(
                                      label: editedLabel,
                                      foregroundColor: senderMetaColor,
                                      backgroundColor: isOwn
                                          ? Colors.white.withValues(alpha: 0.14)
                                          : AppColors.infoSoft,
                                    ),
                                  if (message.isDeleted)
                                    _MessageMetaChip(
                                      label: deletedLabel,
                                      foregroundColor: senderMetaColor,
                                      backgroundColor: isOwn
                                          ? Colors.white.withValues(alpha: 0.14)
                                          : AppColors.surfaceMuted,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isGroupedWithPrevious(ChatMessage? previous, ChatMessage current) {
    if (previous == null) {
      return false;
    }
    if (previous.senderId != current.senderId) {
      return false;
    }

    final previousTime = previous.createdAt;
    final currentTime = current.createdAt;
    if (previousTime == null || currentTime == null) {
      return false;
    }

    return currentTime.difference(previousTime).inMinutes <= 6;
  }

  InlineSpan _messageTextSpan(
    BuildContext context,
    String content, {
    required Color bubbleTextColor,
    required bool isOwn,
  }) {
    final baseStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: bubbleTextColor,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(
          color: bubbleTextColor,
          height: 1.45,
          fontWeight: FontWeight.w500,
        );
    final mentionTextColor = isOwn ? Colors.white : AppColors.primaryStrong;
    final mentionBackground = isOwn
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.primarySoft;
    final mentionBorder = isOwn
        ? Colors.white.withValues(alpha: 0.24)
        : AppColors.primaryStrong.withValues(alpha: 0.16);

    final matches = RegExp(r'@\S+').allMatches(content).toList(growable: false);
    if (matches.isEmpty) {
      return TextSpan(text: content, style: baseStyle);
    }

    final children = <InlineSpan>[];
    var currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        children.add(
          TextSpan(
            text: content.substring(currentIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: mentionBackground,
              borderRadius: AppRadii.pill,
              border: Border.all(color: mentionBorder),
            ),
            child: Text(
              content.substring(match.start, match.end),
              style: baseStyle.copyWith(
                color: mentionTextColor,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ),
      );
      currentIndex = match.end;
    }

    if (currentIndex < content.length) {
      children.add(
        TextSpan(text: content.substring(currentIndex), style: baseStyle),
      );
    }

    return TextSpan(children: children, style: baseStyle);
  }

  String _formatTime(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) {
      return context.tr(en: 'Now', ar: 'الآن');
    }

    final local = dateTime.toLocal();
    final now = DateTime.now();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final isSameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isSameDay) {
      return '$hour:$minute';
    }

    return '${AppDateFormatter.shortDate(local)} $hour:$minute';
  }
}

class _MessageMetaChip extends StatelessWidget {
  const _MessageMetaChip({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.pill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.initials, required this.visible});

  final String initials;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visible ? 1 : 0,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadii.pill,
          border: Border.all(color: AppColors.outline),
        ),
        child: Text(
          initials,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.helperText,
    required this.isWorkspaceChat,
    required this.isEnabled,
    this.isCompact = false,
    required this.onSend,
    required this.onCancelEdit,
  });

  final ChatComposerController controller;
  final String helperText;
  final bool isWorkspaceChat;
  final bool isEnabled;
  final bool isCompact;
  final VoidCallback onSend;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.isEditing;
    final accentColor = isWorkspaceChat ? AppColors.admin : AppColors.member;
    final accentSoft = isWorkspaceChat
        ? AppColors.adminSoft
        : AppColors.memberSoft;
    final showCueChips =
        isEnabled &&
        !isCompact &&
        !controller.focusNode.hasFocus &&
        controller.mentionSuggestions.isEmpty;
    final placeholder = isEditing
        ? context.tr(en: 'Refine the message...', ar: 'حدّث الرسالة...')
        : isWorkspaceChat
        ? context.tr(
            en: 'Share an update, handoff, or quick question...',
            ar: 'شارك تحديثًا أو عملية تسليم أو سؤالًا سريعًا...',
          )
        : context.tr(
            en: 'Discuss the task, blocker, or decision...',
            ar: 'ناقش المهمة أو العائق أو القرار...',
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: AppRadii.medium,
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.tr(en: 'Editing message', ar: 'تعديل الرسالة'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onCancelEdit,
                    child: Text(context.tr(en: 'Cancel', ar: 'إلغاء')),
                  ),
                ],
              ),
            ),
          if (showCueChips)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ComposerCueChip(
                    label: isWorkspaceChat
                        ? context.tr(
                            en: 'Keep team alignment here',
                            ar: 'حافظ على تنسيق الفريق هنا',
                          )
                        : context.tr(
                            en: 'Discuss the task here',
                            ar: 'ناقش المهمة هنا',
                          ),
                    foregroundColor: accentColor,
                    backgroundColor: accentSoft,
                  ),
                  _ComposerCueChip(
                    label: helperText,
                    foregroundColor: AppColors.info,
                    backgroundColor: AppColors.infoSoft,
                  ),
                  if (!isWorkspaceChat)
                    _ComposerCueChip(
                      label: context.tr(
                        en: 'Keep clarifications inside the task',
                        ar: 'حافظ على التوضيحات داخل المهمة',
                      ),
                      foregroundColor: AppColors.ink,
                      backgroundColor: AppColors.surfaceMuted,
                    ),
                ],
              ),
            ),
          if (controller.mentionSuggestions.isNotEmpty && isEnabled)
            _MentionSuggestionsCard(
              suggestions: controller.mentionSuggestions,
              onSelect: controller.selectMention,
              maxHeight: isCompact ? 140 : 220,
            ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted.withValues(alpha: 0.9),
              borderRadius: AppRadii.large,
              border: Border.all(color: AppColors.outlineStrong),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    focusNode: controller.focusNode,
                    minLines: 1,
                    maxLines: 5,
                    enabled: isEnabled && !controller.isSending,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      hintText: placeholder,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: controller.isSending
                      ? const SizedBox(
                          width: 42,
                          height: 42,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        )
                      : IconButton.filled(
                          onPressed: isEnabled && controller.canSubmit
                              ? onSend
                              : null,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryStrong,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(48, 48),
                          ),
                          icon: Icon(
                            isEditing
                                ? Icons.check_rounded
                                : Icons.send_rounded,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerCueChip extends StatelessWidget {
  const _ComposerCueChip({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.pill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MentionSuggestionsCard extends StatelessWidget {
  const _MentionSuggestionsCard({
    required this.suggestions,
    required this.onSelect,
    this.maxHeight = 220,
  });

  final List<ChatParticipant> suggestions;
  final ValueChanged<ChatParticipant> onSelect;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxHeight = suggestions.length > 3
        ? maxHeight
        : 72.0 * suggestions.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: AppRadii.large,
        border: Border.all(color: AppColors.outlineStrong),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Text(
              context.tr(en: 'Mention a teammate', ar: 'اذكر أحد أعضاء الفريق'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: resolvedMaxHeight.clamp(72.0, maxHeight),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final participant = suggestions[index];
                return InkWell(
                  borderRadius: AppRadii.medium,
                  onTap: () => onSelect(participant),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: AppRadii.pill,
                          ),
                          child: Text(
                            participant.initials,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                participant.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${participant.mentionToken} · ${participant.role.localizedLabel(context)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.inkMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.north_west_rounded,
                          size: 18,
                          color: AppColors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _MessageAction { edit, delete }
