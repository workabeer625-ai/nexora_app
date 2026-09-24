import { initializeApp } from "firebase-admin/app";

import {
  acceptWorkspaceInvite,
  createWorkspaceInvite,
  getWorkspaceInvitePreview,
  revokeWorkspaceInvite,
} from "./workspaceInvites";

initializeApp();

export {
  acceptWorkspaceInvite,
  createWorkspaceInvite,
  getWorkspaceInvitePreview,
  revokeWorkspaceInvite,
};
