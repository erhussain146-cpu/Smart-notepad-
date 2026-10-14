import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class NoteCardWidget extends StatelessWidget {
  final Map<String, dynamic> note;
  final Color noteColor;
  final VoidCallback onTap;

  const NoteCardWidget({
    super.key,
    required this.note,
    required this.noteColor,
    required this.onTap,
  });

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? theme.colorScheme.surface
        : (noteColor == AppTheme.noteDefault
              ? theme.colorScheme.surface
              : noteColor);
    final textColor = isDark
        ? theme.colorScheme.onSurface
        : (noteColor == AppTheme.noteDefault
              ? theme.colorScheme.onSurface
              : const Color(0xFF1C1B1F));
    final subColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : textColor.withAlpha(153);

    final tags = (note['tags'] as List?)?.cast<String>() ?? [];
    final isChecklist = note['isChecklist'] == true;
    final isPinned = note['isPinned'] == true;
    final isFavorite = note['isFavorite'] == true;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: theme.colorScheme.primary.withAlpha(20),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: type icon + actions
              Row(
                children: [
                  CustomIconWidget(
                    iconName: isChecklist ? 'checklist_rtl' : 'description',
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  const Spacer(),
                  if (isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CustomIconWidget(
                        iconName: 'push_pin',
                        color: theme.colorScheme.primary,
                        size: 14,
                      ),
                    ),
                  if (isFavorite)
                    CustomIconWidget(
                      iconName: 'favorite',
                      color: Colors.red.shade400,
                      size: 14,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                ((note['title'] as String?)?.isNotEmpty == true ? note['title'] as String : 'Untitled'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Preview
              Text(
                note['preview'] ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: subColor,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Footer
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'access_time',
                    color: subColor,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note['modifiedAt'] ?? ''),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: subColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  if (tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(
                          153,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tags.first,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
