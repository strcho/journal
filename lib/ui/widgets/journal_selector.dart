import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/journal.dart';
import '../../data/journal_repository.dart';
import 'create_journal_dialog.dart';

class JournalSelector extends StatefulWidget {
  const JournalSelector({
    super.key,
    required this.journalRepository,
    required this.selectedJournalId,
    required this.onChanged,
    this.enabled = true,
  });

  final JournalRepository journalRepository;
  final String selectedJournalId;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<JournalSelector> createState() => _JournalSelectorState();
}

class _JournalSelectorState extends State<JournalSelector> {
  static const _storage = FlutterSecureStorage();
  static const _lastSelectedJournalIdKey = 'last_selected_journal_id';
  List<Journal> _cachedJournals = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadInitialJournals();
  }

  Future<void> _loadInitialJournals() async {
    try {
      final journals = await widget.journalRepository.getJournals();
      if (mounted) {
        setState(() {
          _cachedJournals = journals;
          _isInitialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _saveSelectedJournalId(String journalId) async {
    await _storage.write(key: _lastSelectedJournalIdKey, value: journalId);
  }

  Future<void> _showCreateJournalDialog() async {
    if (!context.mounted) return;
    final navigator = Navigator.of(context);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          CreateJournalDialog(journalRepository: widget.journalRepository),
    );

    if (result != null && context.mounted) {
      final name = result['name'] as String;
      final color = result['color'] as String?;

      final newJournal = await widget.journalRepository.createJournal(
        name: name,
        color: color,
      );

      if (!context.mounted) return;

      widget.onChanged(newJournal.uuid);
      await _saveSelectedJournalId(newJournal.uuid);
      if (context.mounted) {
        navigator.pop();
      }
    }
  }

  void _showJournalSelector(List<Journal> journals) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  '选择日记本',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              LimitedBox(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: journals.length,
                  itemBuilder: (context, index) {
                    final journal = journals[index];
                    final isSelected = journal.uuid == widget.selectedJournalId;
                    return InkWell(
                      onTap: () {
                        widget.onChanged(journal.uuid);
                        _saveSelectedJournalId(journal.uuid);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: 0.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    journal.color?.replaceAll('#', '0xFF') ??
                                        '0xFF4285F4',
                                  ),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                journal.name,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.add_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('新增日记本'),
                onTap: _showCreateJournalDialog,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Journal>>(
      stream: widget.journalRepository.watchJournals(),
      initialData: _isInitialized ? _cachedJournals : null,
      builder: (context, snapshot) {
        final journals = snapshot.data ?? _cachedJournals;

        if (!_isInitialized && journals.isEmpty) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Center(child: Text('加载失败，请重试')),
          );
        }

        if (journals.isEmpty) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Center(child: Text('暂无日记本，请先创建')),
          );
        }

        final selectedJournal = journals.firstWhere(
          (j) => j.uuid == widget.selectedJournalId,
          orElse: () => journals.first,
        );

        return InkWell(
          onTap: widget.enabled ? () => _showJournalSelector(journals) : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.enabled
                  ? Theme.of(context).colorScheme.surfaceContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        selectedJournal.color?.replaceAll('#', '0xFF') ??
                            '0xFF4285F4',
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedJournal.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.enabled
                          ? null
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  color: widget.enabled
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
