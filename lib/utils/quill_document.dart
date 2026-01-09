import 'dart:convert';

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
