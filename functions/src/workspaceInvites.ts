import { randomBytes, createHash } from "node:crypto";
import {
  FieldValue,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import type { AuthData } from "firebase-functions/lib/common/providers/https";
import { onCall, type CallableRequest } from "firebase-functions/v2/https";

import { workspaceInviteError } from "./errors";
import {
  acceptanceResults,
  functionsRegion,
  inviteAssignableRoles,
  inviteLinkHost,
  inviteLinkScheme,
  type AcceptWorkspaceInviteData,
  type AcceptWorkspaceInviteResponse,
  type AssignableInviteRole,
  type CreateWorkspaceInviteData,
  type CreateWorkspaceInviteResponse,
  type GetWorkspaceInvitePreviewData,
  type GetWorkspaceInvitePreviewResponse,
  type RevokeWorkspaceInviteData,
  type RevokeWorkspaceInviteResponse,
  type WorkspaceInviteRecord,
  type WorkspaceRole,
} from "./types";

const db = getFirestore();

function assertAuthenticated(auth: AuthData | undefined): string {
  const uid = auth?.uid;
  if (!uid) {
    throw workspaceInviteError("unauthenticated");
  }

  return uid;
}

function normalizeEmail(value: string | null | undefined): string | null {
  if (value == null) {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  if (normalized.length == 0) {
    return null;
  }

  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailPattern.test(normalized)) {
    throw workspaceInviteError("invalid_email");
  }

  return normalized;
}

function assertWorkspaceId(value: unknown): string {
  const workspaceId = typeof value === "string" ? value.trim() : "";
  if (workspaceId.length < 6) {
    throw workspaceInviteError("invalid_workspace_id");
  }

  return workspaceId;
}

function assertInviteId(value: unknown): string {
  const inviteId = typeof value === "string" ? value.trim() : "";
  if (inviteId.length < 6) {
    throw workspaceInviteError("invalid_invite_id");
  }

  return inviteId;
}

function assertToken(value: unknown): string {
  const token = typeof value === "string" ? value.trim() : "";
  if (token.length < 32) {
    throw workspaceInviteError("invalid_token");
  }

  return token;
}

function assertInviteRole(value: unknown): AssignableInviteRole {
  if (typeof value !== "string" || !inviteAssignableRoles.includes(value as AssignableInviteRole)) {
    throw workspaceInviteError("invalid_role");
  }

  return value as AssignableInviteRole;
}

function assertMaxUses(value: unknown): number {
  if (value == null) {
    return 1;
  }

  if (!Number.isInteger(value) || (value as number) < 1) {
    throw workspaceInviteError("invalid_max_uses");
  }

  return value as number;
}

function assertExpiresAt(value: unknown): Timestamp {
  if (typeof value !== "string") {
    throw workspaceInviteError("invalid_expires_at");
  }

  const parsed = Date.parse(value);
  if (Number.isNaN(parsed)) {
    throw workspaceInviteError("invalid_expires_at");
  }

  const expiresAt = Timestamp.fromDate(new Date(parsed));
  if (expiresAt.toMillis() <= Date.now()) {
    throw workspaceInviteError("invalid_expires_at");
  }

  return expiresAt;
}

function hashToken(token: string): string {
  return createHash("sha256").update(token, "utf8").digest("hex");
}

function buildInviteUrl(workspaceId: string, inviteId: string, rawToken: string): string {
  const url = new URL(`${inviteLinkScheme}://${inviteLinkHost}`);
  url.searchParams.set("wid", workspaceId);
  url.searchParams.set("iid", inviteId);
  url.searchParams.set("token", rawToken);
  return url.toString();
}

function resolveInviteStatus(invite: WorkspaceInviteRecord): "active" | "expired" | "revoked" | "exhausted" {
  if (invite.status === "revoked") {
    return "revoked";
  }

  if (invite.status === "exhausted" || invite.used_count >= invite.max_uses) {
    return "exhausted";
  }

  if (invite.expires_at.toMillis() <= Date.now()) {
    return "expired";
  }

  return "active";
}

async function getWorkspaceMembershipRole(
  workspaceId: string,
  uid: string,
): Promise<WorkspaceRole | null> {
  const membershipSnapshot = await db
    .doc(`workspaces/${workspaceId}/members/${uid}`)
    .get();

  if (!membershipSnapshot.exists) {
    return null;
  }

  const role = membershipSnapshot.get("role");
  const status = membershipSnapshot.get("status");
  if (status !== "active") {
    return null;
  }

  if (role === "owner" || role === "admin" || role === "member") {
    return role;
  }

  return null;
}

async function assertWorkspaceAdmin(workspaceId: string, uid: string): Promise<void> {
  const workspaceSnapshot = await db.doc(`workspaces/${workspaceId}`).get();
  if (!workspaceSnapshot.exists) {
    throw workspaceInviteError("workspace_not_found");
  }

  if (workspaceSnapshot.get("is_archived") == true) {
    throw workspaceInviteError("workspace_archived");
  }

  const role = await getWorkspaceMembershipRole(workspaceId, uid);
  if (role !== "owner" && role !== "admin") {
    throw workspaceInviteError("permission_denied");
  }
}

export const createWorkspaceInvite = onCall<CreateWorkspaceInviteData>(
  { region: functionsRegion },
  async (request: CallableRequest<CreateWorkspaceInviteData>): Promise<CreateWorkspaceInviteResponse> => {
    const uid = assertAuthenticated(request.auth);
    const workspaceId = assertWorkspaceId(request.data.workspaceId);
    const role = assertInviteRole(request.data.role);
    const maxUses = assertMaxUses(request.data.maxUses);
    const expiresAt = assertExpiresAt(request.data.expiresAt);
    const email = normalizeEmail(request.data.email);

    await assertWorkspaceAdmin(workspaceId, uid);

    const inviteRef = db.collection(`workspaces/${workspaceId}/invites`).doc();
    const rawToken = randomBytes(32).toString("base64url");

    const inviteRecord: WorkspaceInviteRecord = {
      workspace_id: workspaceId,
      token_hash: hashToken(rawToken),
      created_by: uid,
      role,
      status: "active",
      max_uses: maxUses,
      used_count: 0,
      expires_at: expiresAt,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
      revoked_at: null,
      email,
      last_used_at: null,
      last_used_by: null,
    };

    await inviteRef.set(inviteRecord);

    return {
      success: true,
      workspaceId,
      inviteId: inviteRef.id,
      joinUrl: buildInviteUrl(workspaceId, inviteRef.id, rawToken),
      role,
      status: "active",
      maxUses,
      usedCount: 0,
      expiresAt: expiresAt.toDate().toISOString(),
      email,
    };
  },
);

export const getWorkspaceInvitePreview = onCall<GetWorkspaceInvitePreviewData>(
  { region: functionsRegion },
  async (
    request: CallableRequest<GetWorkspaceInvitePreviewData>,
  ): Promise<GetWorkspaceInvitePreviewResponse> => {
    const workspaceId = assertWorkspaceId(request.data.workspaceId);
    const inviteId = assertInviteId(request.data.inviteId);
    const token = assertToken(request.data.token);

    const [workspaceSnapshot, inviteSnapshot] = await Promise.all([
      db.doc(`workspaces/${workspaceId}`).get(),
      db.doc(`workspaces/${workspaceId}/invites/${inviteId}`).get(),
    ]);

    if (!workspaceSnapshot.exists) {
      throw workspaceInviteError("workspace_not_found");
    }

    if (!inviteSnapshot.exists) {
      throw workspaceInviteError("invite_invalid");
    }

    const invite = inviteSnapshot.data() as WorkspaceInviteRecord;
    if (invite.workspace_id !== workspaceId || invite.token_hash !== hashToken(token)) {
      throw workspaceInviteError("invite_invalid");
    }

    const resolvedStatus = resolveInviteStatus(invite);
    const currentUserEmail = normalizeEmail(request.auth?.token.email as string | undefined);
    const emailMatchesCurrentUser = invite.email == null
      ? null
      : currentUserEmail != null && currentUserEmail === invite.email;

    return {
      success: true,
      workspaceId,
      inviteId,
      workspaceName: String(workspaceSnapshot.get("name") ?? ""),
      workspaceDescription: String(workspaceSnapshot.get("description") ?? ""),
      workspaceArchived: workspaceSnapshot.get("is_archived") == true,
      role: invite.role,
      status: resolvedStatus,
      expiresAt: invite.expires_at.toDate().toISOString(),
      remainingUses: Math.max(invite.max_uses - invite.used_count, 0),
      emailLocked: invite.email != null,
      email: invite.email ?? null,
      emailMatchesCurrentUser,
      canAccept:
        workspaceSnapshot.get("is_archived") != true &&
        resolvedStatus === "active" &&
        (invite.email == null || emailMatchesCurrentUser == true),
    };
  },
);

export const acceptWorkspaceInvite = onCall<AcceptWorkspaceInviteData>(
  { region: functionsRegion },
  async (
    request: CallableRequest<AcceptWorkspaceInviteData>,
  ): Promise<AcceptWorkspaceInviteResponse> => {
    const uid = assertAuthenticated(request.auth);
    const workspaceId = assertWorkspaceId(request.data.workspaceId);
    const inviteId = assertInviteId(request.data.inviteId);
    const token = assertToken(request.data.token);
    const email = normalizeEmail(request.auth?.token.email as string | undefined);

    const workspaceRef = db.doc(`workspaces/${workspaceId}`);
    const inviteRef = workspaceRef.collection("invites").doc(inviteId);
    const memberRef = workspaceRef.collection("members").doc(uid);
    const inviteUseRef = inviteRef.collection("uses").doc(uid);

    return db.runTransaction(async (transaction) => {
      const [workspaceSnapshot, inviteSnapshot, memberSnapshot] =
        await Promise.all([
          transaction.get(workspaceRef),
          transaction.get(inviteRef),
          transaction.get(memberRef),
        ]);

      if (!workspaceSnapshot.exists) {
        throw workspaceInviteError("workspace_not_found");
      }

      if (workspaceSnapshot.get("is_archived") == true) {
        throw workspaceInviteError("workspace_archived");
      }

      if (!inviteSnapshot.exists) {
        throw workspaceInviteError("invite_invalid");
      }

      const invite = inviteSnapshot.data() as WorkspaceInviteRecord;
      if (invite.workspace_id !== workspaceId || invite.token_hash !== hashToken(token)) {
        throw workspaceInviteError("invite_invalid");
      }

      const resolvedStatus = resolveInviteStatus(invite);
      if (resolvedStatus === "revoked") {
        throw workspaceInviteError("invite_revoked");
      }
      if (resolvedStatus === "expired") {
        throw workspaceInviteError("invite_expired");
      }
      if (resolvedStatus === "exhausted") {
        throw workspaceInviteError("invite_exhausted");
      }

      if (invite.email != null) {
        if (email == null || email !== invite.email) {
          throw workspaceInviteError("email_mismatch");
        }
      }

      if (memberSnapshot.exists) {
        const currentStatus = memberSnapshot.get("status");
        const currentRole = memberSnapshot.get("role");
        if (currentStatus === "active") {
          transaction.update(workspaceRef, {
            member_ids: FieldValue.arrayUnion(uid),
            updated_at: FieldValue.serverTimestamp(),
          });

          return {
            success: true,
            result: acceptanceResults[1],
            workspaceId,
            workspaceName: String(workspaceSnapshot.get("name") ?? ""),
            role:
              currentRole === "owner" ||
              currentRole === "admin" ||
              currentRole === "member"
                ? currentRole
                : invite.role,
          };
        }
      }

      transaction.set(
        memberRef,
        {
          workspace_id: workspaceId,
          user_id: uid,
          role: invite.role,
          status: "active",
          joined_at: FieldValue.serverTimestamp(),
          invited_by: invite.created_by,
          invite_id: inviteId,
        },
        { merge: true },
      );

      transaction.update(workspaceRef, {
        member_ids: FieldValue.arrayUnion(uid),
        member_count: FieldValue.increment(1),
        updated_at: FieldValue.serverTimestamp(),
      });

      const updatedUsedCount = invite.used_count + 1;
      transaction.update(inviteRef, {
        used_count: updatedUsedCount,
        updated_at: FieldValue.serverTimestamp(),
        last_used_at: FieldValue.serverTimestamp(),
        last_used_by: uid,
        status: updatedUsedCount >= invite.max_uses ? "exhausted" : "active",
      });

      transaction.set(inviteUseRef, {
        user_id: uid,
        joined_at: FieldValue.serverTimestamp(),
        invite_id: inviteId,
        workspace_id: workspaceId,
      });

      return {
        success: true,
        result: acceptanceResults[0],
        workspaceId,
        workspaceName: String(workspaceSnapshot.get("name") ?? ""),
        role: invite.role,
      };
    });
  },
);

export const revokeWorkspaceInvite = onCall<RevokeWorkspaceInviteData>(
  { region: functionsRegion },
  async (
    request: CallableRequest<RevokeWorkspaceInviteData>,
  ): Promise<RevokeWorkspaceInviteResponse> => {
    const uid = assertAuthenticated(request.auth);
    const workspaceId = assertWorkspaceId(request.data.workspaceId);
    const inviteId = assertInviteId(request.data.inviteId);

    await assertWorkspaceAdmin(workspaceId, uid);

    const inviteRef = db.doc(`workspaces/${workspaceId}/invites/${inviteId}`);
    const inviteSnapshot = await inviteRef.get();
    if (!inviteSnapshot.exists) {
      throw workspaceInviteError("invite_not_found");
    }

    const invite = inviteSnapshot.data() as WorkspaceInviteRecord;
    const alreadyRevoked = invite.status === "revoked";
    const revokedAt = Timestamp.now();

    if (!alreadyRevoked) {
      await inviteRef.update({
        status: "revoked",
        revoked_at: revokedAt,
        updated_at: FieldValue.serverTimestamp(),
      });
    }

    return {
      success: true,
      workspaceId,
      inviteId,
      status: "revoked",
      revokedAt: revokedAt.toDate().toISOString(),
    };
  },
);
