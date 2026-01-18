import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../data/entry.dart';
import '../data/entry_repository.dart';
import '../data/journal_repository.dart';
import '../security/app_lock_service.dart';
import 'calendar_screen.dart';
import 'entry_detail_screen.dart';
import 'entry_editor_screen.dart';
import 'settings_screen.dart';
import 'widgets/journal_selector.dart';

const Map<String, String> _entryTypeLabels = {
  'diary': '日记',
  'note': '笔记',
  'todo': '待办',
};

class EntryListScreen extends StatefulWidget {
  const EntryListScreen({
    super.key,
    required this.repository,
    required this.journalRepository,
    required this.appLockService,
    this.dayFilter,
    this.titleOverride,
    this.showSearch = true,
    this.showSettingsAction = true,
    this.showCalendarAction = true,
  });

  final EntryRepository repository;
  final JournalRepository journalRepository;
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
  String _journalFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;
    final timeFormat = DateFormat.Hm(localeName);
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
                    journalRepository: widget.journalRepository,
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
      body: Column(
        children: [
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: JournalSelector(
                journalRepository: widget.journalRepository,
                selectedJournalId: _journalFilter,
                onChanged: (value) => setState(() => _journalFilter = value),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Entry>>(
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

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _EntryCard(
                      entry: entry,
                      timeFormat: timeFormat,
                      repository: widget.repository,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EntryDetailScreen(
                            repository: widget.repository,
                            journalRepository: widget.journalRepository,
                            entryId: entry.id,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
        builder: (_) => EntryEditorScreen(
          repository: widget.repository,
          journalRepository: widget.journalRepository,
        ),
      ),
    );
  }

  List<Entry> _filterEntries(List<Entry> entries) {
    var filtered = entries;

    final dayFilter = widget.dayFilter;
    if (dayFilter != null) {
      filtered = filtered
          .where((entry) => DateUtils.isSameDay(entry.createdAt, dayFilter))
          .toList();
    }

    if (_journalFilter.isNotEmpty) {
      filtered = filtered
          .where((entry) => entry.journalId == _journalFilter)
          .toList();
    }

    return filtered;
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.timeFormat,
    required this.repository,
    required this.onTap,
  });

  final Entry entry;
  final DateFormat timeFormat;
  final EntryRepository repository;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = entry.title.trim().isEmpty ? '无标题' : entry.title.trim();
    final preview = entry.plainText.trim().replaceAll('\n', ' ');
    final typeLabel = _entryTypeLabels[entry.entryType] ?? entry.entryType;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBlock(dateTime: entry.createdAt),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.attachmentIds.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _EntryThumbnail(
                            attachmentId: entry.attachmentIds.first,
                            repository: repository,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (preview.isNotEmpty)
                      Text(
                        preview,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          typeLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeFormat.format(entry.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                        ),
                        if (entry.location != null &&
                            entry.location!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            entry.latitude != null && entry.longitude != null
                                ? Icons.gps_fixed
                                : Icons.location_on_outlined,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              entry.location!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (entry.checklist.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            _getChecklistProgress(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getChecklistProgress() {
    final completed = entry.checklist.where((e) => e.isCompleted).length;
    return '✅ $completed/${entry.checklist.length}';
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.dateTime});

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[dateTime.weekday - 1];
    final day = dateTime.day.toString().padLeft(2, '0');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          weekday,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          day,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}

class _EntryThumbnail extends StatelessWidget {
  const _EntryThumbnail({required this.attachmentId, required this.repository});

  final String attachmentId;
  final EntryRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: repository.readAttachmentBytes(attachmentId),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: bytes == null || bytes.isEmpty
              ? Container(
                  width: 48,
                  height: 48,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                )
              : Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover),
        );
      },
    );
  }
}
