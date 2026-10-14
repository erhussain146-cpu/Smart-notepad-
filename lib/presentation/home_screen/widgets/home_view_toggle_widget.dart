import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class HomeViewToggleWidget extends StatelessWidget {
  final bool isGridView;
  final String sortLabel;
  final VoidCallback onToggleView;
  final VoidCallback onSortTap;

  const HomeViewToggleWidget({
    super.key,
    required this.isGridView,
    required this.sortLabel,
    required this.onToggleView,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          InkWell(
            onTap: onSortTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'sort',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sortLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggleView,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: isGridView ? 'view_list' : 'grid_view',
                color: theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
