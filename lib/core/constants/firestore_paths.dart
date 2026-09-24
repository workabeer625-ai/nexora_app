final class FirestorePaths {
  const FirestorePaths._();

  static const String users = 'users';
  static const String workspaces = 'workspaces';
  static const String members = 'members';
  static const String joinCodes = 'join_codes';
  static const String joinRequests = 'join_requests';
  static const String joinCodeLookup = 'join_code_lookup';
  static const String projects = 'projects';
  static const String tasks = 'tasks';
  static const String comments = 'comments';
  static const String messages = 'messages';
  static const String chatMessages = 'chat_messages';
  static const String notifications = 'notifications';

  static String user(String uid) => '$users/$uid';

  static String userNotifications(String uid) => '${user(uid)}/$notifications';

  static String workspace(String workspaceId) => '$workspaces/$workspaceId';

  static String workspaceMembers(String workspaceId) =>
      '${workspace(workspaceId)}/$members';

  static String workspaceMember(String workspaceId, String userId) =>
      '${workspaceMembers(workspaceId)}/$userId';

  static String workspaceJoinCodes(String workspaceId) =>
      '${workspace(workspaceId)}/$joinCodes';

  static String workspaceJoinCode(String workspaceId, String joinCodeId) =>
      '${workspaceJoinCodes(workspaceId)}/$joinCodeId';

  static String workspaceJoinRequests(String workspaceId) =>
      '${workspace(workspaceId)}/$joinRequests';

  static String workspaceJoinRequest(String workspaceId, String userId) =>
      '${workspaceJoinRequests(workspaceId)}/$userId';

  static String joinCodeLookupDoc(String codeNormalized) =>
      '$joinCodeLookup/$codeNormalized';

  static String workspaceProjects(String workspaceId) =>
      '${workspace(workspaceId)}/$projects';

  static String project(String workspaceId, String projectId) =>
      '${workspaceProjects(workspaceId)}/$projectId';

  static String projectTasks(String workspaceId, String projectId) =>
      '${project(workspaceId, projectId)}/$tasks';

  static String task(String workspaceId, String projectId, String taskId) =>
      '${projectTasks(workspaceId, projectId)}/$taskId';

  static String taskComments(
    String workspaceId,
    String projectId,
    String taskId,
  ) => '${task(workspaceId, projectId, taskId)}/$comments';

  static String taskMessages(
    String workspaceId,
    String projectId,
    String taskId,
  ) => '${task(workspaceId, projectId, taskId)}/$messages';

  static String workspaceChatMessages(String workspaceId) =>
      '${workspace(workspaceId)}/$chatMessages';
}
