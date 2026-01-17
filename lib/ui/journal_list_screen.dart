import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/journal.dart';
import '../data/journal_repository.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key, required this.journalRepository});

  final JournalRepository journalRepository;

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  static const _storage = FlutterSecureStorage();
  static const _lastSelectedJournalIdKey = 'last_selected_journal_id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日记本')),
      body: StreamBuilder<List<Journal>>(
        stream: widget.journalRepository.watchJournals(),
        builder: (context, snapshot) {
          final journals = snapshot.data ?? [];
          final activeJournals = journals
              .where((j) => j.deletedAt == null)
              .toList();

          if (activeJournals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.book_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text('暂无日记本', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('点击右下角按钮创建日记本'),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: activeJournals.length,
            itemBuilder: (context, index) {
              final journal = activeJournals[index];
              return _JournalListItem(
                journal: journal,
                journalRepository: widget.journalRepository,
                onEdit: () => _editJournal(journal),
                onDelete: () => _deleteJournal(journal),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addJournal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addJournal() async {
    final l10n = AppLocalizations.of(context)!;

    final nameController = TextEditingController();
    final colorController = TextEditingController(text: '#4285F4');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建日记本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '输入日记本名称',
                prefixIcon: Icon(Icons.title),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(
                labelText: '颜色',
                hintText: '#4285F4',
                prefixIcon: Icon(Icons.palette),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入日记本名称')));
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final name = nameController.text.trim();
      final color = colorController.text.trim();
      await widget.journalRepository.createJournal(name: name, color: color);
    }
  }

  Future<void> _editJournal(Journal journal) async {
    final l10n = AppLocalizations.of(context)!;
    final isDefault = journal.uuid == '00000000-0000-0000-0000-000000000001';

    final nameController = TextEditingController(text: journal.name);
    final colorController = TextEditingController(
      text: journal.color ?? '#4285F4',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑日记本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '名称',
                hintText: '输入日记本名称',
                prefixIcon: const Icon(Icons.title),
                enabled: !isDefault,
              ),
              autofocus: true,
              enabled: !isDefault,
            ),
            if (isDefault)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '默认日记本的名称不能修改',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(
                labelText: '颜色',
                hintText: '#4285F4',
                prefixIcon: Icon(Icons.palette),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入日记本名称')));
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final name = nameController.text.trim();
      final color = colorController.text.trim();
      await widget.journalRepository.updateJournal(
        journal.uuid,
        name: name,
        color: color,
      );
    }
  }

  Future<void> _deleteJournal(Journal journal) async {
    final l10n = AppLocalizations.of(context)!;
    final isDefault = journal.uuid == '00000000-0000-0000-0000-000000000001';

    if (isDefault) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('默认日记本不能删除')));
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日记本'),
        content: Text('确定要删除日记本"${journal.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final lastSelectedJournalId = await _storage.read(
        key: _lastSelectedJournalIdKey,
      );
      if (lastSelectedJournalId == journal.uuid) {
        await _storage.delete(key: _lastSelectedJournalIdKey);
      }
      await widget.journalRepository.deleteJournal(journal.uuid);
    }
  }
}

class _JournalListItem extends StatelessWidget {
  const _JournalListItem({
    required this.journal,
    required this.journalRepository,
    required this.onEdit,
    required this.onDelete,
  });

  final Journal journal;
  final JournalRepository journalRepository;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = journal.color ?? '#4285F4';
    final colorInt = int.parse(color.replaceAll('#', '0xFF'));
    final isDefault = journal.uuid == '00000000-0000-0000-0000-000000000001';

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(colorInt),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.book, color: Colors.white),
      ),
      title: Text(journal.name),
      subtitle: Text(
        isDefault ? '默认日记本' : '创建于 ${_formatDate(journal.createdAt)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} 周前';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} 月前';
    } else {
      return '${(diff.inDays / 365).floor()} 年前';
    }
  }
}
