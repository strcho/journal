import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_day_one/l10n/app_localizations.dart';

class EntryRichTextToolbar extends StatelessWidget {
  const EntryRichTextToolbar({
    super.key,
    required this.controller,
    required this.l10n,
    required this.onInsertImages,
  });

  final QuillController controller;
  final AppLocalizations l10n;
  final VoidCallback onInsertImages;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: QuillSimpleToolbar(
              controller: controller,
              config: _basicConfig,
            ),
          ),
          IconButton(
            tooltip: l10n.moreFormatting,
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreFormatting(context),
          ),
        ],
      ),
    );
  }

  QuillSimpleToolbarConfig get _basicConfig {
    return QuillSimpleToolbarConfig(
      multiRowsDisplay: false,
      showDividers: false,
      toolbarSectionSpacing: 8,
      showFontFamily: false,
      showFontSize: false,
      showSmallButton: false,
      showLineHeightButton: false,
      showStrikeThrough: false,
      showInlineCode: false,
      showColorButton: false,
      showBackgroundColorButton: false,
      showClearFormat: false,
      showAlignmentButtons: false,
      showHeaderStyle: false,
      showCodeBlock: false,
      showQuote: false,
      showIndent: false,
      showLink: false,
      showDirection: false,
      showSearchButton: false,
      showSubscript: false,
      showSuperscript: false,
      customButtons: [
        QuillToolbarCustomButtonOptions(
          icon: const Icon(Icons.image_outlined),
          tooltip: l10n.insertImage,
          onPressed: onInsertImages,
        ),
      ],
    );
  }

  QuillSimpleToolbarConfig get _advancedConfig {
    return const QuillSimpleToolbarConfig(
      toolbarIconAlignment: WrapAlignment.start,
      toolbarIconCrossAlignment: WrapCrossAlignment.center,
      showUndo: false,
      showRedo: false,
      showBoldButton: false,
      showItalicButton: false,
      showUnderLineButton: false,
      showListNumbers: false,
      showListBullets: false,
      showListCheck: false,
      showFontFamily: true,
      showFontSize: true,
      showStrikeThrough: true,
      showInlineCode: true,
      showColorButton: true,
      showBackgroundColorButton: true,
      showClearFormat: true,
      showAlignmentButtons: true,
      showHeaderStyle: true,
      showCodeBlock: true,
      showQuote: true,
      showIndent: true,
      showLink: true,
      showSearchButton: true,
      showDirection: true,
      showSubscript: true,
      showSuperscript: true,
    );
  }

  void _showMoreFormatting(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.moreFormatting,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                QuillSimpleToolbar(
                  controller: controller,
                  config: _advancedConfig,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
