import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../data/entry.dart';
import '../data/entry_repository.dart';
import '../utils/attachment_embed.dart';
import '../utils/quill_document.dart';
import 'entry_rich_text_toolbar.dart';
import 'quill_image_embed_builder.dart';

class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({super.key, required this.repository, this.entryId});

  final EntryRepository repository;
  final int? entryId;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  late final Future<Entry> _entryFuture;
  QuillController? _quillController;
  Entry? _entry;
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entryFuture = _loadEntry();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  Future<Entry> _loadEntry() async {
    if (widget.entryId != null) {
      final entry = await widget.repository.getEntry(widget.entryId!);
      if (entry != null) {
        return entry;
      }
    }

    final now = DateTime.now();
    return Entry()
      ..uuid = const Uuid().v4()
      ..title = ''
      ..contentDeltaJson = ''
      ..plainText = ''
      ..payloadEncrypted = ''
      ..createdAt = now
      ..updatedAt = now;
  }

  void _initializeControllers(Entry entry) {
    if (_quillController != null) {
      return;
    }

    _entry = entry;
    _titleController.text = entry.title;
    _selectedDate ??= DateUtils.dateOnly(entry.createdAt);
    final document = quillDocumentFromJson(entry.contentDeltaJson);
    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _quillController!.readOnly = false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Entry>(
      future: _entryFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final entry = snapshot.data!;
        _initializeControllers(entry);
        final controller = _quillController!;
        final l10n = AppLocalizations.of(context)!;
        final isExisting = entry.id != 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(isExisting ? l10n.editEntryTitle : l10n.newEntryTitle),
            actions: [
              IconButton(
                onPressed: _isSaving ? null : _saveEntry,
                icon: const Icon(Icons.save),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: l10n.entryTitleLabel,
                      prefixIcon: const Icon(Icons.title_outlined),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: QuillEditor.basic(
                            controller: controller,
                            config: QuillEditorConfig(
                              embedBuilders: [
                                EncryptedImageEmbedBuilder(widget.repository),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : _pickDate,
                              icon: const Icon(Icons.event_outlined),
                              label: Text(_formatSelectedDate(context, l10n)),
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    EntryRichTextToolbar(
                      controller: controller,
                      l10n: l10n,
                      onInsertImages: _insertImages,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _insertImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) {
      return;
    }

    for (final image in images) {
      final bytes = await image.readAsBytes();
      final mimeType = _guessMimeType(image.path);
      final attachmentId = await widget.repository.saveAttachmentBytes(
        bytes,
        mimeType: mimeType,
      );
      _insertImageEmbed(attachmentId);
    }
  }

  String? _guessMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  void _insertImageEmbed(String attachmentId) {
    final controller = _quillController;
    if (controller == null) {
      return;
    }
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;
    controller.replaceText(
      index,
      length,
      BlockEmbed.image('$attachmentEmbedPrefix$attachmentId'),
      TextSelection.collapsed(offset: index + 1),
    );
  }

  Future<void> _saveEntry() async {
    final entry = _entry;
    final controller = _quillController;
    final selectedDate = _selectedDate;
    if (entry == null || controller == null || selectedDate == null) {
      return;
    }

    setState(() => _isSaving = true);
    final title = _titleController.text.trim();
    final deltaJson = jsonEncode(controller.document.toDelta().toJson());
    final plainText = controller.document
        .toPlainText()
        .replaceAll('\uFFFC', '')
        .trim();
    final attachments = _extractAttachmentIds(controller);

    await _deleteRemovedAttachments(entry.attachmentIds, attachments);

    entry
      ..title = title
      ..contentDeltaJson = deltaJson
      ..plainText = plainText
      ..attachmentIds = attachments
      ..createdAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        entry.createdAt.hour,
        entry.createdAt.minute,
        entry.createdAt.second,
        entry.createdAt.millisecond,
        entry.createdAt.microsecond,
      );

    await widget.repository.saveEntry(entry);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<String> _extractAttachmentIds(QuillController controller) {
    final ops = controller.document.toDelta().toJson();
    final paths = <String>[];
    final seen = <String>{};
    for (final op in ops.cast<Map<String, dynamic>>()) {
      final insert = op['insert'];
      if (insert is Map && insert['image'] is String) {
        final value = insert['image'] as String;
        if (value.startsWith(attachmentEmbedPrefix)) {
          final attachmentId = value.substring(attachmentEmbedPrefix.length);
          if (attachmentId.isNotEmpty && seen.add(attachmentId)) {
            paths.add(attachmentId);
          }
        }
      }
    }
    return paths;
  }

  Future<void> _deleteRemovedAttachments(
    List<String> existing,
    List<String> current,
  ) async {
    final currentSet = current.toSet();
    for (final attachmentId in existing) {
      if (!currentSet.contains(attachmentId)) {
        await widget.repository.deleteAttachment(attachmentId);
      }
    }
  }

  String _formatSelectedDate(BuildContext context, AppLocalizations l10n) {
    final selected = _selectedDate ?? DateTime.now();
    final formatter = DateFormat.yMMMd(l10n.localeName);
    final label = formatter.format(selected);
    if (DateUtils.isSameDay(selected, DateTime.now())) {
      return l10n.entryDateTodayLabel(label);
    }
    return label;
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: l10n.entryDatePickerHelp,
      cancelText: l10n.cancel,
      confirmText: l10n.ok,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(picked);
      });
    }
  }
}
