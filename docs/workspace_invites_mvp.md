# Nexora Workspace Invites MVP

## Decision

Use `Cloud Functions callable` with the Admin SDK for invite creation, preview,
acceptance, and revocation.

This is the best MVP decision for Nexora because:

- invite acceptance must update multiple documents atomically:
  - `workspaces/{workspaceId}`
  - `workspaces/{workspaceId}/members/{uid}`
  - `workspaces/{workspaceId}/invites/{inviteId}`
- the app must keep the raw invite token out of Firestore and store only a hash
- a non-member must never be able to add themselves directly through client-side
  writes
- expressing all invite acceptance checks in Firestore Rules alone would force
  overly-broad client write access and would be brittle

`client + transaction` is not recommended for this flow.

## Invite Document Schema

Path:

```text
workspaces/{workspaceId}/invites/{inviteId}
```

Required fields:

```text
workspace_id   string
token_hash     string
created_by     string
role           string        // owner|admin|member, for MVP allow admin|member
status         string        // active|revoked|exhausted
max_uses       number        // default 1
used_count     number        // default 0
expires_at     timestamp
created_at     timestamp
updated_at     timestamp
revoked_at     timestamp?    // null until revoked
email          string?       // optional lowercase email lock
```

Recommended optional fields:

```text
last_used_at   timestamp?
last_used_by   string?
```

Recommended audit subcollection:

```text
workspaces/{workspaceId}/invites/{inviteId}/uses/{uid}
  - user_id
  - joined_at
  - invite_id
  - workspace_id
```

The `uses` subcollection is optional for the first cut, but recommended because
it gives auditability and makes repeated-use handling easier without storing
large arrays in the invite document.

## Membership Document On Accept

When an invite is accepted, create or update:

```text
workspaces/{workspaceId}/members/{uid}
  - workspace_id
  - user_id
  - role
  - status          // active
  - joined_at
  - invited_by
  - invite_id
```

Also update the workspace:

```text
workspaces/{workspaceId}
  - member_ids      // arrayUnion(uid)
  - member_count    // increment only when the user was not already active
  - updated_at
```

## Link Format

Use a deep link or web link that contains:

```text
workspaceId
inviteId
token
```

Example:

```text
https://app.nexora.com/join?wid={workspaceId}&iid={inviteId}&token={rawToken}
```

or:

```text
nexora://join?wid={workspaceId}&iid={inviteId}&token={rawToken}
```

Do not store `rawToken` in Firestore.

Generate the raw token as a high-entropy random value:

```text
base64url(randomBytes(32))
```

Store only:

```text
token_hash = sha256(rawToken)
```

Including `workspaceId` and `inviteId` in the link avoids a collection-group
query by hash and lets the backend read a single invite document directly.

## End-to-End Flow

### 1. Admin creates an invite

UI:

- workspace admin opens `Invite members`
- chooses role
- chooses expiry
- chooses max uses
- optionally locks invite to an email

Backend callable:

```text
createWorkspaceInvite(workspaceId, role, maxUses, expiresAt, email?)
```

Server-side validation:

- caller is authenticated
- caller is `owner` or `admin` in that workspace
- workspace exists and is not archived
- role is allowed
- `maxUses >= 1`
- `expiresAt > now`
- if email exists, normalize to lowercase and trim

Server-side write:

- create `inviteId`
- generate `rawToken`
- hash it to `token_hash`
- write invite document with `status = active`
- return the final link to the client

### 2. User opens the link

Client:

- parse `wid`, `iid`, `token`
- if not authenticated, route to login and preserve pending invite payload
- after login, route to `JoinWorkspacePage`

### 3. Preview invite before join

Recommended callable:

```text
getWorkspaceInvitePreview(workspaceId, inviteId, token)
```

Return only safe fields:

- workspace name
- workspace description
- role to be granted
- whether invite is expired/revoked/exhausted
- whether current user email matches the invite email lock

Do not return `token_hash`.

### 4. User confirms join

Callable:

```text
acceptWorkspaceInvite(workspaceId, inviteId, token)
```

### 5. Backend accepts invite in a transaction

Validate:

- caller is authenticated
- workspace exists and is not archived
- invite exists
- `sha256(token) == invite.token_hash`
- invite `status == active`
- `expires_at > now`
- `used_count < max_uses`
- if `email` exists, it matches the authenticated user email
- caller is not already an active member

Transaction writes:

- create or update `members/{uid}`
- `arrayUnion(uid)` into `member_ids`
- increment `member_count` only if user was not already active
- increment `used_count`
- set `last_used_at` and `last_used_by`
- if `used_count + 1 >= max_uses`, set `status = exhausted`
- optionally create `invites/{inviteId}/uses/{uid}`

## Acceptance Rules For Edge Cases

Reject acceptance when:

- invite document does not exist
- raw token hash does not match
- invite is revoked
- invite is expired
- invite is exhausted
- workspace is archived
- authenticated email does not match invite email lock
- user is already an active member

Recommended behavior:

- if user is already an active member, return a typed result such as
  `already_member` and route them into the workspace
- if member doc exists with `status = removed`, allow reactivation through a
  valid invite

## Why Callable Functions Beat Client Transactions

### Recommended: callable functions

Pros:

- keeps all sensitive invite validation on the server
- keeps `members` self-join blocked in Firestore Rules
- allows secure multi-document transaction logic
- easier to evolve later for:
  - rate limits
  - analytics
  - email delivery
  - audit logs
  - invite abuse detection

Cons:

- requires a Firebase Functions backend

### Not recommended: client + transaction

Problems:

- client would need write access to membership and workspace update flow
- rules would become complicated and easier to bypass incorrectly
- harder to safely validate hashed token and use limits for non-members

