import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/empty_state_widget.dart';
import './widgets/home_header_widget.dart';
import './widgets/home_quick_actions_widget.dart';
import './widgets/home_section_header_widget.dart';
import './widgets/home_view_toggle_widget.dart';
import './widgets/note_card_widget.dart';

// TODO: Replace with [Riverpod/Bloc] for production — note state management
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnim;

  final AppStore _store = AppStore.instance;

  bool get _isGridView => _store.defaultView == 'Grid';
  String get _sortBy => _store.defaultSort;

  List<Map<String, dynamic>> get _pinnedNotes => _store.sorted(
    _store.activeNotes.where((n) => n['isPinned'] == true).toList(),
    _sortBy,
  );

  List<Map<String, dynamic>> get _favoriteNotes => _store.sorted(
    _store.activeNotes
        .where((n) => n['isFavorite'] == true && n['isPinned'] != true)
        .toList(),
    _sortBy,
  );

  List<Map<String, dynamic>> get _recentNotes => _store.sorted(
    _store.activeNotes.where((n) => n['isPinned'] != true).toList(),
    _sortBy,
  );

  Color _noteColor(String colorKey) {
    switch (colorKey) {
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

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fabScaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _fabController.dispose();
    super.dispose();
  }

  void _openNoteEditor({Map<String, dynamic>? note}) {
    context.push(AppRoutes.noteEditorScreen, extra: note);
  }

  void _onLockTap() {
    if (_store.appLockEnabled && _store.hasPin) {
      _store.lock();
    } else {
      context.push(AppRoutes.pinSetupScreen);
    }
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final options = AppStore.sortOptions;
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
                'Sort Notes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (opt) => InkWell(
                  onTap: () {
                    _store.setDefaultSort(opt);
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
                              fontWeight: _sortBy == opt
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _sortBy == opt
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (_sortBy == opt)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeaderWidget(
                noteCount: _store.activeNotes.length,
                onSearchTap: () => context.go(AppRoutes.searchScreen),
                onSettingsTap: () => context.go(AppRoutes.settingsScreen),
                onLockTap: _onLockTap,
              ),
            ),
            SliverToBoxAdapter(
              child: HomeQuickActionsWidget(
                onNewNote: () => _openNoteEditor(),
                onNewChecklist: () =>
                    _openNoteEditor(note: {'isChecklist': true}),
              ),
            ),
            // Pinned notes
            if (_pinnedNotes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: HomeSectionHeaderWidget(
                  title: 'Pinned',
                  count: _pinnedNotes.length,
                  icon: 'push_pin',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                sliver: isTablet
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.6,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => NoteCardWidget(
                            note: _pinnedNotes[i],
                            noteColor: _noteColor(_pinnedNotes[i]['color']),
                            onTap: () => _openNoteEditor(note: _pinnedNotes[i]),
                          ),
                          childCount: _pinnedNotes.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NoteCardWidget(
                              note: _pinnedNotes[i],
                              noteColor: _noteColor(_pinnedNotes[i]['color']),
                              onTap: () =>
                                  _openNoteEditor(note: _pinnedNotes[i]),
                            ),
                          ),
                          childCount: _pinnedNotes.length,
                        ),
                      ),
              ),
            ],
            // Favorites
            if (_favoriteNotes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: HomeSectionHeaderWidget(
                  title: 'Favorites',
                  count: _favoriteNotes.length,
                  icon: 'favorite',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                sliver: isTablet
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.6,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => NoteCardWidget(
                            note: _favoriteNotes[i],
                            noteColor: _noteColor(_favoriteNotes[i]['color']),
                            onTap: () =>
                                _openNoteEditor(note: _favoriteNotes[i]),
                          ),
                          childCount: _favoriteNotes.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NoteCardWidget(
                              note: _favoriteNotes[i],
                              noteColor: _noteColor(_favoriteNotes[i]['color']),
                              onTap: () =>
                                  _openNoteEditor(note: _favoriteNotes[i]),
                            ),
                          ),
                          childCount: _favoriteNotes.length,
                        ),
                      ),
              ),
            ],
            // All recent notes
            SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: HomeSectionHeaderWidget(
                      title: 'All Notes',
                      count: _recentNotes.length,
                      icon: 'notes',
                    ),
                  ),
                  HomeViewToggleWidget(
                    isGridView: _isGridView,
                    sortLabel: _sortBy,
                    onToggleView: () {
                      _store.setDefaultView(_isGridView ? 'List' : 'Grid');
                    },
                    onSortTap: _showSortMenu,
                  ),
                ],
              ),
            ),
            _recentNotes.isEmpty
                ? SliverFillRemaining(
                    child: EmptyStateWidget(
                      iconName: 'note_add',
                      title: 'No notes yet',
                      subtitle:
                          'Tap + below to create your first note. Your ideas deserve a home.',
                      actionLabel: 'Create Note',
                      onAction: () => _openNoteEditor(),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    sliver: _isGridView || isTablet
                        ? SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isTablet ? 3 : 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.4,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => NoteCardWidget(
                                note: _recentNotes[i],
                                noteColor: _noteColor(_recentNotes[i]['color']),
                                onTap: () =>
                                    _openNoteEditor(note: _recentNotes[i]),
                              ),
                              childCount: _recentNotes.length,
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: NoteCardWidget(
                                  note: _recentNotes[i],
                                  noteColor: _noteColor(
                                    _recentNotes[i]['color'],
                                  ),
                                  onTap: () =>
                                      _openNoteEditor(note: _recentNotes[i]),
                                ),
                              ),
                              childCount: _recentNotes.length,
                            ),
                          ),
                  ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: FloatingActionButton.extended(
          onPressed: () {
            _fabController.forward().then((_) => _fabController.reverse());
            _openNoteEditor();
          },
          icon: CustomIconWidget(
            iconName: 'add_rounded',
            color: Colors.white,
            size: 22,
          ),
          label: Text(
            'New Note',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: theme.colorScheme.primary,
          elevation: 4,
        ),
      ),
    );
  }
}
