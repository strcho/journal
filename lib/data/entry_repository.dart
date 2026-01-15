import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import 'attachment.dart';
import 'attachment_store.dart';
import 'cloud_storage.dart';
import 'crypto_service.dart';
import 'entry.dart';
import 'entry_payload.dart';
import 'isar_service.dart';
import 'journal_api_client.dart';
import 'network_file_cache.dart';
import 'qiniu_cloud_storage.dart';
import '../utils/attachment_embed.dart';

class EntryRepository {
  EntryRepository._(
    this._isar,
    this._cryptoService,
    this._attachmentStore,
    this._cloudStorage,
    this._journalApiClient,
    this._networkFileCache,
  );

  final Isar _isar;
  final CryptoService _cryptoService;
  final AttachmentStore _attachmentStore;
  final CloudStorage _cloudStorage;
  final JournalApiClient _journalApiClient;
  final NetworkFileCache _networkFileCache;
  static const _storage = FlutterSecureStorage();
  static const _legacyMigrationKey = 'migration_local_embeds_v1';

  JournalApiClient get journalApiClient => _journalApiClient;

  static Future<EntryRepository> open({
    CloudStorage? cloudStorage,
    NetworkFileCache? networkFileCache,
    JournalApiClient? journalApiClient,
  }) async {
    final service = await IsarService.open();
    final crypto = await CryptoService.create();
    final repository = EntryRepository._(
      service.isar,
      crypto,
      AttachmentStore(crypto),
      cloudStorage ?? QiniuCloudStorage.fromEnvironment(),
      journalApiClient ?? JournalApiClient.fromConfig(),
      networkFileCache ?? NetworkFileCache(),
    );
    await repository._migrateLegacyLocalEmbeds();
    return repository;
  }

  Stream<List<Entry>> watchEntries({String? query}) {
    final baseStream = _isar.entrys
        .filter()
        .deletedAtIsNull()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
    return baseStream.asyncMap((entries) async {
      final hydrated = await Future.wait(entries.map(_hydrateEntry));
      final normalized = query?.trim().toLowerCase();
      if (normalized == null || normalized.isEmpty) {
        return hydrated;
      }
      return hydrated
          .where(
            (entry) =>
                entry.title.toLowerCase().contains(normalized) ||
                entry.plainText.toLowerCase().contains(normalized),
          )
          .toList();
    });
  }

  Stream<Entry?> watchEntry(Id id) {
    return _isar.entrys
        .watchObject(id, fireImmediately: true)
        .asyncMap(
          (entry) async => entry == null
              ? null
              : _hydrateEntry(entry, offloadJsonDecode: true),
        );
  }

  Future<Entry?> getEntry(Id id) async {
    final entry = await _isar.entrys.get(id);
    if (entry == null) {
      return null;
    }
    return _hydrateEntry(entry, offloadJsonDecode: true);
  }

  Future<void> saveEntry(Entry entry) async {
    final payload = EntryPayload(
      title: entry.title,
      contentDeltaJson: entry.contentDeltaJson,
      plainText: entry.plainText,
      mood: entry.mood,
      tags: entry.tags,
    );
    entry.payloadEncrypted = await _cryptoService.encryptString(
      jsonEncode(payload.toJson()),
    );
    entry.updatedAt = DateTime.now();
    entry.isDirty = true;
    await _isar.writeTxn(() async {
      await _isar.entrys.put(entry);
    });
  }

  Future<void> softDeleteEntry(Entry entry) async {
    entry.deletedAt = DateTime.now();
    entry.isDirty = true;
    await _isar.writeTxn(() async {
      await _isar.entrys.put(entry);
    });
  }

  Future<String> saveAttachmentBytes(
    Uint8List bytes, {
    String? mimeType,
  }) async {
    final attachmentId = const Uuid().v4();
    final encrypted = await _cryptoService.encryptBytes(bytes);
    final filePath =
        await _attachmentStore.saveEncryptedBytes(attachmentId, encrypted);
    final hash = await _cryptoService.sha256Hex(bytes);
    final now = DateTime.now();
    var uploadFailed = false;
    if (_cloudStorage.isConfigured) {
      try {
        await _cloudStorage.uploadEncryptedBytes(
          key: attachmentId,
          bytes: encrypted,
          mimeType: mimeType,
        );
      } catch (_) {
        uploadFailed = true;
      }
    } else {
      uploadFailed = true;
    }
    final attachment = Attachment()
      ..uuid = attachmentId
      ..localPath = filePath
      ..sha256 = hash
      ..sizeBytes = bytes.length
      ..mimeType = mimeType
      ..createdAt = now
      ..updatedAt = now
      ..isDirty = uploadFailed;
    await _isar.writeTxn(() async {
      await _isar.attachments.put(attachment);
    });
    return attachmentId;
  }

