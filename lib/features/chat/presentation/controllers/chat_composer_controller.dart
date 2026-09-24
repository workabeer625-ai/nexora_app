import 'package:flutter/widgets.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_participant.dart';

final class ChatComposerController extends ChangeNotifier {
  ChatComposerController() {
    textController.addListener(_handleTextChanged);
  }

  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final Map<String, String> _selectedMentionTokens = <String, String>{};

  List<ChatParticipant> _participants = const <ChatParticipant>[];
  ChatMessage? _editingMessage;
  bool _isSending = false;
  int? _mentionStartIndex;
  String _mentionQuery = '';

  bool get isSending => _isSending;
  bool get isEditing => _editingMessage != null;
  ChatMessage? get editingMessage => _editingMessage;
  String get mentionQuery => _mentionQuery;
  bool get hasActiveMention => _mentionStartIndex != null;
  bool get canSubmit => !_isSending && textController.text.trim().isNotEmpty;

  List<ChatParticipant> get mentionSuggestions {
    if (_mentionStartIndex == null) {
      return const <ChatParticipant>[];
    }

    return _participants
        .where((participant) => participant.matchesQuery(_mentionQuery))
        .take(6)
        .toList(growable: false);
  }

  void setParticipants(List<ChatParticipant> participants) {
    final sameList =
        _participants.length == participants.length &&
        _participants.asMap().entries.every(
          (entry) => entry.value.userId == participants[entry.key].userId,
        );
    if (sameList) {
      return;
    }

    _participants = participants;
    _selectedMentionTokens.removeWhere(
      (userId, _) =>
          !_participants.any((participant) => participant.userId == userId),
    );
    notifyListeners();
  }

  void markSending(bool value) {
    if (_isSending == value) {
      return;
    }

    _isSending = value;
    notifyListeners();
  }

  void startEditing(ChatMessage message) {
    _editingMessage = message;
    _selectedMentionTokens.clear();
    textController.text = message.isDeleted ? '' : message.content;
    textController.selection = TextSelection.collapsed(
      offset: textController.text.length,
    );
    _seedMentions(message);
    focusNode.requestFocus();
    notifyListeners();
  }

  void cancelEditing({bool clearText = false}) {
    _editingMessage = null;
    _selectedMentionTokens.clear();
    if (clearText) {
      textController.clear();
    }
    notifyListeners();
  }

  void clearComposer() {
    _editingMessage = null;
    _selectedMentionTokens.clear();
    textController.clear();
    notifyListeners();
  }

  void selectMention(ChatParticipant participant) {
    final cursorOffset = _safeCursorOffset();
    final mentionStart = _mentionStartIndex;
    if (mentionStart == null) {
      return;
    }

    final prefix = textController.text.substring(0, mentionStart);
    final suffix = textController.text.substring(cursorOffset);
    final replacement = '${participant.mentionToken} ';
    final nextText = '$prefix$replacement$suffix';
    final nextOffset = prefix.length + replacement.length;

    _selectedMentionTokens[participant.userId] = participant.mentionToken;
    textController.value = textController.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
      composing: TextRange.empty,
    );
    focusNode.requestFocus();
  }

  List<String> resolveMentionIds() {
    final draft = textController.text;

    return _selectedMentionTokens.entries
        .where((entry) => draft.contains(entry.value))
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  @override
  void dispose() {
    textController.removeListener(_handleTextChanged);
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    _selectedMentionTokens.removeWhere(
      (_, token) => !textController.text.contains(token),
    );

    final cursorOffset = _safeCursorOffset();
    final prefix = textController.text.substring(0, cursorOffset);
    final match = RegExp(r'(^|\s)@([^\s@]*)$').firstMatch(prefix);

    final nextMentionStart = match == null
        ? null
        : match.start + (match.group(1)?.length ?? 0);
    final nextMentionQuery = match?.group(2) ?? '';

    final changed =
        nextMentionStart != _mentionStartIndex ||
        nextMentionQuery != _mentionQuery;

    _mentionStartIndex = nextMentionStart;
    _mentionQuery = nextMentionQuery;

    if (changed) {
      notifyListeners();
      return;
    }

    if (!_isSending) {
      notifyListeners();
    }
  }

  void _seedMentions(ChatMessage message) {
    for (final userId in message.mentions) {
      for (final participant in _participants) {
        if (participant.userId != userId) {
          continue;
        }
        if (textController.text.contains(participant.mentionToken)) {
          _selectedMentionTokens[userId] = participant.mentionToken;
        }
        break;
      }
    }
  }

  int _safeCursorOffset() {
    final selection = textController.selection;
    final rawOffset = selection.baseOffset;
    if (rawOffset < 0 || rawOffset > textController.text.length) {
      return textController.text.length;
    }

    return rawOffset;
  }
}
