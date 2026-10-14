import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class HomeQuickActionsWidget extends StatelessWidget {
  final VoidCallback onNewNote;
  final VoidCallback onNewChecklist;

  const HomeQuickActionsWidget({
    super.key,
    required this.onNewNote,
    required this.onNewChecklist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionChip(
              iconName: 'add_circle_outline',
              label: 'New Note',
              onTap: onNewNote,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionChip(
              iconName: 'checklist_rtl',
              label: 'Checklist',
              onTap: onNewChecklist,
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String iconName;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QuickActionChip({
    required this.iconName,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isPrimary
        ? theme.colorScheme.primary
        : theme.colorScheme.secondaryContainer;
    final fg = isPrimary
        ? Colors.white
        : theme.colorScheme.onSecondaryContainer;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: fg.withAlpha(26),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(iconName: iconName, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
