import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class SearchRecentWidget extends StatelessWidget {
  final List<String> recentSearches;
  final void Function(String) onSearchTap;
  final void Function(String) onRemove;

  const SearchRecentWidget({
    super.key,
    required this.recentSearches,
    required this.onSearchTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'history',
              color: theme.colorScheme.outlineVariant,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent searches',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Recent Searches',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ...recentSearches.map(
          (term) => InkWell(
            onTap: () => onSearchTap(term),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'history',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      term,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    onPressed: () => onRemove(term),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Search Tips',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ),
        _SearchTipRow(
          iconName: 'tag',
          tip: 'Search by tag name to filter related notes',
        ),
        _SearchTipRow(
          iconName: 'folder_outlined',
          tip: 'Type a folder name to find notes inside it',
        ),
        _SearchTipRow(
          iconName: 'checklist',
          tip: 'Use "Checklists" filter to find to-do notes',
        ),
      ],
    );
  }
}

class _SearchTipRow extends StatelessWidget {
  final String iconName;
  final String tip;

  const _SearchTipRow({required this.iconName, required this.tip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.primary.withAlpha(179),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
