import '../../../workspaces/domain/entities/workspace.dart';

class ChatParticipant {
  const ChatParticipant({
    required this.userId,
    required this.displayName,
    required this.secondaryLabel,
    required this.role,
    required this.mentionToken,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String secondaryLabel;
  final WorkspaceRole role;
  final String mentionToken;
  final String? avatarUrl;

  String get initials => buildChatParticipantInitials(displayName);

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return displayName.toLowerCase().contains(normalized) ||
        secondaryLabel.toLowerCase().contains(normalized) ||
        mentionToken.toLowerCase().contains(normalized);
  }
}

String buildChatParticipantInitials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) {
    return 'N';
  }

  if (parts.length == 1) {
    final first = parts.first;
    return first.length >= 2
        ? first.substring(0, 2).toUpperCase()
        : first.substring(0, 1).toUpperCase();
  }

  final first = parts.first.substring(0, 1).toUpperCase();
  final second = parts.last.substring(0, 1).toUpperCase();
  return '$first$second';
}
