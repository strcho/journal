import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/journal.dart';
import '../../data/journal_repository.dart';

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

  Future<void> _saveSelectedJournalId(String journalId) async {
    await _storage.write(key: _lastSelectedJournalIdKey, value: journalId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Journal>>(
      stream: widget.journalRepository.watchJournals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox(
            height: 56,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('加载日记本失败，请重试'),
              ),
            ),
          );
        }

        final journals = snapshot.data ?? [];

        if (journals.isEmpty) {
          return const SizedBox(
            height: 56,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('暂无日记本，请先创建日记本'),
              ),
            ),
          );
        }

        return SizedBox(
          height: 60,
          child: DropdownButtonFormField<String>(
            initialValue: widget.selectedJournalId.isNotEmpty
                ? widget.selectedJournalId
                : null,
            items: journals.isEmpty
                ? null
                : journals
                      .map(
                        (journal) => DropdownMenuItem<String>(
                          value: journal.uuid,
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
                              const SizedBox(width: 8),
                              Expanded(child: Text(journal.name)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            onChanged: widget.enabled && journals.isNotEmpty
                ? (value) async {
                    if (value != null) {
                      widget.onChanged(value);
                      await _saveSelectedJournalId(value);
                    }
                  }
                : null,
            decoration: InputDecoration(
              hintText: '选择日记本',
              prefixIcon: const Icon(Icons.book_outlined),
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
          ),
        );
      },
    );
  }
}
