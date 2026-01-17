import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../config/local_config.dart';
import 'attachment.dart';
import 'entry.dart';
import 'journal.dart';

class JournalApiClient {
  JournalApiClient({required this.baseUrl, HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  factory JournalApiClient.fromConfig() {
    return JournalApiClient(baseUrl: LocalConfig.journalApiBaseUrl);
  }

  final String baseUrl;
  final HttpClient _httpClient;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final payload = <String, dynamic>{'email': email, 'password': password};
    final json = await _postJson('/auth/login', payload);
    return AuthTokens.fromJson(json);
  }

  Future<AuthTokens> refresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    final payload = <String, dynamic>{
      'refreshToken': refreshToken,
      'deviceId': deviceId,
    };
    final json = await _postJson('/auth/refresh', payload);
    return AuthTokens.fromJson(json);
  }

  Future<SyncChangesResponse> fetchChanges({
    required String accessToken,
    int? since,
  }) async {
    final query = <String, String>{};
    if (since != null) {
      query['since'] = since.toString();
    }
    final json = await _getJson(
      '/sync/changes',
      accessToken: accessToken,
      query: query.isEmpty ? null : query,
    );
    return SyncChangesResponse.fromJson(json);
  }

  Future<PushResponse> pushChanges({
    required String accessToken,
    List<EntryChange> entries = const <EntryChange>[],
    List<AttachmentMeta> attachmentsMeta = const <AttachmentMeta>[],
    List<JournalChange> journals = const <JournalChange>[],
  }) async {
    final payload = <String, dynamic>{
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'attachmentsMeta': attachmentsMeta.map((meta) => meta.toJson()).toList(),
      'journals': journals.map((journal) => journal.toJson()).toList(),
    };
    final json = await _postJson(
      '/sync/push',
      payload,
      accessToken: accessToken,
    );
    return PushResponse.fromJson(json);
  }

  Future<Journal> fetchJournals({required String accessToken}) async {
    final json = await _getJson('/journals', accessToken: accessToken);
    final journalsList = (json['journals'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map(Journal.fromJson)
        .toList();
    if (journalsList == null || journalsList.isEmpty) {
      final defaultJournal = Journal()
        ..uuid = '00000000-0000-0000-0000-000000000001'
        ..name = '日常'
        ..color = '#4285F4'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..isDirty = false;
      return defaultJournal;
    }
    return journalsList.first;
  }

  Future<Journal> createJournal({
    required String accessToken,
    required String name,
    String? color,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      if (color != null) 'color': color,
    };
    final json = await _postJson(
      '/journals',
      payload,
      accessToken: accessToken,
    );
    return Journal.fromJson(json);
  }

  Future<Journal> updateJournal({
    required String accessToken,
    required String id,
    String? name,
    String? color,
  }) async {
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    };
    final json = await _postJson(
      '/journals/$id',
      payload,
      accessToken: accessToken,
    );
    return Journal.fromJson(json);
  }

  Future<void> deleteJournal({
    required String accessToken,
    required String id,
  }) async {
    await _postJson(
      '/journals/$id',
      <String, dynamic>{},
      accessToken: accessToken,
    );
  }

  Future<String> getQiniuUploadToken({
    required String accessToken,
    required String key,
  }) async {
    final query = <String, String>{'key': key};
    final json = await _getJson(
      '/storage/qiniu/token',
      accessToken: accessToken,
      query: query,
    );
    return json['uploadToken'] as String? ?? '';
  }

  Future<void> uploadAttachment({
    required String accessToken,
    required String attachmentId,
    required Uint8List bytes,
  }) async {
    final uri = _resolveUri('/attachments/$attachmentId');
    final request = await _httpClient.putUrl(uri);
    _applyAuth(request, accessToken);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/octet-stream',
    );
    request.add(bytes);
    final response = await request.close();
    await _consumeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw await ApiException.fromResponse(response);
    }
  }

  Future<Uint8List> downloadAttachment({
    required String accessToken,
    required String attachmentId,
  }) async {
    final uri = _resolveUri('/attachments/$attachmentId');
    final request = await _httpClient.getUrl(uri);
    _applyAuth(request, accessToken);
    final response = await request.close();
    final bytes = await _readResponseBytes(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromBytes(
        statusCode: response.statusCode,
        uri: uri,
        bodyBytes: bytes,
      );
    }
    return bytes;
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    required String accessToken,
    Map<String, String>? query,
  }) async {
    final uri = _resolveUri(path, query: query);
    final request = await _httpClient.getUrl(uri);
    _applyAuth(request, accessToken);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await _readResponseBytes(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromBytes(
        statusCode: response.statusCode,
        uri: uri,
        bodyBytes: body,
      );
    }
    return _decodeJsonObject(body, uri: uri);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload, {
    String? accessToken,
  }) async {
    final uri = _resolveUri(path);
    final request = await _httpClient.postUrl(uri);
    if (accessToken != null) {
      _applyAuth(request, accessToken);
    }
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.add(utf8.encode(jsonEncode(payload)));
    final response = await request.close();
    final body = await _readResponseBytes(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromBytes(
        statusCode: response.statusCode,
        uri: uri,
        bodyBytes: body,
      );
    }
    return _decodeJsonObject(body, uri: uri);
  }

  Uri _resolveUri(String path, {Map<String, String>? query}) {
    final base = Uri.parse(baseUrl);
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    final resolved = base.resolve(normalized);
    if (query == null || query.isEmpty) {
      return resolved;
    }
    return resolved.replace(queryParameters: query);
  }

  void _applyAuth(HttpClientRequest request, String accessToken) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
  }

  Future<void> _consumeResponse(HttpClientResponse response) async {
    await _readResponseBytes(response);
  }

  Map<String, dynamic> _decodeJsonObject(Uint8List bytes, {required Uri uri}) {
    if (bytes.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException(
      statusCode: 500,
      uri: uri,
      message: 'Unexpected response payload.',
    );
  }

  Future<Uint8List> _readResponseBytes(HttpClientResponse response) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  void close() {
    _httpClient.close(force: false);
  }
}

