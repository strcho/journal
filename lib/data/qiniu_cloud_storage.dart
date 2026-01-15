import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'cloud_storage.dart';

class QiniuCloudStorage implements CloudStorage {
  QiniuCloudStorage({
    required this.uploadUrl,
    required this.downloadBaseUrl,
    required this.uploadTokenProvider,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  factory QiniuCloudStorage.fromEnvironment() {
    const uploadUrl = String.fromEnvironment(
      'QINIU_UPLOAD_URL',
      defaultValue: '',
    );
    const downloadBaseUrl = String.fromEnvironment(
      'QINIU_DOWNLOAD_BASE_URL',
      defaultValue: '',
    );

    return QiniuCloudStorage(
      uploadUrl: uploadUrl,
      downloadBaseUrl: downloadBaseUrl,
      uploadTokenProvider: (key) async => '',
    );
  }

  final String uploadUrl;
  final String downloadBaseUrl;
  final Future<String> Function(String key) uploadTokenProvider;
  final HttpClient _httpClient;

  @override
  bool get isConfigured =>
      uploadUrl.trim().isNotEmpty && downloadBaseUrl.trim().isNotEmpty;

  @override
  Future<CloudFile> uploadEncryptedBytes({
    required String key,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    if (!isConfigured) {
      throw StateError('QiniuCloudStorage is not configured.');
    }
    final token = (await uploadTokenProvider(key)).trim();
    if (token.isEmpty) {
      throw StateError('Qiniu upload token is empty.');
    }

    final boundary = '----my-day-one-${DateTime.now().millisecondsSinceEpoch}';
    final request = await _httpClient.postUrl(Uri.parse(uploadUrl));
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );

    _writeMultipartField(request, boundary, 'token', token);
    _writeMultipartField(request, boundary, 'key', key);
    _writeMultipartFile(
      request,
      boundary,
      name: 'file',
      filename: key,
      contentType: mimeType ?? 'application/octet-stream',
      bytes: bytes,
    );
    request.add(utf8.encode('--$boundary--\r\n'));

    final response = await request.close();
    final responseBody = await _readResponseBytes(response);
    if (response.statusCode != 200) {
      throw HttpException(
        'Qiniu upload failed: ${response.statusCode}',
        uri: Uri.parse(uploadUrl),
      );
    }
    // Best effort: consume response for connection reuse.
    if (responseBody.isNotEmpty) {
      // Intentionally ignored: Qiniu returns JSON metadata.
    }

    return CloudFile(
      key: key,
      url: _resolveDownloadUrl(key),
      sizeBytes: bytes.length,
      mimeType: mimeType,
    );
  }

  @override
  Future<Uint8List> downloadEncryptedBytes(String key) async {
    if (!isConfigured) {
      return Uint8List(0);
    }
    final url = _resolveDownloadUrl(key);
    final request = await _httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      return Uint8List(0);
    }
    return _readResponseBytes(response);
  }

  String _resolveDownloadUrl(String key) {
    final base = downloadBaseUrl.endsWith('/')
        ? downloadBaseUrl.substring(0, downloadBaseUrl.length - 1)
        : downloadBaseUrl;
    return '$base/$key';
  }

  void _writeMultipartField(
    HttpClientRequest request,
    String boundary,
    String name,
    String value,
  ) {
    request.add(utf8.encode('--$boundary\r\n'));
    request.add(
      utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'),
    );
    request.add(utf8.encode('$value\r\n'));
  }

  void _writeMultipartFile(
    HttpClientRequest request,
    String boundary, {
    required String name,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) {
    request.add(utf8.encode('--$boundary\r\n'));
    request.add(
      utf8.encode(
        'Content-Disposition: form-data; name="$name"; '
        'filename="$filename"\r\n',
      ),
    );
    request.add(utf8.encode('Content-Type: $contentType\r\n\r\n'));
    request.add(bytes);
    request.add(utf8.encode('\r\n'));
  }

  Future<Uint8List> _readResponseBytes(HttpClientResponse response) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
