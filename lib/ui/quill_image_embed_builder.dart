import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../data/entry_repository.dart';
import '../utils/attachment_embed.dart';

class EncryptedImageEmbedBuilder extends EmbedBuilder {
  EncryptedImageEmbedBuilder(this.repository);

  final EntryRepository repository;

  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    final value = data is String ? data : '';
    if (value.isEmpty) {
      return _buildPlaceholder(context);
    }

    if (value.startsWith(attachmentEmbedPrefix)) {
      final attachmentId = value.substring(attachmentEmbedPrefix.length);
      return FutureBuilder<Uint8List>(
        future: repository.readAttachmentBytes(attachmentId),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            return _buildPlaceholder(context);
          }
          return _wrapImage(context, Image.memory(bytes, fit: BoxFit.cover));
        },
      );
    }

    if (value.startsWith(legacyLocalEmbedPrefix)) {
      final localPath = value.substring(legacyLocalEmbedPrefix.length);
      return FutureBuilder<Uint8List>(
        future: repository.readLegacyAttachmentBytesByPath(localPath),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            return _buildPlaceholder(context);
          }
          return _wrapImage(context, Image.memory(bytes, fit: BoxFit.cover));
        },
      );
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return FutureBuilder<Uint8List>(
        future: repository.readNetworkBytes(value),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            return _buildPlaceholder(context);
          }
          return _wrapImage(context, Image.memory(bytes, fit: BoxFit.cover));
        },
      );
    }

    return _buildPlaceholder(context);
  }

  @override
  String toPlainText(Embed node) => '[image]';

  Widget _wrapImage(BuildContext context, Widget image) {
    final maxWidth = MediaQuery.of(context).size.width - 32;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: image,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return _wrapImage(
      context,
      Container(
        height: 180,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}
