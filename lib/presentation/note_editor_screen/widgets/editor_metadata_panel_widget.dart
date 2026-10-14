import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class EditorMetadataPanelWidget extends StatelessWidget {
  final int wordCount;
  final int charCount;
  final bool isPinned;
  final bool isFavorite;
  final String folder;
  final List<String> tags;

  const EditorMetadataPanelWidget({
    super.key,
    required this.wordCount,
    required this.charCount,
    required this.isPinned,
    required this.isFavorite,
    required this.folder,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note Info',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _MetaRow(
            iconName: 'text_fields',
            label: 'Words',
            value: '$wordCount',
          ),
          _MetaRow(
            iconName: 'format_size',
            label: 'Characters',
            value: '$charCount',
          ),
          _MetaRow(iconName: 'folder_outlined', label: 'Folder', value: folder),
          _MetaRow(
            iconName: 'push_pin',
            label: 'Pinned',
            value: isPinned ? 'Yes' : 'No',
          ),
          _MetaRow(
            iconName: 'favorite_border',
            label: 'Favorite',
            value: isFavorite ? 'Yes' : 'No',
          ),
          const SizedBox(height: 12),
          Text(
            'Tags',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...tags.map(
                (t) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+ Add tag',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String iconName;
  final String label;
  final String value;

  const _MetaRow({
    required this.iconName,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
