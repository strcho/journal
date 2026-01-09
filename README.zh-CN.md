# My Day One

[English](README.md) | [中文](README.zh-CN.md)

离线优先的个人日记应用（受 Day One 启发）。支持富文本编辑（Quill），本地加密存储，
图片以内嵌方式保存为加密附件，并为后续自建同步（last-write-wins）做了结构预留。

## 功能特性

- 使用 `flutter_quill` 的富文本编辑器
- Isar 离线存储
- 日记内容 AES-GCM 加密 + 附件加密存储
- 图片以内嵌附件 ID 形式存储（`att:<id>`）
- App 锁（生物识别或设备密码）与超时设置
- 旧版 `local:` 图片 embed 的迁移支持

## 技术栈

- Flutter + Dart
- Isar（本地数据库）
- flutter_quill（富文本编辑）
- flutter_secure_storage（密钥存储）
- local_auth（App 锁）

## 数据模型（本地 + 同步准备）

Entry（加密存储）：
- `uuid`（同步主键）
- `payloadEncrypted`（AES-GCM 密文）
- `payloadVersion`（格式版本）
- `attachmentIds`（附件 ID 列表）
- `createdAt`, `updatedAt`, `deletedAt`
- `isDirty`（本地变更标记）
- `serverRevision`（上次同步版本）

Payload 内容（在 `payloadEncrypted` 内）：
- `title`, `contentDeltaJson`, `plainText`, `mood`, `tags`

Attachment：
- `uuid`（同步主键）
- `localPath`（加密文件路径）
- `sha256`, `sizeBytes`, `mimeType`
- `createdAt`, `updatedAt`, `deletedAt`
- `isDirty`, `serverRevision`

## 同步 API（草案，自建）

所有请求使用 `Authorization: Bearer <accessToken>`。
服务器只存密文，冲突策略为 last-write-wins。

认证：

```http
POST /auth/login
```

请求：

```json
{ "email": "user@example.com", "password": "..." }
```

响应：

```json
{ "accessToken": "...", "refreshToken": "...", "deviceId": "..." }
```

拉取变更：

```http
GET /sync/changes?since=REV
```

响应：

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

推送变更：

```http
POST /sync/push
```

请求：

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

响应：

```json
{
  "accepted": ["uuid"],
  "conflicts": ["uuid"],
  "missingAttachments": ["att1"]
}
```

附件上传/下载：

```http
PUT /attachments/{id}
GET /attachments/{id}
```

请求体为密文（`application/octet-stream`）。

## 错误码（草案）

错误响应统一格式：

```json
{ "error": { "code": "STRING", "message": "Human readable message" } }
```

常见错误码：
- `AUTH_INVALID_CREDENTIALS` (401) 登录失败
- `AUTH_TOKEN_EXPIRED` (401) Access token 过期
- `AUTH_TOKEN_INVALID` (401) token 无效
- `AUTH_FORBIDDEN` (403) 无权限
- `SYNC_CONFLICT` (409) 服务端版本更新（last-write-wins）
- `SYNC_MISSING_ATTACHMENT` (409) 缺少附件内容
- `RESOURCE_NOT_FOUND` (404) 资源不存在
- `VALIDATION_ERROR` (400) 参数错误
- `RATE_LIMITED` (429) 请求过于频繁
- `SERVER_ERROR` (500) 服务端异常

## 鉴权刷新流程（草案）

Access token 短效，Refresh token 长效。

```http
POST /auth/refresh
```

请求：

```json
{ "refreshToken": "...", "deviceId": "..." }
```

响应：

```json
{ "accessToken": "...", "refreshToken": "..." }
```

若返回 `AUTH_TOKEN_INVALID`，客户端需重新登录。

## 版本迁移策略

- `payloadVersion` 表示内容格式版本，按版本顺序迁移
- 迁移流程必须幂等，可重复执行
- 大型迁移应分批处理，避免卡顿
- 对旧版本至少保留一个版本的兼容读取能力

## 项目结构

- `lib/` Dart 源码
  - `data/` Isar 模型、仓库、加密、附件存储
  - `ui/` 页面
  - `utils/` 工具与常量
- `test/` 测试

## 安装与运行

安装依赖：

```sh
flutter pub get
```

生成 Isar 代码：

```sh
dart run build_runner build
```

运行：

```sh
flutter run
```

## 测试与分析

```sh
flutter test
flutter analyze
```

## App 锁说明

- 使用设备生物识别或系统密码（`local_auth`）
- Android 使用 `FlutterFragmentActivity`，需生物识别权限
- iOS 需要 `NSFaceIDUsageDescription`
- 如果系统层关闭生物识别/密码，App 锁将失效
- 超时锁定仅对后台状态生效

## 加密说明

- Entry payload 写入 Isar 前进行加密
- 附件存储为加密文件 `attachments/<attachmentId>.enc`
- 密钥存储在安全存储中，若密钥丢失将无法解密

## 旧数据迁移

旧版 `local:` 图片 embed 会在启动时迁移到 `att:`，迁移状态
记录在安全存储中，仅执行一次。

## 未来同步（规划）

- 自建后端
- 基于 Entry/Attachment ID 同步
- 冲突策略 last-write-wins
- 服务端仅保存密文
