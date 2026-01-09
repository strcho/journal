import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'crypto_service.dart';

class AttachmentStore {
  AttachmentStore(this._cryptoService);

  final CryptoService _cryptoService;
  Directory? _cachedDirectory;

  Future<String> saveBytes(String attachmentId, Uint8List bytes) async {
    final encrypted = await _cryptoService.encryptBytes(bytes);
    final directory = await _attachmentsDirectory();
    final filename = '$attachmentId.enc';
    final filePath = path.join(directory.path, filename);
    final file = File(filePath);
    await file.writeAsBytes(encrypted, flush: true);
    return filePath;
  }

  Future<Uint8List> readBytes(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return Uint8List(0);
    }
    final encrypted = await file.readAsBytes();
    return _cryptoService.decryptBytes(encrypted);
  }

  Future<void> delete(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> moveToAttachmentId(
    String existingPath,
    String attachmentId,
  ) async {
    final directory = await _attachmentsDirectory();
    final newPath = path.join(directory.path, '$attachmentId.enc');
    if (existingPath == newPath) {
      return existingPath;
    }

    final file = File(existingPath);
    if (!await file.exists()) {
      return existingPath;
    }

    try {
      await file.rename(newPath);
      return newPath;
    } catch (_) {
      final bytes = await file.readAsBytes();
      await File(newPath).writeAsBytes(bytes, flush: true);
      await file.delete();
      return newPath;
    }
  }

  Future<Directory> _attachmentsDirectory() async {
    if (_cachedDirectory != null) {
      return _cachedDirectory!;
    }
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory(path.join(base.path, 'attachments'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _cachedDirectory = directory;
    return directory;
  }
}
