import 'package:flutter/material.dart';

import '../../data/journal_repository.dart';
import 'color_picker_dialog.dart';

class CreateJournalDialog extends StatefulWidget {
  const CreateJournalDialog({super.key, required this.journalRepository});

  final JournalRepository journalRepository;

  @override
  State<CreateJournalDialog> createState() => _CreateJournalDialogState();
}

class _CreateJournalDialogState extends State<CreateJournalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = '#2196F3';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    final color = await showDialog<String>(
      context: context,
      builder: (context) => ColorPickerDialog(initialColor: _selectedColor),
    );

    if (color != null && mounted) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    Navigator.of(context).pop({'name': name, 'color': _selectedColor});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建日记本'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '输入日记本名称',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入日记本名称';
                }
                return null;
              },
              onFieldSubmitted: (_) => _pickColor(),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickColor,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(
                            _selectedColor?.replaceAll('#', '0xFF') ??
                                '0xFF2196F4',
                          ),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedColor ?? '#2196F4',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    const Icon(Icons.palette_outlined),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('创建')),
      ],
    );
  }
}
