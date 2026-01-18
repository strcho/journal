import 'package:flutter/material.dart';
import 'package:my_day_one/data/checklist_item.dart';

class ChecklistWidget extends StatelessWidget {
  const ChecklistWidget({
    super.key,
    required this.items,
    required this.onItemToggle,
    required this.onItemAdd,
    required this.onItemDelete,
    required this.onItemEdit,
  });

  final List<ChecklistItem> items;
  final void Function(String id) onItemToggle;
  final void Function(String text) onItemAdd;
  final void Function(String id) onItemDelete;
  final void Function(String id, String newText) onItemEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyChecklist(onAdd: onItemAdd);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                const Icon(Icons.checklist, size: 16),
                const SizedBox(width: 8),
                Text(
                  _getProgressText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) {
            return _ChecklistItemTile(
              item: item,
              onTap: () => onItemToggle(item.id),
              onEdit: (newText) => onItemEdit(item.id, newText),
              onDelete: () => onItemDelete(item.id),
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('添加项目'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getProgressText() {
    final completed = items.where((e) => e.isCompleted).length;
    return '✅ $completed/${items.length}';
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加待办事项'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入待办事项内容...',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onItemAdd(value.trim());
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onItemAdd(controller.text.trim());
              }
              Navigator.of(context).pop();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _EmptyChecklist extends StatelessWidget {
  const _EmptyChecklist({required this.onAdd});

  final void Function(String text) onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showAddDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Text(
                '添加待办事项',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加待办事项'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入待办事项内容...',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onAdd(value.trim());
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
              }
              Navigator.of(context).pop();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ChecklistItem item;
  final VoidCallback onTap;
  final void Function(String newText) onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(
              item.isCompleted
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: item.isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: item.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: item.isCompleted
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6)
                      : null,
                ),
              ),
            ),
            _EditDeleteMenu(
              onEdit: () => _showEditDialog(context),
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: item.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑待办事项'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onEdit(value.trim());
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onEdit(controller.text.trim());
              }
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _EditDeleteMenu extends StatelessWidget {
  const _EditDeleteMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 12),
              Text('编辑'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18),
              SizedBox(width: 12),
              Text('删除'),
            ],
          ),
        ),
      ],
    );
  }
}
