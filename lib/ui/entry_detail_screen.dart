import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';

import '../data/entry.dart';
import '../data/entry_repository.dart';
import '../utils/quill_document.dart';
import 'entry_editor_screen.dart';
import 'quill_image_embed_builder.dart';

class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({
    super.key,
    required this.repository,
    required this.entryId,
  });

  final EntryRepository repository;
  final int entryId;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<Entry?>(
      stream: widget.repository.watchEntry(widget.entryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text(l10n.entryLoadError)));
        }

        final entry = snapshot.data;
        if (entry == null || entry.deletedAt != null) {
          return Scaffold(body: Center(child: Text(l10n.entryNotFound)));
        }
        final dateLabel = DateFormat.yMMMd(
          l10n.localeName,
        ).add_Hm().format(entry.createdAt);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.entryDetailTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EntryEditorScreen(
                      repository: widget.repository,
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
                entry.title.trim().isEmpty ? l10n.untitled : entry.title.trim(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              _EntryContent(
                repository: widget.repository,
                contentDeltaJson: entry.contentDeltaJson,
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
      await widget.repository.softDeleteEntry(entry);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _EntryContent extends StatefulWidget {
  const _EntryContent({
    required this.repository,
    required this.contentDeltaJson,
  });

  final EntryRepository repository;
  final String contentDeltaJson;

  @override
  State<_EntryContent> createState() => _EntryContentState();
}

class _EntryContentState extends State<_EntryContent> {
  QuillController? _controller;
  Object? _loadError;
  bool _isLoading = true;
  late String _lastContentDeltaJson;

  @override
  void initState() {
    super.initState();
    _lastContentDeltaJson = widget.contentDeltaJson;
    _loadController(widget.contentDeltaJson);
  }

  @override
  void didUpdateWidget(covariant _EntryContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentDeltaJson != _lastContentDeltaJson) {
      _lastContentDeltaJson = widget.contentDeltaJson;
      _loadController(widget.contentDeltaJson);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadController(String contentDeltaJson) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final document = await quillDocumentFromJsonAsync(contentDeltaJson);
      if (!mounted) {
        return;
      }
      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      )..readOnly = true;
      _controller?.dispose();
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _controller?.dispose();
        _controller = null;
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_loadError != null || _controller == null) {
      return Text(
        AppLocalizations.of(context)!.noContent,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return QuillEditor.basic(
      controller: _controller!,
      config: QuillEditorConfig(
        embedBuilders: [EncryptedImageEmbedBuilder(widget.repository)],
      ),
    );
  }
}
