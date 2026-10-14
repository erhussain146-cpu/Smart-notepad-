import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/empty_state_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/search_filter_chips_widget.dart';
import './widgets/search_recent_widget.dart';
import './widgets/search_result_card_widget.dart';

// TODO: Replace with [Riverpod/Bloc] for production — search state management
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  String _activeFilter = 'All';

  final List<String> _filters = [
    'All',
    'Favorites',
    'Pinned',
    'Checklists',
    'Archived',
  ];

  final AppStore _store = AppStore.instance;

  List<Map<String, dynamic>> get _filteredNotes {
    var notes = _activeFilter == 'Archived'
        ? _store.archivedNotes
        : _store.activeNotes;
    if (_activeFilter == 'Favorites') {
      notes = notes.where((n) => n['isFavorite'] == true).toList();
    } else if (_activeFilter == 'Pinned') {
      notes = notes.where((n) => n['isPinned'] == true).toList();
    } else if (_activeFilter == 'Checklists') {
      notes = notes.where((n) => n['isChecklist'] == true).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      notes = notes.where((n) {
        return '${n['title'] ?? ''}'.toLowerCase().contains(q) ||
            '${n['content'] ?? n['preview'] ?? ''}'.toLowerCase().contains(
              q,
            ) ||
            '${n['folder'] ?? ''}'.toLowerCase().contains(q) ||
            ((n['tags'] as List?) ?? const []).any(
              (t) => '$t'.toLowerCase().contains(q),
            );
      }).toList();
    }
    return _store.sorted(notes, 'Modified');
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

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _filteredNotes;
    final showRecent = _query.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed search bar
            SearchBarWidget(
              controller: _searchController,
              focusNode: _searchFocus,
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              onSubmitted: (v) => _store.addRecentSearch(v),
            ),
            // Filter chips
            SearchFilterChipsWidget(
              filters: _filters,
              activeFilter: _activeFilter,
              onFilterSelected: (f) => setState(() => _activeFilter = f),
            ),
            // Results or recent
            Expanded(
              child: showRecent
                  ? SearchRecentWidget(
                      recentSearches: _store.recentSearches,
                      onSearchTap: (term) {
                        _searchController.text = term;
                        setState(() => _query = term);
                      },
                      onRemove: (term) {
                        _store.removeRecentSearch(term);
                      },
                    )
                  : results.isEmpty
                  ? EmptyStateWidget(
                      iconName: 'search_off',
                      title: 'No notes found',
                      subtitle:
                          'Try different keywords or clear filters to broaden your search.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => SearchResultCardWidget(
                        note: results[i],
                        query: _query,
                        noteColor: _noteColor(results[i]['color']),
                        onTap: () {
                          _store.addRecentSearch(_query);
                          context.push(
                            AppRoutes.noteEditorScreen,
                            extra: results[i],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
