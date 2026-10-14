import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/empty_state_widget.dart';
import './widgets/create_folder_sheet_widget.dart';
import './widgets/folder_card_widget.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final AppStore _store = AppStore.instance;

  final Map<String, Color> _colorMap = {
    'blue': const Color(0xFF1565C0),
    'purple': const Color(0xFF6750A4),
    'green': const Color(0xFF2D7A4F),
    'yellow': const Color(0xFFB45309),
    'orange': const Color(0xFFE65100),
    'gray': const Color(0xFF757575),
    'pink': const Color(0xFFC2185B),
    'red': const Color(0xFFB91C1C),
  };

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

  void _openFolder(String type, String name) {
    context.push(
      AppRoutes.folderNotesScreen,
      extra: {'type': type, 'name': name},
    );
  }

  void _showCreateFolderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CreateFolderSheetWidget(
        onCreateFolder: (name, colorKey) {
          final ok = _store.createFolder(name, colorKey);
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Folder "$name" already exists')),
            );
            return;
          }
          Navigator.pop(ctx);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Folder "$name" created')));
        },
      ),
    );
  }

  void _showFolderOptions(Map<String, dynamic> folder) {
    if (folder['isSystem'] == true) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      folder['name'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'edit_outlined',
                    color: theme.colorScheme.onSurface,
                    size: 22,
                  ),
                  title: Text(
                    'Rename Folder',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRenameDialog(folder);
                  },
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'delete_outline',
                    color: const Color(0xFFB91C1C),
                    size: 22,
                  ),
                  title: Text(
                    'Delete Folder',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteFolder(folder);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameDialog(Map<String, dynamic> folder) {
    final controller = TextEditingController(text: '${folder['name']}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rename Folder',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ok = _store.renameFolder(
                '${folder['id']}',
                controller.text,
              );
              if (ok) {
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a new, unused folder name'),
                  ),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(Map<String, dynamic> folder) {
    final count = folder['noteCount'] ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete "${folder['name']}"?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          count == 0
              ? 'This folder is empty.'
              : 'What would you like to do with the $count notes inside?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              _store.deleteFolder('${folder['id']}', deleteNotes: false);
              Navigator.pop(ctx);
            },
            child: Text(count == 0 ? 'Delete' : 'Move to Other'),
          ),
          if (count != 0)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              onPressed: () {
                _store.deleteFolder('${folder['id']}', deleteNotes: true);
                Navigator.pop(ctx);
              },
              child: const Text('Delete Notes Too'),
            ),
        ],
      ),
    );
  }

  Widget _label(ThemeData theme, String text, {double top = 8}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, top, 20, 8),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  SliverPadding _grid(
    bool isTablet,
    List<Map<String, dynamic>> items,
    ThemeData theme, {
    required void Function(Map<String, dynamic>) onTap,
    double bottom = 0,
    Color? forceColor,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => FolderCardWidget(
            folder: items[i],
            accentColor:
                forceColor ??
                _colorMap[items[i]['color']] ??
                theme.colorScheme.primary,
            onTap: () => onTap(items[i]),
            onLongPress: () => _showFolderOptions(items[i]),
          ),
          childCount: items.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final all = _store.folders;
    final systemFolders = all.where((f) => f['isSystem'] == true).toList();
    final userFolders = all.where((f) => f['isSystem'] != true).toList();

    final specials = <Map<String, dynamic>>[
      {
        'id': 'archive',
        'name': 'Archived',
        'icon': 'archive',
        'noteCount': _store.archivedNotes.length,
        'type': 'archive',
        'isSystem': true,
      },
      {
        'id': 'trash',
        'name': 'Trash',
        'icon': 'delete_outline',
        'noteCount': _store.trashedNotes.length,
        'type': 'trash',
        'isSystem': true,
      },
    ];

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
                'Folders',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              actions: [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'create_new_folder_outlined',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  onPressed: _showCreateFolderSheet,
                  tooltip: 'Create folder',
                ),
              ],
            ),
            _label(theme, 'Default Folders'),
            _grid(
              isTablet,
              systemFolders,
              theme,
              onTap: (f) => _openFolder('folder', '${f['name']}'),
            ),
            _label(theme, 'Archive & Trash', top: 20),
            _grid(
              isTablet,
              specials,
              theme,
              forceColor: const Color(0xFF757575),
              onTap: (f) => _openFolder('${f['type']}', '${f['name']}'),
            ),
            if (userFolders.isNotEmpty) ...[
              _label(theme, 'My Folders', top: 20),
              _grid(
                isTablet,
                userFolders,
                theme,
                bottom: 100,
                onTap: (f) => _openFolder('folder', '${f['name']}'),
              ),
            ] else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: EmptyStateWidget(
                    iconName: 'create_new_folder_outlined',
                    title: 'No custom folders yet',
                    subtitle:
                        'Organize your notes by creating folders that match your workflow.',
                    actionLabel: 'Create Folder',
                    onAction: _showCreateFolderSheet,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateFolderSheet,
        icon: CustomIconWidget(
          iconName: 'create_new_folder_outlined',
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          'New Folder',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
