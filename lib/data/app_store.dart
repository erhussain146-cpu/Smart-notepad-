import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for notes, folders and settings.
/// Everything is saved on the phone using SharedPreferences.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  static const List<String> sortOptions = [
    'Modified',
    'Created',
    'Title A–Z',
    'Title Z–A',
    'Color',
  ];

  static const Map<String, int> lockTimeouts = {
    'Immediately': 0,
    '30 seconds': 30,
    '1 minute': 60,
    '5 minutes': 300,
    'Never': -1,
  };

  static const List<String> _colorOrder = [
    'default',
    'red',
    'orange',
    'yellow',
    'green',
    'blue',
    'purple',
    'pink',
    'gray',
  ];

  static const String defaultFolder = 'Personal';

  SharedPreferences? _prefs;
  bool ready = false;

  final List<Map<String, dynamic>> _notes = [];
  final List<Map<String, dynamic>> _folders = [];
  final List<String> _recentSearches = [];

  // ---- settings ----
  String themeMode = 'System';
  String defaultView = 'List';
  String defaultSort = 'Modified';
  double fontSize = 16;
  bool showWordCount = true;
  bool autosave = true;
  bool appLockEnabled = false;
  bool biometricEnabled = false;
  String lockTimeout = '1 minute';
  String? _pinHash;

  // ---- lock state ----
  bool isLocked = false;
  bool authInProgress = false;

  // =====================================================================
  // INIT / PERSIST
  // =====================================================================
  Future<void> init() async {
    if (ready) return;
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    // settings
    try {
      final raw = prefs.getString('settings_v1');
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        themeMode = (m['themeMode'] ?? themeMode) as String;
        defaultView = (m['defaultView'] ?? defaultView) as String;
        defaultSort = (m['defaultSort'] ?? defaultSort) as String;
        fontSize = ((m['fontSize'] ?? fontSize) as num).toDouble();
        showWordCount = (m['showWordCount'] ?? showWordCount) as bool;
        autosave = (m['autosave'] ?? autosave) as bool;
        appLockEnabled = (m['appLockEnabled'] ?? appLockEnabled) as bool;
        biometricEnabled = (m['biometricEnabled'] ?? biometricEnabled) as bool;
        lockTimeout = (m['lockTimeout'] ?? lockTimeout) as String;
      }
    } catch (_) {}
    if (!sortOptions.contains(defaultSort)) defaultSort = 'Modified';
    if (!lockTimeouts.containsKey(lockTimeout)) lockTimeout = '1 minute';
    _pinHash = prefs.getString('pin_hash');

    // folders
    final foldersRaw = prefs.getString('folders_v1');
    if (foldersRaw != null) {
      try {
        _folders.addAll(_decodeList(foldersRaw));
      } catch (_) {}
    }
    if (_folders.isEmpty) _folders.addAll(_defaultFolders());

    // notes
    final notesRaw = prefs.getString('notes_v1');
    if (notesRaw != null) {
      try {
        _notes.addAll(_decodeList(notesRaw));
      } catch (_) {}
    } else {
      _notes.add(_welcomeNote());
      _saveNotes();
    }

    // recent searches
    _recentSearches.addAll(prefs.getStringList('recent_searches') ?? []);

    // auto purge trash older than 30 days
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final before = _notes.length;
    _notes.removeWhere((n) {
      if (n['isTrashed'] != true) return false;
      final t = DateTime.tryParse('${n['trashedAt'] ?? ''}');
      return t != null && t.isBefore(cutoff);
    });
    if (before != _notes.length) _saveNotes();

    isLocked = appLockEnabled && hasPin;
    ready = true;
    notifyListeners();
  }

  List<Map<String, dynamic>> _decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: true);
  }

  List<Map<String, dynamic>> _defaultFolders() => [
    {'id': 'f1', 'name': 'Personal', 'color': 'blue', 'isSystem': true, 'icon': 'person_outline'},
    {'id': 'f2', 'name': 'Work', 'color': 'purple', 'isSystem': true, 'icon': 'work_outline'},
    {'id': 'f3', 'name': 'Study', 'color': 'green', 'isSystem': true, 'icon': 'school_outlined'},
    {'id': 'f4', 'name': 'Ideas', 'color': 'yellow', 'isSystem': true, 'icon': 'lightbulb_outline'},
    {'id': 'f5', 'name': 'Shopping', 'color': 'orange', 'isSystem': true, 'icon': 'shopping_cart_outlined'},
    {'id': 'f6', 'name': 'Other', 'color': 'gray', 'isSystem': true, 'icon': 'folder_outlined'},
  ];

  Map<String, dynamic> _welcomeNote() {
    final now = DateTime.now().toIso8601String();
    const content =
        'Welcome to SmartNotepad!\n\n'
        '• Tap New Note to write something\n'
        '• Pin or favorite notes from the top bar\n'
        '• Put notes in folders, lock the app with a PIN\n\n'
        '☐ Try a checklist item\n'
        '☐ Create your first folder';
    return {
      'id': 'welcome',
      'title': 'Welcome 👋',
      'content': content,
      'preview': _makePreview(content),
      'color': 'yellow',
      'isPinned': true,
      'isFavorite': false,
      'isChecklist': false,
      'isArchived': false,
      'isTrashed': false,
      'createdAt': now,
      'modifiedAt': now,
      'wordCount': _wordCount(content),
      'tags': <String>[],
      'folder': defaultFolder,
    };
  }

  void _saveNotes() {
    _prefs?.setString('notes_v1', jsonEncode(_notes));
  }

  void _saveFolders() {
    _prefs?.setString('folders_v1', jsonEncode(_folders));
  }

  void _saveSettings() {
    _prefs?.setString(
      'settings_v1',
      jsonEncode({
        'themeMode': themeMode,
        'defaultView': defaultView,
        'defaultSort': defaultSort,
        'fontSize': fontSize,
        'showWordCount': showWordCount,
        'autosave': autosave,
        'appLockEnabled': appLockEnabled,
        'biometricEnabled': biometricEnabled,
        'lockTimeout': lockTimeout,
      }),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================
  static int _wordCount(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  static String _makePreview(String content) {
    final flat = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length > 200 ? '${flat.substring(0, 200)}…' : flat;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // =====================================================================
  // NOTES
  // =====================================================================
  List<Map<String, dynamic>> get activeNotes => _notes
      .where((n) => n['isTrashed'] != true && n['isArchived'] != true)
      .toList();

  List<Map<String, dynamic>> get archivedNotes => _notes
      .where((n) => n['isTrashed'] != true && n['isArchived'] == true)
      .toList();

  List<Map<String, dynamic>> get trashedNotes =>
      _notes.where((n) => n['isTrashed'] == true).toList();

  List<Map<String, dynamic>> notesInFolder(String folder) =>
      activeNotes.where((n) => n['folder'] == folder).toList();

  Map<String, dynamic>? noteById(String? id) {
    if (id == null) return null;
    for (final n in _notes) {
      if (n['id'] == id) return n;
    }
    return null;
  }

  List<Map<String, dynamic>> sorted(
    List<Map<String, dynamic>> list,
    String sortBy,
  ) {
    final out = List<Map<String, dynamic>>.from(list);
    int cmpDate(String key, Map a, Map b) =>
        '${b[key] ?? ''}'.compareTo('${a[key] ?? ''}');
    String title(Map n) => '${n['title'] ?? ''}'.toLowerCase();
    switch (sortBy) {
      case 'Created':
        out.sort((a, b) => cmpDate('createdAt', a, b));
        break;
      case 'Title A–Z':
        out.sort((a, b) => title(a).compareTo(title(b)));
        break;
      case 'Title Z–A':
        out.sort((a, b) => title(b).compareTo(title(a)));
        break;
      case 'Color':
        out.sort((a, b) {
          final ia = _colorOrder.indexOf('${a['color']}');
          final ib = _colorOrder.indexOf('${b['color']}');
          return ia.compareTo(ib);
        });
        break;
      default:
        out.sort((a, b) => cmpDate('modifiedAt', a, b));
    }
    return out;
  }

  /// Creates a new note (id == null) or updates one.
  /// Returns null when there is nothing to save (empty new note).
  Map<String, dynamic>? saveNote({
    String? id,
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    required bool isFavorite,
    required bool isChecklist,
    required String folder,
    List<String> tags = const [],
    bool isArchived = false,
  }) {
    final existing = noteById(id);
    final isEmpty = title.trim().isEmpty && content.trim().isEmpty;
    if (existing == null && isEmpty) return null;

    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'title': title.trim(),
      'content': content,
      'preview': _makePreview(content),
      'color': color,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'isChecklist': isChecklist,
      'isArchived': isArchived,
      'modifiedAt': now,
      'wordCount': _wordCount(content),
      'tags': tags,
      'folder': folder,
    };

    Map<String, dynamic> result;
    if (existing != null) {
      existing.addAll(data);
      result = existing;
    } else {
      result = {
        'id': _newId(),
        'createdAt': now,
        'isTrashed': false,
        ...data,
      };
      _notes.add(result);
    }
    _saveNotes();
    notifyListeners();
    return result;
  }

  Map<String, dynamic>? duplicateNote(String id) {
    final n = noteById(id);
    if (n == null) return null;
    final now = DateTime.now().toIso8601String();
    final copy = Map<String, dynamic>.from(n);
    copy['id'] = _newId();
    copy['title'] = '${n['title'] ?? ''} (copy)'.trim();
    copy['createdAt'] = now;
    copy['modifiedAt'] = now;
    copy['isPinned'] = false;
    copy['tags'] = List<String>.from((n['tags'] as List?) ?? const []);
    _notes.add(copy);
    _saveNotes();
    notifyListeners();
    return copy;
  }

  void trashNote(String id) {
    final n = noteById(id);
    if (n == null) return;
    n['isTrashed'] = true;
    n['isPinned'] = false;
    n['trashedAt'] = DateTime.now().toIso8601String();
    _saveNotes();
    notifyListeners();
  }

  void restoreNote(String id) {
    final n = noteById(id);
    if (n == null) return;
    n['isTrashed'] = false;
    n.remove('trashedAt');
    n['modifiedAt'] = DateTime.now().toIso8601String();
    _saveNotes();
    notifyListeners();
  }

  void deleteForever(String id) {
    _notes.removeWhere((n) => n['id'] == id);
    _saveNotes();
    notifyListeners();
  }

  int emptyTrash() {
    final count = _notes.where((n) => n['isTrashed'] == true).length;
    _notes.removeWhere((n) => n['isTrashed'] == true);
    _saveNotes();
    notifyListeners();
    return count;
  }

  void setArchived(String id, bool value) {
    final n = noteById(id);
    if (n == null) return;
    n['isArchived'] = value;
    if (value) n['isPinned'] = false;
    _saveNotes();
    notifyListeners();
  }

  // =====================================================================
  // FOLDERS
  // =====================================================================
  List<Map<String, dynamic>> get folders {
    return _folders.map((f) {
      final copy = Map<String, dynamic>.from(f);
      copy['noteCount'] = notesInFolder('${f['name']}').length;
      return copy;
    }).toList();
  }

  List<String> get folderNames => _folders.map((f) => '${f['name']}').toList();

  bool folderExists(String name, {String? exceptId}) {
    final n = name.trim().toLowerCase();
    return _folders.any(
      (f) => f['id'] != exceptId && '${f['name']}'.toLowerCase() == n,
    );
  }

  bool createFolder(String name, String colorKey) {
    final clean = name.trim();
    if (clean.isEmpty || folderExists(clean)) return false;
    _folders.add({
      'id': 'f${_newId()}',
      'name': clean,
      'color': colorKey,
      'isSystem': false,
      'icon': 'folder_outlined',
    });
    _saveFolders();
    notifyListeners();
    return true;
  }

  bool renameFolder(String id, String newName) {
    final clean = newName.trim();
    if (clean.isEmpty || folderExists(clean, exceptId: id)) return false;
    final f = _folders.firstWhere((x) => x['id'] == id, orElse: () => {});
    if (f.isEmpty) return false;
    final old = '${f['name']}';
    f['name'] = clean;
    for (final n in _notes) {
      if (n['folder'] == old) n['folder'] = clean;
    }
    _saveFolders();
    _saveNotes();
    notifyListeners();
    return true;
  }

  void deleteFolder(String id, {required bool deleteNotes}) {
    final f = _folders.firstWhere((x) => x['id'] == id, orElse: () => {});
    if (f.isEmpty) return;
    final name = '${f['name']}';
    for (final n in _notes) {
      if (n['folder'] != name) continue;
      if (deleteNotes) {
        if (n['isTrashed'] != true) {
          n['isTrashed'] = true;
          n['isPinned'] = false;
          n['trashedAt'] = DateTime.now().toIso8601String();
        }
      } else {
        n['folder'] = 'Other';
      }
    }
    _folders.removeWhere((x) => x['id'] == id);
    _saveFolders();
    _saveNotes();
    notifyListeners();
  }

  // =====================================================================
  // SEARCH HISTORY
  // =====================================================================
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  void addRecentSearch(String term) {
    final t = term.trim();
    if (t.isEmpty) return;
    _recentSearches.removeWhere((x) => x.toLowerCase() == t.toLowerCase());
    _recentSearches.insert(0, t);
    if (_recentSearches.length > 8) _recentSearches.removeLast();
    _prefs?.setStringList('recent_searches', _recentSearches);
    notifyListeners();
  }

  void removeRecentSearch(String term) {
    _recentSearches.remove(term);
    _prefs?.setStringList('recent_searches', _recentSearches);
    notifyListeners();
  }

  // =====================================================================
  // SETTINGS
  // =====================================================================
  ThemeMode get materialThemeMode {
    switch (themeMode) {
      case 'Dark':
        return ThemeMode.dark;
      case 'Light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(String v) {
    themeMode = v;
    _saveSettings();
    notifyListeners();
  }

  void setDefaultView(String v) {
    defaultView = v;
    _saveSettings();
    notifyListeners();
  }

  void setDefaultSort(String v) {
    defaultSort = v;
    _saveSettings();
    notifyListeners();
  }

  void setFontSize(double v) {
    fontSize = v;
    _saveSettings();
    notifyListeners();
  }

  void setShowWordCount(bool v) {
    showWordCount = v;
    _saveSettings();
    notifyListeners();
  }

  void setAutosave(bool v) {
    autosave = v;
    _saveSettings();
    notifyListeners();
  }

  void setLockTimeout(String v) {
    lockTimeout = v;
    _saveSettings();
    notifyListeners();
  }

  void setBiometricEnabled(bool v) {
    biometricEnabled = v;
    _saveSettings();
    notifyListeners();
  }

  // =====================================================================
  // APP LOCK
  // =====================================================================
  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;

  String _hash(String pin) =>
      sha256.convert(utf8.encode('smartnotepad::$pin')).toString();

  bool verifyPin(String pin) => hasPin && _pinHash == _hash(pin);

  /// Saves a new PIN and turns App Lock on.
  void setPin(String pin) {
    _pinHash = _hash(pin);
    _prefs?.setString('pin_hash', _pinHash!);
    appLockEnabled = true;
    _saveSettings();
    notifyListeners();
  }

  void disableAppLock() {
    appLockEnabled = false;
    biometricEnabled = false;
    isLocked = false;
    _saveSettings();
    notifyListeners();
  }

  void enableAppLock() {
    if (!hasPin) return;
    appLockEnabled = true;
    _saveSettings();
    notifyListeners();
  }

  void lock() {
    if (!appLockEnabled || !hasPin) return;
    isLocked = true;
    notifyListeners();
  }

  void unlock() {
    isLocked = false;
    notifyListeners();
  }

  /// Called when the app comes back to the foreground.
  void checkAutoLock(DateTime? pausedAt) {
    if (!appLockEnabled || !hasPin || isLocked || authInProgress) return;
    final secs = lockTimeouts[lockTimeout] ?? 60;
    if (secs < 0 || pausedAt == null) return;
    if (DateTime.now().difference(pausedAt).inSeconds >= secs) lock();
  }

  // =====================================================================
  // BACKUP / EXPORT
  // =====================================================================
  String exportBackupJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'SmartNotepad',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'folders': _folders,
      'notes': _notes,
    });
  }

  /// Merges a backup into the current data. Returns an error text or null.
  String? importBackupJson(String raw) {
    try {
      final data = jsonDecode(raw.trim());
      if (data is! Map || data['notes'] is! List) {
        return 'This is not a SmartNotepad backup.';
      }
      var added = 0;
      for (final item in (data['notes'] as List)) {
        final n = Map<String, dynamic>.from(item as Map);
        if (n['id'] == null) continue;
        final idx = _notes.indexWhereId(n["id"]);
        if (idx >= 0) {
          _notes[idx] = n;
        } else {
          _notes.add(n);
          added++;
        }
      }
      if (data['folders'] is List) {
        for (final item in (data['folders'] as List)) {
          final f = Map<String, dynamic>.from(item as Map);
          final name = '${f['name'] ?? ''}';
          if (name.isEmpty || folderExists(name)) continue;
          _folders.add(f);
        }
      }
      _saveNotes();
      _saveFolders();
      notifyListeners();
      return added == 0 && (data['notes'] as List).isEmpty
          ? 'Backup has no notes.'
          : null;
    } catch (_) {
      return 'Could not read the backup. Please paste the full text.';
    }
  }

  String exportAllNotesText() {
    final buf = StringBuffer();
    final list = sorted(activeNotes + archivedNotes, 'Modified');
    for (final n in list) {
      buf.writeln('# ${(n['title'] as String?)?.isNotEmpty == true ? n['title'] : 'Untitled'}');
      buf.writeln('Folder: ${n['folder']}');
      buf.writeln();
      buf.writeln('${n['content'] ?? n['preview'] ?? ''}');
      buf.writeln();
      buf.writeln('------------------------------');
      buf.writeln();
    }
    return buf.toString().trim();
  }
}

extension _NoteListX on List<Map<String, dynamic>> {
  int indexWhereId(dynamic id) => indexWhere((n) => n['id'] == id);
}
