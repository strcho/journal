import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class NetworkFileCache {
  NetworkFileCache({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;
  Directory? _cachedDirectory;

  Future<Uint8List> getBytes(String url) async {
    if (url.trim().isEmpty) {
      return Uint8List(0);
    }

    final directory = await _cacheDirectory();
    final key = await _hashUrl(url);
    final filePath = path.join(directory.path, '$key.cache');
    final file = File(filePath);
    if (await file.exists()) {
      return file.readAsBytes();
    }

    final bytes = await _downloadBytes(url);
    if (bytes.isEmpty) {
      return Uint8List(0);
    }
    await file.writeAsBytes(bytes, flush: true);
    return bytes;
  }

  Future<Directory> _cacheDirectory() async {
    if (_cachedDirectory != null) {
      return _cachedDirectory!;
    }
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory(path.join(base.path, 'network_cache'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _cachedDirectory = directory;
    return directory;
  }

  Future<String> _hashUrl(String url) async {
    final hash = await Sha256().hash(utf8.encode(url));
    final buffer = StringBuffer();
    for (final byte in hash.bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  Future<Uint8List> _downloadBytes(String url) async {
    try {
      final request = await _httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        return Uint8List(0);
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } catch (_) {
      return Uint8List(0);
    }
  }
}