  Future<Uint8List> readAttachmentBytes(String attachmentId) async {
    final attachment = await _isar.attachments
        .filter()
        .uuidEqualTo(attachmentId)
        .findFirst();
    if (attachment == null || attachment.deletedAt != null) {
      return Uint8List(0);
    }
    final localPath = attachment.localPath;
    if (await _attachmentStore.exists(localPath)) {
      try {
        final cached = await _attachmentStore.readBytes(localPath);
        if (cached.isNotEmpty) {
          return cached;
        }
      } catch (_) {
        await _attachmentStore.delete(localPath);
      }
    }

    if (!_cloudStorage.isConfigured) {
      return Uint8List(0);
    }

    try {
      final encrypted = await _cloudStorage.downloadEncryptedBytes(
        attachment.uuid,
      );
      if (encrypted.isEmpty) {
        return Uint8List(0);
      }
      final cachedPath = await _attachmentStore.saveEncryptedBytes(
        attachment.uuid,
        encrypted,
      );
      if (cachedPath != attachment.localPath) {
        attachment
          ..localPath = cachedPath
          ..updatedAt = DateTime.now();
        await _isar.writeTxn(() async {
          await _isar.attachments.put(attachment);
        });
      }
      return _attachmentStore.readBytes(cachedPath);
    } catch (_) {
      return Uint8List(0);
    }
  }

  Future<Uint8List> readLegacyAttachmentBytesByPath(String localPath) {
    return _attachmentStore.readBytes(localPath);
  }

  Future<Uint8List> readNetworkBytes(String url) {
    return _networkFileCache.getBytes(url);
  }

  Future<void> deleteAttachment(String attachmentId) async {
    final attachment = await _isar.attachments
        .filter()
        .uuidEqualTo(attachmentId)
        .findFirst();
    if (attachment == null) {
      return;
    }
    await _attachmentStore.delete(attachment.localPath);
    await _isar.writeTxn(() async {
      await _isar.attachments.delete(attachment.id);
    });
  }

  Future<void> _migrateLegacyLocalEmbeds() async {
    final migrated = await _storage.read(key: _legacyMigrationKey);
    if (migrated == 'true') {
      return;
    }

    final entries = await _isar.entrys.where().findAll();
    if (entries.isEmpty) {
      await _storage.write(key: _legacyMigrationKey, value: 'true');
      return;
    }

    final existingAttachments = await _isar.attachments.where().findAll();
    final localPathToId = <String, String>{
      for (final attachment in existingAttachments)
        attachment.localPath: attachment.uuid,
    };

    for (final entry in entries) {
      if (entry.payloadEncrypted.isEmpty) {
        continue;
      }
      final payload = await _decryptPayload(entry.payloadEncrypted);
      if (payload == null) {
        continue;
      }

      final updated = await _updateDeltaForLegacyImages(
        payload.contentDeltaJson,
        localPathToId,
      );

      if (updated.changed) {
        final newPayload = EntryPayload(
          title: payload.title,
          contentDeltaJson: updated.deltaJson,
          plainText: payload.plainText,
          mood: payload.mood,
          tags: payload.tags,
        );
        entry.payloadEncrypted = await _cryptoService.encryptString(
          jsonEncode(newPayload.toJson()),
        );
      }

      final attachmentsChanged = !_listEquals(
        entry.attachmentIds,
        updated.attachmentIds,
      );
      if (attachmentsChanged) {
        entry.attachmentIds = updated.attachmentIds;
      }

      if (updated.changed || attachmentsChanged) {
        entry.isDirty = true;
        await _isar.writeTxn(() async {
          await _isar.entrys.put(entry);
        });
      }
    }

    await _storage.write(key: _legacyMigrationKey, value: 'true');
  }

