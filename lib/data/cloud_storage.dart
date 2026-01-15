import 'dart:typed_data';

class CloudFile {
  const CloudFile({
    required this.key,
    required this.url,
    required this.sizeBytes,
    this.mimeType,
  });

  final String key;
  final String url;
  final int sizeBytes;
  final String? mimeType;
}

abstract class CloudStorage {
  bool get isConfigured;

  Future<CloudFile> uploadEncryptedBytes({
    required String key,
    required Uint8List bytes,
    String? mimeType,
  });

  Future<Uint8List> downloadEncryptedBytes(String key);
}
