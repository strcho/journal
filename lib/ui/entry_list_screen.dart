import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../data/entry.dart';
import '../data/entry_repository.dart';
import '../security/app_lock_service.dart';
import 'calendar_screen.dart';
import 'entry_detail_screen.dart';
import 'entry_editor_screen.dart';
import 'settings_screen.dart';

class EntryListScreen extends StatefulWidget {
  const EntryListScreen({
    super.key,
    required this.repository,
    required this.appLockService,
    this.dayFilter,
    this.titleOverride,
    this.showSearch = true,
    this.showSettingsAction = true,
    this.showCalendarAction = true,
  });

  final EntryRepository repository;
  final AppLockService appLockService;
  final DateTime? dayFilter;
  final String? titleOverride;
  final bool showSearch;
  final bool showSettingsAction;
  final bool showCalendarAction;

  @override
  State<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends State<EntryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;
    final dateFormat = DateFormat.yMMMd(localeName).add_Hm();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titleOverride ?? l10n.appTitle),
        actions: [
          if (widget.showCalendarAction)
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CalendarScreen(
                    repository: widget.repository,
                    appLockService: widget.appLockService,
                  ),
                ),
              ),
            ),
          if (widget.showSettingsAction)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsScreen(appLockService: widget.appLockService),
                ),
              ),
            ),
        ],
        bottom: widget.showSearch
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.searchEntriesHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: StreamBuilder<List<Entry>>(
        stream: widget.repository.watchEntries(query: _query),
        builder: (context, snapshot) {
          final entries = _filterEntries(snapshot.data ?? []);
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_stories, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noEntriesTitle,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.noEntriesBody),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openEditor(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.newEntry),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final title = entry.title.trim().isEmpty
                  ? l10n.untitled
                  : entry.title.trim();
              final preview = entry.plainText.trim().replaceAll('\n', ' ');
              return ListTile(
                leading: entry.attachmentIds.isEmpty
                    ? null
                    : _EntryThumbnail(
                        attachmentId: entry.attachmentIds.first,
                        repository: widget.repository,
                      ),
                title: Text(title),
                subtitle: preview.isEmpty
                    ? Text(l10n.noContent)
                    : Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: Text(
                  dateFormat.format(entry.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EntryDetailScreen(
                      repository: widget.repository,
                      entryId: entry.id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryEditorScreen(repository: widget.repository),
      ),
    );
  }

  List<Entry> _filterEntries(List<Entry> entries) {
    final dayFilter = widget.dayFilter;
    if (dayFilter == null) {
      return entries;
    }
    return entries
        .where((entry) => DateUtils.isSameDay(entry.createdAt, dayFilter))
        .toList();
  }
}

class _EntryThumbnail extends StatelessWidget {
  const _EntryThumbnail({
    required this.attachmentId,
    required this.repository,
  });

  final String attachmentId;
  final EntryRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: repository.readAttachmentBytes(attachmentId),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: bytes == null || bytes.isEmpty
              ? Container(
                  width: 56,
                  height: 56,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported_outlined),
                )
              : Image.memory(
                  bytes,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
        );
      },
    );
  }
}
