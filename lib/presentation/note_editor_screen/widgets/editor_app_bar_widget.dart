import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EditorAppBarWidget extends StatelessWidget {
  final bool isPinned;
  final bool isFavorite;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onPinToggle;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onColorTap;
  final VoidCallback onMoreTap;

  const EditorAppBarWidget({
    super.key,
    required this.isPinned,
    required this.isFavorite,
    required this.isSaving,
    required this.onBack,
    required this.onSave,
    required this.onPinToggle,
    required this.onFavoriteToggle,
    required this.onColorTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Back button
          _AppBarIconButton(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            onTap: onBack,
            tooltip: 'Back',
          ),
          const Spacer(),
          // Pin button
          _AppBarIconButton(
            iconName: isPinned ? 'push_pin' : 'push_pin',
            color: isPinned
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            onTap: onPinToggle,
            tooltip: isPinned ? 'Unpin' : 'Pin',
          ),
          // Favorite button
          _AppBarIconButton(
            iconName: isFavorite ? 'favorite' : 'favorite_border',
            color: isFavorite
                ? Colors.red.shade400
                : theme.colorScheme.onSurfaceVariant,
            onTap: onFavoriteToggle,
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          // Color picker button
          _AppBarIconButton(
            iconName: 'palette_outlined',
            color: theme.colorScheme.onSurfaceVariant,
            onTap: onColorTap,
            tooltip: 'Change color',
          ),
          // Save button — always visible
          isSaving
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              : _AppBarIconButton(
                  iconName: 'save',
                  color: theme.colorScheme.primary,
                  onTap: onSave,
                  tooltip: 'Save note',
                  size: 24,
                ),
          // More options button
          _AppBarIconButton(
            iconName: 'more_vert',
            color: theme.colorScheme.onSurfaceVariant,
            onTap: onMoreTap,
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final String iconName;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final double size;

  const _AppBarIconButton({
    required this.iconName,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.size = 22,
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
          child: CustomIconWidget(iconName: iconName, color: color, size: size),
        ),
      ),
    );
  }
}
