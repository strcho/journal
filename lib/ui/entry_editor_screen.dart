import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../data/checklist_item.dart';
import '../data/entry.dart';
import '../data/entry_repository.dart';
import '../data/journal_repository.dart';
import '../services/location_service.dart';
import '../utils/attachment_embed.dart';
import '../utils/quill_document.dart';
import 'entry_rich_text_toolbar.dart';
import 'quill_image_embed_builder.dart';
import 'widgets/checklist_widget.dart';
import 'widgets/journal_selector.dart';

class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({
    super.key,
    required this.repository,
    required this.journalRepository,
    this.entryId,
  });

  final EntryRepository repository;
  final JournalRepository journalRepository;
  final int? entryId;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  late final Future<Entry> _entryFuture;
  QuillController? _quillController;
  Entry? _entry;
  DateTime? _selectedDate;
  String _journalId = '';
  bool _isSaving = false;
  String _entryType = 'diary';
  List<ChecklistItem> _checklist = [];
  bool _showChecklist = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _entryFuture = _loadEntry();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
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
      ..journalId = '00000000-0000-0000-0000-000000000001'
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
    _locationController.text = entry.location ?? '';
    _journalId = entry.journalId;
    _entryType = entry.entryType;
    _checklist = entry.checklist;
    _showChecklist = _checklist.isNotEmpty;
    _latitude = entry.latitude;
    _longitude = entry.longitude;
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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: JournalSelector(
                          journalRepository: widget.journalRepository,
                          selectedJournalId: _journalId,
                          onChanged: (value) =>
                              setState(() => _journalId = value),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            DropdownButton<String>(
                              value: _entryType,
                              items: const [
                                DropdownMenuItem(
                                  value: 'diary',
                                  child: Text('日记'),
                                ),
                                DropdownMenuItem(
                                  value: 'note',
                                  child: Text('笔记'),
                                ),
                                DropdownMenuItem(
                                  value: 'todo',
                                  child: Text('待办'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _entryType = value);
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  hintText: '地点（可选）',
                                  prefixIcon: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: _isSaving
                                            ? null
                                            : _getCurrentLocation,
                                        icon: const Icon(Icons.my_location),
                                        tooltip: '获取当前位置',
                                      ),
                                      IconButton(
                                        onPressed: _isSaving
                                            ? null
                                            : _showLocationSearch,
                                        icon: const Icon(Icons.search),
                                        tooltip: '搜索地点',
                                      ),
                                    ],
                                  ),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showChecklist)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: ChecklistWidget(
                            items: _checklist,
                            onItemToggle: (id) {
                              setState(() {
                                _checklist = _checklist.map((item) {
                                  if (item.id == id) {
                                    return item.copyWith(
                                      isCompleted: !item.isCompleted,
                                    );
                                  }
                                  return item;
                                }).toList();
                              });
                            },
                            onItemAdd: (text) {
                              setState(() {
                                _checklist.add(
                                  ChecklistItem(
                                    id: const Uuid().v4(),
                                    text: text,
                                    position: _checklist.length,
                                  ),
                                );
                              });
                            },
                            onItemDelete: (id) {
                              setState(() {
                                _checklist = _checklist
                                    .where((e) => e.id != id)
                                    .toList();
                              });
                            },
                            onItemEdit: (id, newText) {
                              setState(() {
                                _checklist = _checklist.map((item) {
                                  if (item.id == id) {
                                    return item.copyWith(text: newText);
                                  }
                                  return item;
                                }).toList();
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
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
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _isSaving
                                ? null
                                : () => setState(
                                    () => _showChecklist = !_showChecklist,
                                  ),
                            icon: Icon(
                              _showChecklist
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: _showChecklist
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            tooltip: '待办事项',
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
      ..journalId = _journalId
      ..title = title
      ..contentDeltaJson = deltaJson
      ..plainText = plainText
      ..attachmentIds = attachments
      ..entryType = _entryType
      ..location = _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim()
      ..checklist = _checklist
      ..latitude = _latitude
      ..longitude = _longitude
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

  Future<void> _getCurrentLocation() async {
    final context = this.context;
    setState(() => _isSaving = true);
    try {
      final location = await LocationService.instance.getCurrentLocation();
      if (location != null) {
        setState(() {
          _latitude = location.latitude;
          _longitude = location.longitude;
          _locationController.text =
              location.address ??
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('获取位置失败，请重试')));
      }
    } finally {
      if (context.mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showLocationSearch() {
    final controller = TextEditingController(text: _locationController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索地点'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '输入地点名称搜索...',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _performSearch(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => _performSearch(context, controller.text),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSearch(BuildContext context, String query) async {
    Navigator.of(context).pop();
    if (query.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final results = await LocationService.instance.searchPlaces(query);
      if (mounted) {
        Navigator.of(context).pop();
        if (results.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未找到匹配的地点')));
        } else {
          _showSearchResults(context, results);
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('搜索失败，请重试')));
      }
    }
  }

  void _showSearchResults(BuildContext context, List<PlaceResult> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择地点'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                title: Text(result.address),
                onTap: () {
                  setState(() {
                    _latitude = result.latitude;
                    _longitude = result.longitude;
                    _locationController.text = result.address;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
