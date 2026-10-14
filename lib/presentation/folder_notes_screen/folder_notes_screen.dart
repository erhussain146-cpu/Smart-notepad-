import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/empty_state_widget.dart';
import '../home_screen/widgets/note_card_widget.dart';

/// Shows the notes of one folder, or the Archive, or the Trash.
/// type: 'folder' | 'archive' | 'trash'
class FolderNotesScreen extends StatefulWidget {
  final String type;
  final String name;

  const FolderNotesScreen({super.key, required this.type, required this.name});

  @override
  State<FolderNotesScreen> createState() => _FolderNotesScreenState();
}

class _FolderNotesScreenState extends State<FolderNotesScreen> {
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

  List<Map<String, dynamic>> get _notes {
    List<Map<String, dynamic>> list;
    switch (widget.type) {
      case 'trash':
        list = _store.trashedNotes;
        break;
      case 'archive':
        list = _store.archivedNotes;
        break;
      default:
        list = _store.notesInFolder(widget.name);
    }
    return _store.sorted(list, _store.defaultSort);
  }

  Color _noteColor(String key) {
    switch (key) {
      case 'red':
        return AppTheme.noteRed;
      case 'orange':
        return AppTheme.noteOrange;
      case 'yellow':
        return AppTheme.noteYellow;
      case 'green':
        return AppTheme.noteGreen;
      case 'blue':
        return AppTheme.noteBlue;
      case 'purple':
        return AppTheme.notePurple;
      case 'pink':
        return AppTheme.notePink;
      case 'gray':
        return AppTheme.noteGray;
      default:
        return AppTheme.noteDefault;
    }
  }

  void _openNote(Map<String, dynamic> note) {
    if (widget.type == 'trash') {
      _showTrashOptions(note);
    } else {
      context.push(AppRoutes.noteEditorScreen, extra: note);
    }
  }

  void _showTrashOptions(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restore_from_trash),
                title: const Text('Restore note'),
                onTap: () {
                  Navigator.pop(ctx);
                  _store.restoreNote('${note['id']}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note restored')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: Color(0xFFB91C1C),
                ),
                title: const Text(
                  'Delete forever',
                  style: TextStyle(color: Color(0xFFB91C1C)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _store.deleteForever('${note['id']}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmEmptyTrash() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Empty Trash?'),
        content: const Text(
          'All notes in Trash will be permanently deleted.',
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
            },
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = _notes;
    final isTrash = widget.type == 'trash';
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (isTrash && notes.isNotEmpty)
            TextButton(
              onPressed: _confirmEmptyTrash,
              child: const Text(
                'Empty',
                style: TextStyle(color: Color(0xFFB91C1C)),
              ),
            ),
        ],
      ),
      body: notes.isEmpty
          ? EmptyStateWidget(
              iconName: isTrash ? 'delete_outline' : 'note_add',
              title: isTrash
                  ? 'Trash is empty'
                  : widget.type == 'archive'
                  ? 'No archived notes'
                  : 'No notes here yet',
              subtitle: isTrash
                  ? 'Deleted notes stay here for 30 days.'
                  : widget.type == 'archive'
                  ? 'Archive a note from its ⋮ menu to keep it out of the way.'
                  : 'Tap + to add a note to this folder.',
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: notes.length,
              itemBuilder: (ctx, i) => NoteCardWidget(
                note: notes[i],
                noteColor: _noteColor('${notes[i]['color']}'),
                onTap: () => _openNote(notes[i]),
              ),
            ),
      floatingActionButton: widget.type == 'folder'
          ? FloatingActionButton(
              onPressed: () => context.push(
                AppRoutes.noteEditorScreen,
                extra: {'folder': widget.name},
              ),
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
