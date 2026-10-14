import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;
  final ValueChanged<String>? onSubmitted;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onClear,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: false,
                textInputAction: TextInputAction.search,
                onSubmitted: onSubmitted,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notes, folders, tags…',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'close',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          onPressed: onClear,
                        )
                      : null,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
