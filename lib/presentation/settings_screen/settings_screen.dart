import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import './widgets/settings_row_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/settings_theme_selector_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppStore _store = AppStore.instance;

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SettingsThemeSelectorWidget(
        currentTheme: _store.themeMode,
        onThemeSelected: (t) {
          _store.setThemeMode(t);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showDropdownSheet(
    String title,
    List<String> options,
    String current,
    void Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
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
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (opt) => InkWell(
                  onTap: () {
                    onSelect(opt);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: opt == current
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: opt == current
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (opt == current)
                          CustomIconWidget(
                            iconName: 'check',
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------ app lock
  void _onAppLockChanged(bool on) {
    if (on) {
      if (_store.hasPin) {
        _store.enableAppLock();
      } else {
        context.push(AppRoutes.pinSetupScreen);
      }
    } else {
      _store.disableAppLock();
    }
  }

  Future<void> _onBiometricChanged(bool on) async {
    if (!on) {
      _store.setBiometricEnabled(false);
      return;
    }
    final available = await BiometricService.isAvailable();
    if (!available) {
      if (mounted) {
        _snack('No fingerprint / face unlock set up on this phone');
      }
      return;
    }
    _store.authInProgress = true;
    final ok = await BiometricService.authenticate('Confirm to turn on biometric unlock');
    Future.delayed(const Duration(seconds: 1), () {
      _store.authInProgress = false;
    });
    if (ok) {
      _store.setBiometricEnabled(true);
    } else if (mounted) {
      _snack('Biometric check failed');
    }
  }

  // ------------------------------------------------------------ data
  Future<void> _exportBackup() async {
    await Clipboard.setData(ClipboardData(text: _store.exportBackupJson()));
    if (mounted) {
      _snack('Backup copied. Paste it in Notes / WhatsApp / Drive to keep it safe');
    }
  }

  Future<void> _exportAllNotes() async {
    final text = _store.exportAllNotesText();
    if (text.isEmpty) {
      _snack('No notes to export');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _snack('All notes copied to clipboard');
  }

  Future<void> _showRestoreDialog() async {
    final controller = TextEditingController();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final clip = data?.text ?? '';
    if (clip.contains('"SmartNotepad"')) controller.text = clip;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Restore Backup',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Paste your backup text below. Notes are merged with the ones you already have.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Paste backup here',
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final d = await Clipboard.getData(Clipboard.kTextPlain);
                      controller.text = d?.text ?? '';
                    },
                    icon: const Icon(Icons.paste, size: 18),
                    label: const Text('Paste'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final err = _store.importBackupJson(controller.text);
                  if (err != null) {
                    setLocal(() => error = err);
                  } else {
                    Navigator.pop(ctx);
                    _snack('Backup restored');
                  }
                },
                child: const Text('Restore'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClearTrash() {
    final count = _store.trashedNotes.length;
    if (count == 0) {
      _snack('Trash is already empty');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Empty Trash?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '$count note(s) in Trash will be permanently deleted. This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _store.emptyTrash();
              _snack('Trash emptied');
            },
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'SmartNotepad stores all your notes only on this phone. '
          'Nothing is uploaded to any server and no account is needed. '
          'Your PIN is saved as a one-way hash, never as plain text.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              floating: true,
              snap: true,
              elevation: 0,
              scrolledUnderElevation: 1,
              automaticallyImplyLeading: false,
              title: Text(
                'Settings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                // General
                SettingsSectionWidget(
                  title: 'General',
                  children: [
                    SettingsRowWidget(
                      iconName: 'palette_outlined',
                      label: 'Theme',
                      trailingLabel: _store.themeMode,
                      onTap: _showThemeSelector,
                    ),
                    SettingsRowWidget(
                      iconName: 'view_list',
                      label: 'Default View',
                      trailingLabel: _store.defaultView,
                      onTap: () => _showDropdownSheet(
                        'Default View',
                        ['List', 'Grid'],
                        _store.defaultView,
                        _store.setDefaultView,
                      ),
                    ),
                    SettingsRowWidget(
                      iconName: 'sort',
                      label: 'Default Sort',
                      trailingLabel: _store.defaultSort,
                      onTap: () => _showDropdownSheet(
                        'Default Sort',
                        AppStore.sortOptions,
                        _store.defaultSort,
                        _store.setDefaultSort,
                      ),
                    ),
                  ],
                ),
                // Editor
                SettingsSectionWidget(
                  title: 'Editor',
                  children: [
                    SettingsRowWidget(
                      iconName: 'text_fields',
                      label: 'Font Size',
                      trailingLabel: '${_store.fontSize.toInt()}sp',
                      onTap: () {},
                      trailing: Slider(
                        value: _store.fontSize.clamp(12, 22).toDouble(),
                        min: 12,
                        max: 22,
                        divisions: 5,
                        onChanged: _store.setFontSize,
                      ),
                      hasSlider: true,
                    ),
                    SettingsRowWidget(
                      iconName: 'spellcheck',
                      label: 'Show Word Count',
                      onTap: () =>
                          _store.setShowWordCount(!_store.showWordCount),
                      trailing: Switch(
                        value: _store.showWordCount,
                        onChanged: _store.setShowWordCount,
                      ),
                    ),
                    SettingsRowWidget(
                      iconName: 'save_outlined',
                      label: 'Autosave',
                      onTap: () => _store.setAutosave(!_store.autosave),
                      trailing: Switch(
                        value: _store.autosave,
                        onChanged: _store.setAutosave,
                      ),
                    ),
                  ],
                ),
                // Security
                SettingsSectionWidget(
                  title: 'Security',
                  children: [
                    SettingsRowWidget(
                      iconName: 'lock_outline',
                      label: 'App Lock',
                      onTap: () => _onAppLockChanged(!_store.appLockEnabled),
                      trailing: Switch(
                        value: _store.appLockEnabled,
                        onChanged: _onAppLockChanged,
                      ),
                    ),
                    if (_store.appLockEnabled) ...[
                      SettingsRowWidget(
                        iconName: 'fingerprint',
                        label: 'Biometric Unlock',
                        onTap: () =>
                            _onBiometricChanged(!_store.biometricEnabled),
                        trailing: Switch(
                          value: _store.biometricEnabled,
                          onChanged: _onBiometricChanged,
                        ),
                      ),
                      SettingsRowWidget(
                        iconName: 'timer_outlined',
                        label: 'Auto-lock After',
                        trailingLabel: _store.lockTimeout,
                        onTap: () => _showDropdownSheet(
                          'Auto-lock After',
                          AppStore.lockTimeouts.keys.toList(),
                          _store.lockTimeout,
                          _store.setLockTimeout,
                        ),
                      ),
                      SettingsRowWidget(
                        iconName: 'pin_outlined',
                        label: 'Change PIN',
                        onTap: () => context.push(AppRoutes.pinSetupScreen),
                      ),
                    ],
                  ],
                ),
                // Data Management
                SettingsSectionWidget(
                  title: 'Data Management',
                  children: [
                    SettingsRowWidget(
                      iconName: 'backup_outlined',
                      label: 'Export Backup',
                      onTap: _exportBackup,
                    ),
                    SettingsRowWidget(
                      iconName: 'restore',
                      label: 'Restore Backup',
                      onTap: _showRestoreDialog,
                    ),
                    SettingsRowWidget(
                      iconName: 'file_download_outlined',
                      label: 'Export All Notes',
                      onTap: _exportAllNotes,
                    ),
                    SettingsRowWidget(
                      iconName: 'delete_sweep_outlined',
                      label: 'Empty Trash',
                      isDestructive: true,
                      onTap: _confirmClearTrash,
                    ),
                  ],
                ),
                // About
                SettingsSectionWidget(
                  title: 'About',
                  children: [
                    SettingsRowWidget(
                      iconName: 'info_outline',
                      label: 'App Version',
                      trailingLabel: '1.0.0',
                      onTap: () {},
                    ),
                    SettingsRowWidget(
                      iconName: 'privacy_tip_outlined',
                      label: 'Privacy Policy',
                      onTap: _showPrivacy,
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
