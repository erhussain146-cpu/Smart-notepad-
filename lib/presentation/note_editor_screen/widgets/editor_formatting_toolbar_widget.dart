import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EditorFormattingToolbarWidget extends StatelessWidget {
  final void Function(String tag) onFormat;
  final VoidCallback onChecklistToggle;
  final bool isChecklist;

  const EditorFormattingToolbarWidget({
    super.key,
    required this.onFormat,
    required this.onChecklistToggle,
    required this.isChecklist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            _ToolbarButton(
              iconName: 'format_bold',
              tooltip: 'Bold',
              onTap: () => onFormat('bold'),
            ),
            _ToolbarButton(
              iconName: 'format_italic',
              tooltip: 'Italic',
              onTap: () => onFormat('italic'),
            ),
            _ToolbarButton(
              iconName: 'format_underline',
              tooltip: 'Underline',
              onTap: () => onFormat('underline'),
            ),
            _ToolbarButton(
              iconName: 'format_strikethrough',
              tooltip: 'Strikethrough',
              onTap: () => onFormat('strikethrough'),
            ),
            _VerticalDivider(),
            _ToolbarButton(
              iconName: 'format_list_bulleted',
              tooltip: 'Bullet list',
              onTap: () => onFormat('bullet'),
            ),
            _ToolbarButton(
              iconName: 'format_list_numbered',
              tooltip: 'Numbered list',
              onTap: () => onFormat('numbered'),
            ),
            _ToolbarButton(
              iconName: 'checklist',
              tooltip: 'Add checklist item',
              onTap: () => onFormat('checklist_item'),
              isActive: isChecklist,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final String iconName;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  const _ToolbarButton({
    required this.iconName,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: isActive
              ? BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Center(
            child: CustomIconWidget(
              iconName: iconName,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.colorScheme.outlineVariant,
    );
  }
}
