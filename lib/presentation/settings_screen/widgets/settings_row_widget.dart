import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class SettingsRowWidget extends StatelessWidget {
  final String iconName;
  final String label;
  final String? trailingLabel;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool hasSlider;

  const SettingsRowWidget({
    super.key,
    required this.iconName,
    required this.label,
    this.trailingLabel,
    this.trailing,
    required this.onTap,
    this.isDestructive = false,
    this.hasSlider = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = isDestructive
        ? const Color(0xFFB91C1C)
        : theme.colorScheme.onSurface;
    final iconColor = isDestructive
        ? const Color(0xFFB91C1C)
        : theme.colorScheme.onSurfaceVariant;

    if (hasSlider && trailing != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: iconName,
                  color: iconColor,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                ),
                if (trailingLabel != null)
                  Text(
                    trailingLabel!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            trailing!,
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor:
          (isDestructive ? const Color(0xFFB91C1C) : theme.colorScheme.primary)
              .withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CustomIconWidget(iconName: iconName, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (trailingLabel != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailingLabel!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: theme.colorScheme.outlineVariant,
                    size: 18,
                  ),
                ],
              )
            else if (!isDestructive)
              CustomIconWidget(
                iconName: 'chevron_right',
                color: theme.colorScheme.outlineVariant,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
