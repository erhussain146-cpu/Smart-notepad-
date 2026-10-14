import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class EditorFooterWidget extends StatelessWidget {
  final String saveStatus;
  final bool isSaving;
  final int wordCount;
  final int charCount;
  final bool showCounts;

  const EditorFooterWidget({
    super.key,
    required this.saveStatus,
    required this.isSaving,
    required this.wordCount,
    required this.charCount,
    this.showCounts = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          if (isSaving)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          else
            CustomIconWidget(
              iconName: saveStatus == 'All changes saved'
                  ? 'cloud_done'
                  : 'edit_outlined',
              color: theme.colorScheme.primary,
              size: 14,
            ),
          const SizedBox(width: 6),
          Text(
            saveStatus,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          if (showCounts)
            Text(
              '$wordCount words · $charCount chars',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
