import { HttpsError } from "firebase-functions/v2/https";

export type WorkspaceInviteErrorReason =
  | "unauthenticated"
  | "permission_denied"
  | "invalid_workspace_id"
  | "invalid_invite_id"
  | "invalid_token"
  | "invalid_role"
  | "invalid_max_uses"
  | "invalid_expires_at"
  | "invalid_email"
  | "workspace_not_found"
  | "workspace_archived"
  | "invite_not_found"
  | "invite_invalid"
  | "invite_expired"
  | "invite_revoked"
  | "invite_exhausted"
  | "email_mismatch"
  | "already_member";

interface ErrorConfig {
  code:
    | "unauthenticated"
    | "permission-denied"
    | "invalid-argument"
    | "not-found"
    | "failed-precondition";
  message: string;
}

const errorConfigs: Record<WorkspaceInviteErrorReason, ErrorConfig> = {
  unauthenticated: {
    code: "unauthenticated",
    message: "Authentication is required.",
  },
  permission_denied: {
    code: "permission-denied",
    message: "You do not have permission to perform this action.",
  },
  invalid_workspace_id: {
    code: "invalid-argument",
    message: "Workspace ID is invalid.",
  },
  invalid_invite_id: {
    code: "invalid-argument",
    message: "Invite ID is invalid.",
  },
  invalid_token: {
    code: "invalid-argument",
    message: "Invite token is invalid.",
  },
  invalid_role: {
    code: "invalid-argument",
    message: "Invite role is invalid.",
  },
  invalid_max_uses: {
    code: "invalid-argument",
    message: "Max uses must be at least 1.",
  },
  invalid_expires_at: {
    code: "invalid-argument",
    message: "Invite expiration date is invalid.",
  },
  invalid_email: {
    code: "invalid-argument",
    message: "Invite email is invalid.",
  },
  workspace_not_found: {
    code: "not-found",
    message: "Workspace not found.",
  },
  workspace_archived: {
    code: "failed-precondition",
    message: "Archived workspaces cannot accept invites.",
  },
  invite_not_found: {
    code: "not-found",
    message: "Invite not found.",
  },
  invite_invalid: {
    code: "invalid-argument",
    message: "Invite link is invalid.",
  },
  invite_expired: {
    code: "failed-precondition",
    message: "Invite has expired.",
  },
  invite_revoked: {
    code: "failed-precondition",
    message: "Invite has been revoked.",
  },
  invite_exhausted: {
    code: "failed-precondition",
    message: "Invite has no remaining uses.",
  },
  email_mismatch: {
    code: "failed-precondition",
    message: "This invite is restricted to a different email address.",
  },
  already_member: {
    code: "failed-precondition",
    message: "You are already a member of this workspace.",
  },
};

export function workspaceInviteError(
  reason: WorkspaceInviteErrorReason,
  details?: Record<string, unknown>,
): HttpsError {
  const config = errorConfigs[reason];

  return new HttpsError(config.code, config.message, {
    reason,
    message: config.message,
    ...details,
  });
}