## Security Rules Direction

The key rule decision for the MVP:

- clients must not be allowed to add themselves directly under
  `workspaces/{workspaceId}/members/{uid}`
- invite acceptance must happen only through Cloud Functions

### Rules for invites

Add this under `match /workspaces/{workspaceId}`:

```javascript
match /invites/{inviteId} {
  allow read: if isWorkspaceAdmin(workspaceId);
  allow create, update, delete: if isWorkspaceAdmin(workspaceId);

  match /uses/{usedByUid} {
    allow read: if isWorkspaceAdmin(workspaceId);
    allow write: if false;
  }
}
```

### Rules for members

Keep direct member writes blocked except:

- owner bootstrap during workspace creation
- admin-managed member updates

That means the current member rule pattern remains correct:

```javascript
match /members/{memberUid} {
  allow read: if isWorkspaceListedMember(workspaceId);
  allow create: if isWorkspaceAdmin(workspaceId)
    || isWorkspaceOwnerBootstrap(workspaceId, memberUid);
  allow update: if isWorkspaceAdmin(workspaceId);
  allow delete: if isWorkspaceOwner(workspaceId);
}
```

With this design, a regular signed-in user cannot self-add to `members`.

## Suggested Flutter Structure

Create a new feature:

```text
lib/features/workspace_invites/
  application/
    workspace_invite_service.dart
  data/
    models/
      workspace_invite_preview_model.dart
      workspace_invite_model.dart
    repositories/
      callable_workspace_invite_repository.dart
  domain/
    entities/
      workspace_invite.dart
      workspace_invite_preview.dart
    repositories/
      workspace_invite_repository.dart
  presentation/
    pages/
      join_workspace_page.dart
    widgets/
      create_invite_dialog.dart
      invite_tile.dart
```

Suggested backend structure:

```text
functions/src/workspaceInvites.ts
  - createWorkspaceInvite
  - getWorkspaceInvitePreview
  - acceptWorkspaceInvite
  - revokeWorkspaceInvite
```

## Suggested Entities

### WorkspaceInvite

```text
id
workspaceId
createdBy
role
status
maxUses
usedCount
expiresAt
createdAt
updatedAt
revokedAt
email
```

### WorkspaceInvitePreview

```text
workspaceId
workspaceName
workspaceDescription
role
status
expiresAt
emailLocked
emailMatchesCurrentUser
```

### AcceptWorkspaceInviteResult

```text
workspaceId
workspaceName
membershipRole
result
```

Where `result` can be:

```text
joined
already_member
expired
revoked
exhausted
invalid
email_mismatch
workspace_archived
```

## Pseudocode

### createWorkspaceInvite

```text
assert auth exists
load workspace member doc for caller
assert caller role is owner/admin
assert workspace not archived

inviteId = new doc id
rawToken = base64url(randomBytes(32))
tokenHash = sha256(rawToken)

write invites/{inviteId}:
  workspace_id = workspaceId
  token_hash = tokenHash
  created_by = callerUid
  role = requestedRole
  status = active
  max_uses = maxUses
  used_count = 0
  expires_at = expiresAt
  created_at = serverTimestamp
  updated_at = serverTimestamp
  revoked_at = null
  email = normalizedEmailOrNull

return joinLink(workspaceId, inviteId, rawToken)
```

### acceptWorkspaceInvite

```text
assert auth exists
load workspace
assert workspace exists and not archived

load invite by path
assert invite exists
assert sha256(rawToken) == invite.token_hash
assert invite.status == active
assert invite.expires_at > now
assert invite.used_count < invite.max_uses

if invite.email != null:
  assert auth.email exists
  assert normalize(auth.email) == invite.email

transaction:
  load members/{uid}
  if member exists and status == active:
    return already_member

  write members/{uid}:
    workspace_id = workspaceId
    user_id = uid
    role = invite.role
    status = active
    joined_at = serverTimestamp
    invited_by = invite.created_by
    invite_id = inviteId

  update workspace:
    member_ids = arrayUnion(uid)
    member_count = increment(1)
    updated_at = serverTimestamp

  update invite:
    used_count = invite.used_count + 1
    updated_at = serverTimestamp
    last_used_at = serverTimestamp
    last_used_by = uid
    if used_count reaches max_uses:
      status = exhausted

  optional write invites/{inviteId}/uses/{uid}

return joined
```

## UI Flow

### Admin side

- open workspace details
- tap `Invite members`
- choose:
  - role
  - expiration
  - max uses
  - optional email
- tap `Create invite`
- show generated link
- `Copy link`

### Recipient side

- open link
- app parses invite payload
- if signed out, go to login
- after login, open `JoinWorkspacePage`
- show workspace preview and granted role
- user taps `Join workspace`
- callable runs
- success routes into workspace

## Validation And Security Notes

- never store raw invite tokens in Firestore
- use high-entropy random tokens only
- prefer `App Check` on callable functions in production
- normalize all emails to lowercase before storing or comparing
- if your product relies on email-bound invites, prefer requiring a verified
  email before accepting an email-locked invite
- do not allow `owner` role invites in the first MVP unless there is a real
  business need
- revocation should only flip `status = revoked` and set `revoked_at`
- avoid deleting invite docs immediately; keep them for audit

## Repo-Specific Notes

Current Nexora code still uses direct manual member addition:

- `WorkspaceManagementService.addMember`
- `WorkspaceRepository.addMember`

That flow should remain for internal/admin tooling only or be deprecated after
the invite flow ships.

Current task storage in the repo is nested under projects:

```text
workspaces/{workspaceId}/projects/{projectId}/tasks/{taskId}
```

The invite design above does not conflict with that structure.
