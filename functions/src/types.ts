export const functionsRegion = "me-west1";
export const inviteLinkScheme = "nexora";
export const inviteLinkHost = "join";

export const workspaceRoles = ["owner", "admin", "member"] as const;
export type WorkspaceRole = (typeof workspaceRoles)[number];

export const inviteAssignableRoles = ["admin", "member"] as const;
export type AssignableInviteRole = (typeof inviteAssignableRoles)[number];

export const inviteStatuses = ["active", "revoked", "exhausted"] as const;
export type WorkspaceInviteStatus = (typeof inviteStatuses)[number];

export const acceptanceResults = [
  "joined",
  "already_member",
] as const;
export type WorkspaceInviteAcceptanceResult =
  (typeof acceptanceResults)[number];

export interface CreateWorkspaceInviteData {
  workspaceId: string;
  role: AssignableInviteRole;
  maxUses?: number;
  expiresAt: string;
  email?: string | null;
}

export interface CreateWorkspaceInviteResponse {
  success: true;
  workspaceId: string;
  inviteId: string;
  joinUrl: string;
  role: AssignableInviteRole;
  status: WorkspaceInviteStatus;
  maxUses: number;
  usedCount: number;
  expiresAt: string;
  email: string | null;
}

export interface GetWorkspaceInvitePreviewData {
  workspaceId: string;
  inviteId: string;
  token: string;
}

export interface GetWorkspaceInvitePreviewResponse {
  success: true;
  workspaceId: string;
  inviteId: string;
  workspaceName: string;
  workspaceDescription: string;
  workspaceArchived: boolean;
  role: AssignableInviteRole;
  status: "active" | "expired" | "revoked" | "exhausted";
  expiresAt: string;
  remainingUses: number;
  emailLocked: boolean;
  email: string | null;
  emailMatchesCurrentUser: boolean | null;
  canAccept: boolean;
}

export interface AcceptWorkspaceInviteData {
  workspaceId: string;
  inviteId: string;
  token: string;
}

export interface AcceptWorkspaceInviteResponse {
  success: true;
  result: WorkspaceInviteAcceptanceResult;
  workspaceId: string;
  workspaceName: string;
  role: AssignableInviteRole | WorkspaceRole;
}

export interface RevokeWorkspaceInviteData {
  workspaceId: string;
  inviteId: string;
}

export interface RevokeWorkspaceInviteResponse {
  success: true;
  workspaceId: string;
  inviteId: string;
  status: "revoked";
  revokedAt: string;
}

export interface WorkspaceInviteRecord {
  workspace_id: string;
  token_hash: string;
  created_by: string;
  role: AssignableInviteRole;
  status: WorkspaceInviteStatus;
  max_uses: number;
  used_count: number;
  expires_at: FirebaseFirestore.Timestamp;
  created_at?: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
  updated_at?: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
  revoked_at?: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue | null;
  email?: string | null;
  last_used_at?: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue | null;
  last_used_by?: string | null;
}
