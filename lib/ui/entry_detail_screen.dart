import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';

import '../data/entry.dart';
import '../data/entry_repository.dart';
import '../utils/quill_document.dart';
import 'entry_editor_screen.dart';
import 'quill_image_embed_builder.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({
    super.key,
    required this.repository,
    required this.entryId,
  });

  final EntryRepository repository;
  final int entryId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Entry?>(
      stream: repository.watchEntry(entryId),
      builder: (context, snapshot) {
        final entry = snapshot.data;
        if (entry == null || entry.deletedAt != null) {
          return const Scaffold(
            body: Center(child: Text('Entry not found.')),
          );
        }

        final controller = QuillController(
          document: quillDocumentFromJson(entry.contentDeltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
        controller.readOnly = true;

        final dateLabel = DateFormat('MMM d, yyyy • HH:mm')
            .format(entry.updatedAt);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Entry'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EntryEditorScreen(
                      repository: repository,
                      entryId: entry.id,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, entry),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                entry.title.trim().isEmpty ? 'Untitled' : entry.title.trim(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              QuillEditor.basic(
                controller: controller,
                config: QuillEditorConfig(
                  embedBuilders: [
                    EncryptedImageEmbedBuilder(repository),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Entry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This will remove the entry from your journal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await repository.softDeleteEntry(entry);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
