import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class PinKeypadWidget extends StatelessWidget {
  final void Function(String) onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback onBiometric;
  final bool showBiometric;

  const PinKeypadWidget({
    super.key,
    required this.onKeyTap,
    required this.onBackspace,
    required this.onBiometric,
    this.showBiometric = true,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          ...keys.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row
                    .map((k) => _KeyButton(label: k, onTap: () => onKeyTap(k)))
                    .toList(),
              ),
            ),
          ),
          // Bottom row: biometric, 0, backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (showBiometric)
                _IconKeyButton(
                  iconName: 'fingerprint',
                  onTap: onBiometric,
                  tooltip: 'Use biometrics',
                )
              else
                const SizedBox(width: 72, height: 72),
              _KeyButton(label: '0', onTap: () => onKeyTap('0')),
              _IconKeyButton(
                iconName: 'backspace_outlined',
                onTap: onBackspace,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconKeyButton extends StatelessWidget {
  final String iconName;
  final VoidCallback onTap;
  final String tooltip;

  const _IconKeyButton({
    required this.iconName,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        splashColor: theme.colorScheme.primary.withAlpha(26),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.onSurfaceVariant,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
