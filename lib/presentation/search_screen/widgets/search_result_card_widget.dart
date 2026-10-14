import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class SearchResultCardWidget extends StatelessWidget {
  final Map<String, dynamic> note;
  final String query;
  final Color noteColor;
  final VoidCallback onTap;

  const SearchResultCardWidget({
    super.key,
    required this.note,
    required this.query,
    required this.noteColor,
    required this.onTap,
  });

  List<TextSpan> _highlightText(
    String text,
    String query,
    TextStyle base,
    TextStyle highlight,
  ) {
    if (query.isEmpty) return [TextSpan(text: text, style: base)];
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;
    while (true) {
      final idx = lower.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: base));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: base));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: highlight,
        ),
      );
      start = idx + query.length;
    }
    return spans;
  }

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
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark
        ? theme.colorScheme.surface
        : (noteColor == AppTheme.noteDefault
              ? theme.colorScheme.surface
              : noteColor);
    final textColor = isDark
        ? theme.colorScheme.onSurface
        : const Color(0xFF1C1B1F);
    final subColor = textColor.withAlpha(153);

    final baseStyle = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      color: subColor,
      height: 1.5,
    );
    final highlightStyle = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      backgroundColor: theme.colorScheme.primaryContainer.withAlpha(102),
      height: 1.5,
    );
    final titleBase = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: textColor,
    );
    final titleHighlight = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.primaryContainer.withAlpha(102),
    );

    final tags = (note['tags'] as List?)?.cast<String>() ?? [];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: _highlightText(
                          ((note['title'] as String?)?.isNotEmpty == true ? note['title'] as String : 'Untitled'),
                          query,
                          titleBase,
                          titleHighlight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(note['modifiedAt'] ?? ''),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: subColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: _highlightText(
                    note['preview'] ?? '',
                    query,
                    baseStyle,
                    highlightStyle,
                  ),
                ),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: tags
                      .take(3)
                      .map(
                        (t) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withAlpha(
                              128,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
