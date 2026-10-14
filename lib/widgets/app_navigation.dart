import 'package:flutter/material.dart';

import '../core/app_export.dart';

class _TabSpec {
  final String label;
  final String activeIcon;
  final String inactiveIcon;
  final int? branchIndex;

  const _TabSpec({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedVisualIndex = 0;

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'Notes',
      activeIcon: 'note_alt',
      inactiveIcon: 'note_alt_outlined',
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Folders',
      activeIcon: 'folder',
      inactiveIcon: 'folder_outlined',
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Search',
      activeIcon: 'search',
      inactiveIcon: 'search',
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Settings',
      activeIcon: 'settings',
      inactiveIcon: 'settings_outlined',
      branchIndex: 3,
    ),
  ];

  void _onTabTapped(int visualIndex) {
    final tab = _tabs[visualIndex];
    if (tab.branchIndex == null) return;

    setState(() {
      _selectedVisualIndex = visualIndex;
    });
    widget.navigationShell.goBranch(
      tab.branchIndex!,
      initialLocation: tab.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(covariant AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentBranch = widget.navigationShell.currentIndex;
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].branchIndex == currentBranch) {
        if (_selectedVisualIndex != i) {
          setState(() => _selectedVisualIndex = i);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationBar(
      selectedIndex: _selectedVisualIndex,
      onDestinationSelected: _onTabTapped,
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.primaryContainer,
      elevation: 2,
      height: 72,
      destinations: _tabs.map((tab) {
        final isActive = _tabs.indexOf(tab) == _selectedVisualIndex;
        final isStub = tab.branchIndex == null;
        return NavigationDestination(
          icon: Opacity(
            opacity: isStub ? 0.4 : 1.0,
            child: CustomIconWidget(
              iconName: tab.inactiveIcon,
              color: isStub
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          selectedIcon: Opacity(
            opacity: isStub ? 0.4 : 1.0,
            child: CustomIconWidget(
              iconName: tab.activeIcon,
              color: isStub
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary,
              size: 24,
            ),
          ),
          label: tab.label,
        );
      }).toList(),
    );
  }
}
