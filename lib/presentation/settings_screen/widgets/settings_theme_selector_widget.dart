import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class SettingsThemeSelectorWidget extends StatelessWidget {
  final String currentTheme;
  final void Function(String) onThemeSelected;

  const SettingsThemeSelectorWidget({
    super.key,
    required this.currentTheme,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      {'key': 'Light', 'icon': 'light_mode', 'desc': 'Always use light theme'},
      {'key': 'Dark', 'icon': 'dark_mode', 'desc': 'Always use dark theme'},
      {
        'key': 'System',
        'icon': 'settings_suggest',
        'desc': 'Follow device settings',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose Theme',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final isSelected = opt['key'] == currentTheme;
            return GestureDetector(
              onTap: () => onThemeSelected(opt['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: opt['icon']!,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt['key']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          opt['desc']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isSelected)
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