class AuthTokens {
  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.deviceId,
  });

  final String accessToken;
  final String refreshToken;
  final String deviceId;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
    );
  }
}

class EntryChange {
  EntryChange({
    required this.id,
    required this.journalId,
    required this.payloadEncrypted,
    required this.payloadVersion,
    required this.attachmentIds,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.revision,
  });

  final String id;
  final String journalId;
  final String payloadEncrypted;
  final int payloadVersion;
  final List<String> attachmentIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int? revision;

  factory EntryChange.fromEntry(Entry entry) {
    return EntryChange(
      id: entry.uuid,
      journalId: entry.journalId,
      payloadEncrypted: entry.payloadEncrypted,
      payloadVersion: entry.payloadVersion,
      attachmentIds: List<String>.from(entry.attachmentIds),
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      deletedAt: entry.deletedAt,
      revision: entry.serverRevision,
    );
  }

  factory EntryChange.fromJson(Map<String, dynamic> json) {
    return EntryChange(
      id: json['id'] as String? ?? '',
      journalId: json['journalId'] as String? ?? '',
      payloadEncrypted: json['payloadEncrypted'] as String? ?? '',
      payloadVersion: (json['payloadVersion'] as num?)?.toInt() ?? 1,
      attachmentIds:
          (json['attachmentIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      revision: (json['revision'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'journalId': journalId,
    'payloadEncrypted': payloadEncrypted,
    'payloadVersion': payloadVersion,
    'attachmentIds': attachmentIds,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'revision': revision,
  };
}

class AttachmentMeta {
  AttachmentMeta({
    required this.id,
    required this.sha256,
    required this.sizeBytes,
    required this.mimeType,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.revision,
  });

  final String id;
  final String sha256;
  final int sizeBytes;
  final String mimeType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int? revision;

  factory AttachmentMeta.fromAttachment(Attachment attachment) {
    return AttachmentMeta(
      id: attachment.uuid,
      sha256: attachment.sha256,
      sizeBytes: attachment.sizeBytes,
      mimeType: attachment.mimeType ?? 'application/octet-stream',
      createdAt: attachment.createdAt,
      updatedAt: attachment.updatedAt,
      deletedAt: attachment.deletedAt,
      revision: attachment.serverRevision,
    );
  }

  factory AttachmentMeta.fromJson(Map<String, dynamic> json) {
    return AttachmentMeta(
      id: json['id'] as String? ?? '',
      sha256: json['sha256'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      revision: (json['revision'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'sha256': sha256,
    'sizeBytes': sizeBytes,
    'mimeType': mimeType,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'revision': revision,
  };
}

class SyncChangesResponse {
  SyncChangesResponse({
    required this.latestRevision,
    required this.entries,
    required this.attachments,
    required this.journals,
  });

  final int latestRevision;
  final List<EntryChange> entries;
  final List<AttachmentMeta> attachments;
  final List<JournalChange> journals;

  factory SyncChangesResponse.fromJson(Map<String, dynamic> json) {
    return SyncChangesResponse(
      latestRevision: (json['latestRevision'] as num?)?.toInt() ?? 0,
      entries:
          (json['entries'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(EntryChange.fromJson)
              .toList() ??
          const <EntryChange>[],
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(AttachmentMeta.fromJson)
              .toList() ??
          const <AttachmentMeta>[],
      journals:
          (json['journals'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(JournalChange.fromJson)
              .toList() ??
          const <JournalChange>[],
    );
  }
}

class JournalChange {
  JournalChange({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.revision,
  });

  final String id;
  final String name;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int? revision;

  factory JournalChange.fromJournal(Journal journal) {
    return JournalChange(
      id: journal.uuid,
      name: journal.name,
      color: journal.color ?? '#000000',
      createdAt: journal.createdAt,
      updatedAt: journal.updatedAt,
      deletedAt: journal.deletedAt,
      revision: journal.serverRevision,
    );
  }

  factory JournalChange.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['createdAt'] as String?;
    final updatedAtStr = json['updatedAt'] as String?;
    final deletedAtStr = json['deletedAt'] as String?;

    return JournalChange(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as String? ?? '#000000',
      createdAt: createdAtStr != null
          ? DateTime.parse(createdAtStr)
          : DateTime.now(),
      updatedAt: updatedAtStr != null
          ? DateTime.parse(updatedAtStr)
          : DateTime.now(),
      deletedAt: deletedAtStr != null ? DateTime.parse(deletedAtStr) : null,
      revision: (json['revision'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'color': color,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
    'revision': revision,
  };
}

class PushResponse {
  PushResponse({
    required this.accepted,
    required this.conflicts,
    required this.missingAttachments,
  });

  final List<String> accepted;
  final List<String> conflicts;
  final List<String> missingAttachments;

  factory PushResponse.fromJson(Map<String, dynamic> json) {
    return PushResponse(
      accepted:
          (json['accepted'] as List<dynamic>?)?.whereType<String>().toList() ??
          const <String>[],
      conflicts:
          (json['conflicts'] as List<dynamic>?)?.whereType<String>().toList() ??
          const <String>[],
      missingAttachments:
          (json['missingAttachments'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
    );
  }
}

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.uri,
    this.code,
    this.message,
    this.body,
  });

  final int statusCode;
  final Uri uri;
  final String? code;
  final String? message;
  final String? body;

  static Future<ApiException> fromResponse(HttpClientResponse response) async {
    final bytes = await _readResponseBytesStatic(response);
    return ApiException.fromBytes(
      statusCode: response.statusCode,
      uri: Uri(),
      bodyBytes: bytes,
    );
  }

  static ApiException fromBytes({
    required int statusCode,
    required Uri uri,
    required Uint8List bodyBytes,
  }) {
    final body = bodyBytes.isEmpty ? null : utf8.decode(bodyBytes);
    String? code;
    String? message;
    if (body != null && body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final error = decoded['error'];
          if (error is Map<String, dynamic>) {
            code = error['code'] as String?;
            message = error['message'] as String?;
          }
        }
      } catch (_) {}
    }
    return ApiException(
      statusCode: statusCode,
      uri: uri,
      code: code,
      message: message,
      body: body,
    );
  }

  @override
  String toString() {
    final detail = message ?? body ?? 'HTTP $statusCode';
    return 'ApiException($statusCode): $detail';
  }

  static Future<Uint8List> _readResponseBytesStatic(
    HttpClientResponse response,
  ) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
