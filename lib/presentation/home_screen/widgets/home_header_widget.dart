import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class HomeHeaderWidget extends StatelessWidget {
  final int noteCount;
  final VoidCallback onSearchTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLockTap;

  const HomeHeaderWidget({
    super.key,
    required this.noteCount,
    required this.onSearchTap,
    required this.onSettingsTap,
    required this.onLockTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'note_alt',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'SmartNotepad',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              _HeaderIconButton(
                iconName: 'search',
                onTap: onSearchTap,
                tooltip: 'Search notes',
              ),
              _HeaderIconButton(
                iconName: 'lock_outline',
                onTap: onLockTap,
                tooltip: 'App lock',
              ),
              _HeaderIconButton(
                iconName: 'settings_outlined',
                onTap: onSettingsTap,
                tooltip: 'Settings',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Your notes,',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'all in one place.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$noteCount notes total',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String iconName;
  final VoidCallback onTap;
  final String tooltip;

  const _HeaderIconButton({
    required this.iconName,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: theme.colorScheme.primary.withAlpha(26),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
      ),
    );
  }
}
