import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';

Document quillDocumentFromJson(String json) {
  final normalized = json.trim();
  if (normalized.isEmpty) {
    return Document();
  }

  try {
    final data = jsonDecode(normalized);
    if (data is List) {
      return Document.fromJson(data);
    }
  } catch (_) {
    // Fall through to an empty document.
  }

  return Document();
}

Future<Document> quillDocumentFromJsonAsync(String json) async {
  final normalized = json.trim();
  if (normalized.isEmpty) {
    return Document();
  }

  // For small payloads the isolate spin-up cost can outweigh the benefit.
  const offloadThresholdChars = 5000;
  if (normalized.length < offloadThresholdChars) {
    return quillDocumentFromJson(normalized);
  }

  final ops = await compute(_decodeQuillOps, normalized);
  if (ops == null) {
    return Document();
  }
  return Document.fromJson(ops);
}

List<dynamic>? _decodeQuillOps(String json) {
  try {
    final data = jsonDecode(json);
    if (data is List) {
      return data;
    }
  } catch (_) {
    // Fall through to null.
  }
  return null;
}
