import 'dart:async';

import '../../users/domain/entities/user_profile.dart';
import '../../users/domain/repositories/user_profile_repository.dart';
import '../../workspaces/domain/entities/workspace.dart';
import '../../workspaces/domain/repositories/workspace_repository.dart';
import '../domain/entities/chat_participant.dart';

final class ChatParticipantService {
  ChatParticipantService({
    required WorkspaceRepository workspaceRepository,
    required UserProfileRepository userProfileRepository,
  }) : _workspaceRepository = workspaceRepository,
       _userProfileRepository = userProfileRepository;

  final WorkspaceRepository _workspaceRepository;
  final UserProfileRepository _userProfileRepository;

  Stream<List<ChatParticipant>> watchWorkspaceParticipants(String workspaceId) {
    late final StreamController<List<ChatParticipant>> controller;
    StreamSubscription<List<WorkspaceMember>>? membersSubscription;
    final profileSubscriptions = <String, StreamSubscription<UserProfile?>>{};
    final membersById = <String, WorkspaceMember>{};
    final profilesById = <String, UserProfile?>{};

    void emit() {
      if (controller.isClosed) {
        return;
      }

      final seeds =
          membersById.values
              .map(
                (member) => _ParticipantSeed(
                  userId: member.userId,
                  displayName: _resolveDisplayName(
                    profilesById[member.userId],
                    member.userId,
                  ),
                  secondaryLabel: _resolveSecondaryLabel(
                    profilesById[member.userId],
                  ),
                  role: member.role,
                ),
              )
              .toList(growable: false)
            ..sort(_sortSeeds);

      final handleCounts = <String, int>{};
      for (final seed in seeds) {
        final handle = _baseMentionHandle(seed.displayName, seed.userId);
        handleCounts[handle] = (handleCounts[handle] ?? 0) + 1;
      }

      final participants = seeds
          .map((seed) {
            final handle = _baseMentionHandle(seed.displayName, seed.userId);
            final hasCollision = handleCounts[handle] != 1;
            final uniqueSuffix = hasCollision
                ? '-${seed.userId.substring(0, 4).toLowerCase()}'
                : '';

            return ChatParticipant(
              userId: seed.userId,
              displayName: seed.displayName,
              secondaryLabel: seed.secondaryLabel,
              role: seed.role,
              mentionToken: '@$handle$uniqueSuffix',
            );
          })
          .toList(growable: false);

      controller.add(participants);
    }

    Future<void> syncMembers(List<WorkspaceMember> members) async {
      final nextIds = members.map((member) => member.userId).toSet();
      final staleIds = profileSubscriptions.keys
          .where((userId) => !nextIds.contains(userId))
          .toList(growable: false);

      for (final userId in staleIds) {
        await profileSubscriptions.remove(userId)?.cancel();
        membersById.remove(userId);
        profilesById.remove(userId);
      }

      for (final member in members) {
        membersById[member.userId] = member;

        if (profileSubscriptions.containsKey(member.userId)) {
          continue;
        }

        profileSubscriptions[member.userId] = _userProfileRepository
            .watchProfile(member.userId)
            .listen((profile) {
              profilesById[member.userId] = profile;
              emit();
            }, onError: controller.addError);
      }

      emit();
    }

    controller = StreamController<List<ChatParticipant>>(
      onListen: () {
        membersSubscription = _workspaceRepository
            .watchMembers(workspaceId)
            .listen(syncMembers, onError: controller.addError);
      },
      onCancel: () async {
        await membersSubscription?.cancel();
        for (final subscription in profileSubscriptions.values) {
          await subscription.cancel();
        }
        profileSubscriptions.clear();
        membersById.clear();
        profilesById.clear();
      },
    );

    return controller.stream;
  }

  int _sortSeeds(_ParticipantSeed left, _ParticipantSeed right) {
    final roleCompare = _roleRank(left.role).compareTo(_roleRank(right.role));
    if (roleCompare != 0) {
      return roleCompare;
    }

    return left.displayName.toLowerCase().compareTo(
      right.displayName.toLowerCase(),
    );
  }

  int _roleRank(WorkspaceRole role) {
    return switch (role) {
      WorkspaceRole.owner => 0,
      WorkspaceRole.admin => 1,
      WorkspaceRole.member => 2,
    };
  }

  String _resolveDisplayName(UserProfile? profile, String userId) {
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

  String _resolveSecondaryLabel(UserProfile? profile) {
    final email = profile?.email.trim() ?? '';
    if (email.isNotEmpty) {
      return email;
    }

    final displayName = profile?.displayName.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    return 'Workspace member';
  }

  String _baseMentionHandle(String displayName, String userId) {
    final normalized = displayName
        .trim()
        .replaceAll('@', '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF-]'), '')
        .toLowerCase();

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return 'user-${userId.substring(0, 4).toLowerCase()}';
  }
}

final class _ParticipantSeed {
  const _ParticipantSeed({
    required this.userId,
    required this.displayName,
    required this.secondaryLabel,
    required this.role,
  });

  final String userId;
  final String displayName;
  final String secondaryLabel;
  final WorkspaceRole role;
}
