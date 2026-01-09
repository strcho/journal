# My Day One

Offline-first personal journal app inspired by Day One. Entries use a rich
text editor (Quill), are encrypted locally, and support embedded images with
encrypted attachment storage. Designed for future self-hosted sync with
last-write-wins conflict resolution.

## Features

- Rich text editor using `flutter_quill`
- Offline storage with Isar
- Entry payload encryption (AES-GCM) + encrypted attachments
- Embedded images stored as attachment IDs (`att:<id>`)
- App lock (biometrics or device passcode) with configurable timeout
- Legacy migration for old `local:` image embeds

## Tech Stack

- Flutter + Dart
- Isar (local database)
- flutter_quill (rich text editor)
- flutter_secure_storage (key storage)
- local_auth (app lock)

## Data Model (Local + Sync-Ready)

Entry (stored encrypted):
- `uuid` (String, primary ID for sync)
- `payloadEncrypted` (String, AES-GCM ciphertext)
- `payloadVersion` (int, format version)
- `attachmentIds` (List<String>)
- `createdAt`, `updatedAt`, `deletedAt` (DateTime)
- `isDirty` (bool, local changes)
- `serverRevision` (int?, last synced revision)

Payload contents (inside `payloadEncrypted`):
- `title`, `contentDeltaJson`, `plainText`, `mood`, `tags`

Attachment:
- `uuid` (String, primary ID for sync)
- `localPath` (String, encrypted file path)
- `sha256`, `sizeBytes`, `mimeType`
- `createdAt`, `updatedAt`, `deletedAt`
- `isDirty`, `serverRevision`

## Sync API (Draft, Self-Hosted)

All requests use `Authorization: Bearer <accessToken>`.
Server stores ciphertext only. Conflict strategy: last-write-wins.

Auth:

```http
POST /auth/login
```

Request:

```json
{ "email": "user@example.com", "password": "..." }
```

Response:

```json
{ "accessToken": "...", "refreshToken": "...", "deviceId": "..." }
```

Changes pull:

```http
GET /sync/changes?since=REV
```

Response:

```json
{
  "latestRevision": 120,
  "entries": [
    {
      "id": "uuid",
      "payloadEncrypted": "...",
      "payloadVersion": 1,
      "attachmentIds": ["att1", "att2"],
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-02T00:00:00Z",
      "deletedAt": null,
      "revision": 120
    }
  ],
  "attachments": [
    {
      "id": "att1",
      "sha256": "...",
      "sizeBytes": 12345,
      "mimeType": "image/jpeg",
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-02T00:00:00Z",
      "deletedAt": null,
      "revision": 120
    }
  ]
}
```

Changes push:

```http
POST /sync/push
```

Request:

```json
{
  "entries": [
    {
      "id": "uuid",
      "payloadEncrypted": "...",
      "payloadVersion": 1,
      "attachmentIds": ["att1"],
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-02T00:00:00Z",
      "deletedAt": null,
      "revision": 118
    }
  ],
  "attachmentsMeta": [
    {
      "id": "att1",
      "sha256": "...",
      "sizeBytes": 12345,
      "mimeType": "image/jpeg",
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-02T00:00:00Z",
      "deletedAt": null,
      "revision": 118
    }
  ]
}
```

Response:

```json
{
  "accepted": ["uuid"],
  "conflicts": ["uuid"],
  "missingAttachments": ["att1"]
}
```

Attachment upload/download:

```http
PUT /attachments/{id}
GET /attachments/{id}
```

Body is raw ciphertext (`application/octet-stream`).

## Error Codes (Draft)

All error responses use:

```json
{ "error": { "code": "STRING", "message": "Human readable message" } }
```

Common codes:
- `AUTH_INVALID_CREDENTIALS` (401) Login failed
- `AUTH_TOKEN_EXPIRED` (401) Access token expired
- `AUTH_TOKEN_INVALID` (401) Invalid token
- `AUTH_FORBIDDEN` (403) Not allowed
- `SYNC_CONFLICT` (409) Server has newer revision (last-write-wins)
- `SYNC_MISSING_ATTACHMENT` (409) Missing attachment content
- `RESOURCE_NOT_FOUND` (404) Entry/attachment not found
- `VALIDATION_ERROR` (400) Invalid payload
- `RATE_LIMITED` (429) Too many requests
- `SERVER_ERROR` (500) Unexpected server error

## Auth Refresh Flow (Draft)

Access tokens are short-lived. Refresh tokens are long-lived.

```http
POST /auth/refresh
```

Request:

```json
{ "refreshToken": "...", "deviceId": "..." }
```

Response:

```json
{ "accessToken": "...", "refreshToken": "..." }
```

If refresh fails with `AUTH_TOKEN_INVALID`, force re-login.

## Version Migration Strategy

The client stores data format versions and applies migrations in order:

- `payloadVersion` in Entry payload determines how to decode/transform content
- App upgrade runs idempotent migrations (tracked via secure storage flags)
- For data-breaking changes, create a new versioned payload and re-encrypt

Guidelines:
- Always keep previous versions readable for at least one app version
- Migrations must be safe to re-run and should never drop data silently
- For large migrations, perform in small batches to avoid UI jank

## Project Structure

- `lib/` Dart source
  - `data/` Isar models, repository, encryption, attachment store
  - `ui/` Screens and widgets
  - `utils/` Embed constants and helpers
- `test/` Flutter tests

## Setup

Install dependencies:

```sh
flutter pub get
```

Generate Isar models:

```sh
dart run build_runner build
```

## Run

```sh
flutter run
```

## Test and Analyze

```sh
flutter test
flutter analyze
```

## App Lock Notes

- Uses device biometrics or passcode via `local_auth`
- Android uses `FlutterFragmentActivity` and requires biometric permissions
- iOS uses Face ID/Touch ID with `NSFaceIDUsageDescription` set
- If device security is disabled, app lock will not work
- Lock timeout only applies when the app is in the background

## Encryption Notes

- Entry payloads are encrypted before being stored in Isar
- Attachments are stored as encrypted files under app documents
  (`attachments/<attachmentId>.enc`)
- Encryption key is stored in secure storage; if the key is lost, data cannot
  be decrypted

## Legacy Migration

Older entries using `local:` image embeds are migrated to `att:` embeds on
startup. The migration runs once and is tracked via secure storage.

## Future Sync (Planned)

- Self-hosted backend
- Sync by entry/attachment IDs with last-write-wins conflict resolution
- Server stores ciphertext only
