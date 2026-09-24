import 'auth_service.dart';
import 'firestore_service.dart';
import '../../features/auth/application/auth_coordinator.dart';
import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/chat/application/chat_participant_service.dart';
import '../../features/chat/application/chat_service.dart';
import '../../features/chat/data/repositories/firestore_chat_repository.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/notifications/data/repositories/firestore_notification_repository.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/projects/application/project_management_service.dart';
import '../../features/projects/data/repositories/firestore_project_repository.dart';
import '../../features/projects/domain/repositories/project_repository.dart';
import '../../features/tasks/application/task_management_service.dart';
import '../../features/tasks/data/repositories/firestore_task_repository.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/users/data/repositories/firestore_user_profile_repository.dart';
import '../../features/users/domain/repositories/user_profile_repository.dart';
import '../../features/workspace_join/application/workspace_join_service.dart';
import '../../features/workspace_join/data/repositories/firestore_workspace_join_repository.dart';
import '../../features/workspace_join/domain/repositories/workspace_join_repository.dart';
import '../../features/workspaces/application/workspace_management_service.dart';
import '../../features/workspaces/data/repositories/firestore_workspace_repository.dart';
import '../../features/workspaces/domain/repositories/workspace_repository.dart';

/// Lightweight application dependency container until feature-level injection is added.
final class AppServices {
  factory AppServices({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) {
    final resolvedAuthService = authService ?? FirebaseAuthService();
    final resolvedFirestoreService =
        firestoreService ?? FirebaseFirestoreService();

    final authRepository = FirebaseEmailAuthRepository(
      authService: resolvedAuthService,
    );
    final userProfileRepository = FirestoreUserProfileRepository(
      firestoreService: resolvedFirestoreService,
    );
    final workspaceRepository = FirestoreWorkspaceRepository(
      firestoreService: resolvedFirestoreService,
    );
    final projectRepository = FirestoreProjectRepository(
      firestoreService: resolvedFirestoreService,
    );
    final taskRepository = FirestoreTaskRepository(
      firestoreService: resolvedFirestoreService,
    );
    final chatRepository = FirestoreChatRepository(
      firestoreService: resolvedFirestoreService,
    );
    final notificationRepository = FirestoreNotificationRepository(
      firestoreService: resolvedFirestoreService,
    );
    final workspaceJoinRepository = FirestoreWorkspaceJoinRepository(
      firestoreService: resolvedFirestoreService,
    );

    return AppServices._(
      authService: resolvedAuthService,
      firestoreService: resolvedFirestoreService,
      authRepository: authRepository,
      userProfileRepository: userProfileRepository,
      workspaceRepository: workspaceRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      chatRepository: chatRepository,
      notificationRepository: notificationRepository,
      workspaceJoinRepository: workspaceJoinRepository,
      authCoordinator: AuthCoordinator(
        authRepository: authRepository,
        userProfileRepository: userProfileRepository,
      ),
      workspaceManagementService: WorkspaceManagementService(
        workspaceRepository: workspaceRepository,
      ),
      projectManagementService: ProjectManagementService(
        projectRepository: projectRepository,
      ),
      taskManagementService: TaskManagementService(
        taskRepository: taskRepository,
        workspaceRepository: workspaceRepository,
        notificationRepository: notificationRepository,
      ),
      chatService: ChatService(
        chatRepository: chatRepository,
        workspaceRepository: workspaceRepository,
        userProfileRepository: userProfileRepository,
        notificationRepository: notificationRepository,
      ),
      chatParticipantService: ChatParticipantService(
        workspaceRepository: workspaceRepository,
        userProfileRepository: userProfileRepository,
      ),
      workspaceJoinService: WorkspaceJoinService(
        workspaceJoinRepository: workspaceJoinRepository,
        workspaceRepository: workspaceRepository,
        userProfileRepository: userProfileRepository,
        notificationRepository: notificationRepository,
      ),
    );
  }

  const AppServices._({
    required this.authService,
    required this.firestoreService,
    required this.authRepository,
    required this.userProfileRepository,
    required this.workspaceRepository,
    required this.projectRepository,
    required this.taskRepository,
    required this.chatRepository,
    required this.notificationRepository,
    required this.workspaceJoinRepository,
    required this.authCoordinator,
    required this.workspaceManagementService,
    required this.projectManagementService,
    required this.taskManagementService,
    required this.chatService,
    required this.chatParticipantService,
    required this.workspaceJoinService,
  });

  final AuthService authService;
  final FirestoreService firestoreService;
  final AuthRepository authRepository;
  final UserProfileRepository userProfileRepository;
  final WorkspaceRepository workspaceRepository;
  final ProjectRepository projectRepository;
  final TaskRepository taskRepository;
  final ChatRepository chatRepository;
  final NotificationRepository notificationRepository;
  final WorkspaceJoinRepository workspaceJoinRepository;
  final AuthCoordinator authCoordinator;
  final WorkspaceManagementService workspaceManagementService;
  final ProjectManagementService projectManagementService;
  final TaskManagementService taskManagementService;
  final ChatService chatService;
  final ChatParticipantService chatParticipantService;
  final WorkspaceJoinService workspaceJoinService;
}