  Future<EntryPayload?> _decryptPayload(String encrypted) async {
    try {
      final decrypted = await _cryptoService.decryptString(encrypted);
      final map = jsonDecode(decrypted) as Map<String, dynamic>;
      return EntryPayload.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<_LegacyDeltaUpdate> _updateDeltaForLegacyImages(
    String deltaJson,
    Map<String, String> localPathToId,
  ) async {
    final trimmed = deltaJson.trim();
    if (trimmed.isEmpty) {
      return _LegacyDeltaUpdate(deltaJson, const <String>[], false);
    }

    List<dynamic> ops;
    try {
      ops = jsonDecode(trimmed) as List<dynamic>;
    } catch (_) {
      return _LegacyDeltaUpdate(deltaJson, const <String>[], false);
    }

    bool changed = false;
    final attachmentIds = <String>{};
    for (final op in ops) {
      if (op is! Map<String, dynamic>) {
        continue;
      }
      final insert = op['insert'];
      if (insert is Map && insert['image'] is String) {
        final value = insert['image'] as String;
        if (value.startsWith(attachmentEmbedPrefix)) {
          attachmentIds.add(
            value.substring(attachmentEmbedPrefix.length),
          );
          continue;
        }

        if (value.startsWith(legacyLocalEmbedPrefix)) {
          final localPath = value.substring(legacyLocalEmbedPrefix.length);
          if (localPath.isEmpty) {
            continue;
          }
          final attachmentId = await _getOrCreateAttachmentId(
            localPath,
            localPathToId,
          );
          if (attachmentId == null) {
            continue;
          }
          insert['image'] = '$attachmentEmbedPrefix$attachmentId';
          attachmentIds.add(attachmentId);
          changed = true;
        }
      }
    }

    if (!changed) {
      return _LegacyDeltaUpdate(deltaJson, attachmentIds.toList(), false);
    }

    return _LegacyDeltaUpdate(
      jsonEncode(ops),
      attachmentIds.toList(),
      true,
    );
  }

  Future<String?> _getOrCreateAttachmentId(
    String localPath,
    Map<String, String> localPathToId,
  ) async {
    final cached = localPathToId[localPath];
    if (cached != null) {
      return cached;
    }

    final decrypted = await _attachmentStore.readBytes(localPath);
    if (decrypted.isEmpty) {
      return null;
    }

    final attachmentId = const Uuid().v4();
    final hash = await _cryptoService.sha256Hex(decrypted);
    final newPath =
        await _attachmentStore.moveToAttachmentId(localPath, attachmentId);
    final now = DateTime.now();
    final attachment = Attachment()
      ..uuid = attachmentId
      ..localPath = newPath
      ..sha256 = hash
      ..sizeBytes = decrypted.length
      ..mimeType = _guessMimeType(localPath)
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.attachments.put(attachment);
    });
    localPathToId[localPath] = attachmentId;
    return attachmentId;
  }

  String? _guessMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    return listEquals(a, b);
  }

  Future<Entry> _hydrateEntry(
    Entry entry, {
    bool offloadJsonDecode = false,
  }) async {
    if (entry.payloadEncrypted.isEmpty) {
      entry
        ..title = ''
        ..contentDeltaJson = ''
        ..plainText = '';
      return entry;
    }

    try {
      final decrypted = await _cryptoService.decryptString(
        entry.payloadEncrypted,
      );
      final map = await _decodeJsonMap(
        decrypted,
        offload: offloadJsonDecode,
      );
      final payload = EntryPayload.fromJson(map);
      entry
        ..title = payload.title
        ..contentDeltaJson = payload.contentDeltaJson
        ..plainText = payload.plainText
        ..mood = payload.mood
        ..tags = List<String>.from(payload.tags);
    } catch (_) {
      entry
        ..title = ''
        ..contentDeltaJson = ''
        ..plainText = ''
        ..mood = null
        ..tags = [];
    }

    return entry;
  }
}

Future<Map<String, dynamic>> _decodeJsonMap(
  String json, {
  required bool offload,
}) async {
  // Avoid isolate overhead for smaller payloads.
  const offloadThresholdChars = 20000;
  if (!offload || json.length < offloadThresholdChars) {
    return jsonDecode(json) as Map<String, dynamic>;
  }
  return compute(_jsonDecodeToMap, json);
}

Map<String, dynamic> _jsonDecodeToMap(String json) {
  return jsonDecode(json) as Map<String, dynamic>;
}

class _LegacyDeltaUpdate {
  _LegacyDeltaUpdate(this.deltaJson, this.attachmentIds, this.changed);

  final String deltaJson;
  final List<String> attachmentIds;
  final bool changed;
}
