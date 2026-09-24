# Nexora Workspace Join Flow

## Firestore schema

```text
workspaces/{workspaceId}
  id
  name
  description
  owner_id
  created_at
  updated_at
  is_archived
  member_ids
  member_count

workspaces/{workspaceId}/members/{userId}
  workspace_id
  user_id
  role
  joined_at
  status
  source              // join_code_request for approved requests
  approved_by
  join_request_id
  join_code_id

workspaces/{workspaceId}/join_codes/{joinCodeId}
  id
  workspace_id
  workspace_name_snapshot
  workspace_description_snapshot
  code
  code_normalized
  kind                // single_use | multi_use
  is_active
  max_uses
  used_count
  expires_at
  created_at
  updated_at
  created_by

workspaces/{workspaceId}/join_requests/{uid}
  user_id
  workspace_id
  status              // pending | approved | rejected
  requested_at
  reviewed_at
  reviewed_by
  requested_via       // manual_code | qr_scan | qr_gallery
  note
  user_display_name_snapshot
  user_email_snapshot
  join_code_snapshot
    join_code_id
    code
    code_normalized
    kind
    max_uses

join_code_lookup/{code_normalized}
  workspace_id
  join_code_id
  code_normalized
  workspace_name_snapshot
  workspace_description_snapshot
  kind
  is_active
  max_uses
  used_count
  expires_at
  created_at
  updated_at
```

## File structure

```text
lib/features/workspace_join/
  application/
    workspace_join_code_utils.dart
    workspace_join_service.dart
  data/
    models/
      workspace_join_code_model.dart
      workspace_join_request_model.dart
    repositories/
      firestore_workspace_join_repository.dart
  domain/
    entities/
      workspace_join_code.dart
      workspace_join_preview.dart
      workspace_join_request.dart
    repositories/
      workspace_join_repository.dart
  presentation/
    pages/
      guest_landing_page.dart
      join_requests_admin_page.dart
      join_with_code_page.dart
      join_workspace_preview_page.dart
      scan_join_qr_page.dart
    widgets/
      workspace_invite_panel.dart
```

## Security direction

- Guests never read `workspaces/{workspaceId}` directly.
- Guest join-code resolution happens against `join_code_lookup/{code_normalized}` with direct `get`, not a broad query.
- Admin code management still happens inside `workspaces/{workspaceId}/join_codes/{joinCodeId}`.
- Authenticated users can only create `join_requests/{theirUid}` for themselves.
- Users cannot create `members/{theirUid}` directly.
- Admin approval is the only supported path that creates membership, updates `member_ids`, updates `member_count`, and increments `used_count`.
- Join codes are not invite links. The QR currently carries a formatted payload like `NEXORA_JOIN:ABCD-EFGH-JKLM`.

## Practical trade-offs

- Because Spark + client-side Firestore is used without Cloud Functions, join code secrecy depends on code entropy and approval review, not on server-side token verification.
- `member_ids` remains denormalized for workspace list queries. The active member document is the real access gate in rules.
- Gallery QR import is intentionally deferred. Camera scanning ships first and the UI marks gallery support as a TODO.
- This design is ready to evolve later into QR links, deep links, and server-side validation without changing the main user flow.
