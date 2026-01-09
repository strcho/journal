import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
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
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            body: Center(child: Text(l10n.entryNotFound)),
          );
        }

        final controller = QuillController(
          document: quillDocumentFromJson(entry.contentDeltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
        controller.readOnly = true;

        final l10n = AppLocalizations.of(context)!;
        final dateLabel = DateFormat.yMMMd(l10n.localeName)
            .add_Hm()
            .format(entry.updatedAt);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.entryDetailTitle),
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
                entry.title.trim().isEmpty
                    ? l10n.untitled
                    : entry.title.trim(),
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
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deleteEntryTitle),
          content: Text(l10n.deleteEntryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
        );
      },
    );

    if (result == true) {
      await repository.softDeleteEntry(entry);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
