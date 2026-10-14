import 'package:flutter/material.dart';

class PinDotsWidget extends StatelessWidget {
  final int pinLength;
  final int filledCount;
  final bool isError;

  const PinDotsWidget({
    super.key,
    required this.pinLength,
    required this.filledCount,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = isError
        ? const Color(0xFFB91C1C)
        : theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (i) {
        final isFilled = i < filledCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 18 : 16,
          height: isFilled ? 18 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? activeColor : Colors.transparent,
            border: Border.all(
              color: isFilled ? activeColor : theme.colorScheme.outlineVariant,
              width: 2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: activeColor.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
