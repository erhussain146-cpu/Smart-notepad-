import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import './widgets/editor_app_bar_widget.dart';
import './widgets/editor_footer_widget.dart';
import './widgets/editor_formatting_toolbar_widget.dart';
import './widgets/editor_metadata_panel_widget.dart';

class NoteEditorScreen extends StatefulWidget {
  /// Either an existing note (has an 'id') or hints for a new note
  /// such as {'folder': 'Work'} or {'isChecklist': true}.
  final Map<String, dynamic>? noteData;

  const NoteEditorScreen({super.key, this.noteData});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with WidgetsBindingObserver {
  final AppStore _store = AppStore.instance;

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _contentFocus;

  String? _noteId;
  bool _isPinned = false;
  bool _isFavorite = false;
  bool _isChecklist = false;
  bool _isArchived = false;
  String _noteColor = 'default';
  String _folder = AppStore.defaultFolder;
  List<String> _tags = [];

  String _saveStatus = 'All changes saved';
  bool _isSaving = false;
  bool _dirty = false;
  Timer? _debounce;

  String _prevTitle = '';
  String _prevContent = '';
  bool _internalChange = false;

  final List<String> _colorKeys = [
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

  final Map<String, Color> _colorMap = {
    'default': AppTheme.noteDefault,
    'red': AppTheme.noteRed,
    'orange': AppTheme.noteOrange,
    'yellow': AppTheme.noteYellow,
    'green': AppTheme.noteGreen,
    'blue': AppTheme.noteBlue,
    'purple': AppTheme.notePurple,
    'pink': AppTheme.notePink,
    'gray': AppTheme.noteGray,
  };

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount => _contentController.text.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final hint = widget.noteData;
    // always read the latest saved copy of an existing note
    final saved = _store.noteById(hint?['id'] as String?);
    final note = saved ?? hint;

    _noteId = saved?['id'] as String?;
    var content = (note?['content'] ?? note?['preview'] ?? '') as String;
    final isNew = _noteId == null;

    _isPinned = note?['isPinned'] == true;
    _isFavorite = note?['isFavorite'] == true;
    _isChecklist = note?['isChecklist'] == true;
    _isArchived = note?['isArchived'] == true;
    _noteColor = (note?['color'] as String?) ?? 'default';
    final f = note?['folder'] as String?;
    _folder = (f != null && _store.folderNames.contains(f))
        ? f
        : AppStore.defaultFolder;
    _tags = ((note?['tags'] as List?) ?? const []).cast<String>().toList();

    if (isNew && _isChecklist && content.isEmpty) content = '☐ ';

    _titleController = TextEditingController(
      text: (note?['title'] as String?) ?? '',
    );
    _contentController = TextEditingController(text: content);
    if (isNew && _isChecklist) {
      _contentController.selection = TextSelection.collapsed(
        offset: content.length,
      );
    }
    _contentFocus = FocusNode();
    _prevTitle = _titleController.text;
    _prevContent = _contentController.text;
    _saveStatus = isNew ? 'New note' : 'All changes saved';

    _contentController.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);

    if (isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _contentFocus.requestFocus();
      });
    }
  }

  // ---------------------------------------------------------------- saving
  void _onTextChanged() {
    if (_internalChange) return;
    final title = _titleController.text;
    final content = _contentController.text;
    if (title == _prevTitle && content == _prevContent) return; // only cursor moved

    if (content != _prevContent) _handleListContinuation();

    _prevTitle = _titleController.text;
    _prevContent = _contentController.text;
    _markDirty();
  }

  void _markDirty() {
    if (!mounted) return;
    _dirty = true;
    if (_store.autosave) {
      setState(() {
        _isSaving = true;
        _saveStatus = 'Saving…';
      });
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 700), _persist);
    } else {
      _debounce?.cancel();
      setState(() => _saveStatus = 'Unsaved changes');
    }
  }

  /// Writes to the store without touching the UI (safe inside dispose).
  Map<String, dynamic>? _commit() {
    _debounce?.cancel();
    final saved = _store.saveNote(
      id: _noteId,
      title: _titleController.text,
      content: _contentController.text,
      color: _noteColor,
      isPinned: _isPinned,
      isFavorite: _isFavorite,
      isChecklist: _isChecklist,
      folder: _folder,
      tags: _tags,
      isArchived: _isArchived,
    );
    if (saved != null) _noteId = saved['id'] as String;
    _dirty = false;
    return saved;
  }

  void _persist({bool showToast = false}) {
    final saved = _commit();
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _saveStatus = saved == null ? 'Nothing to save yet' : 'All changes saved';
    });
    if (showToast) {
      _snack(saved == null ? 'Write something first' : 'Note saved');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _dirty && _store.autosave) {
      _commit();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    if (_dirty && _store.autosave) {
      // copy the values now, save right after this frame (the tree is locked in dispose)
      final id = _noteId;
      final title = _titleController.text;
      final content = _contentController.text;
      final color = _noteColor;
      final pinned = _isPinned;
      final fav = _isFavorite;
      final checklist = _isChecklist;
      final folder = _folder;
      final tags = List<String>.from(_tags);
      final archived = _isArchived;
      final store = _store;
      Future.microtask(() {
        store.saveNote(
          id: id,
          title: title,
          content: content,
          color: color,
          isPinned: pinned,
          isFavorite: fav,
          isChecklist: checklist,
          folder: folder,
          tags: tags,
          isArchived: archived,
        );
      });
    }
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _askSaveOrDiscard() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Save changes?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You have unsaved changes in this note.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'save') {
      _commit();
      Navigator.of(context).pop();
    } else if (choice == 'discard') {
      _dirty = false;
      Navigator.of(context).pop();
    }
  }

  // ------------------------------------------------------------ formatting
  static final RegExp _listPrefix = RegExp(r'^(• |☐ |☑ |\d+\. )');

  void _setText(String text, TextSelection selection) {
    _internalChange = true;
    _contentController.value = TextEditingValue(
      text: text,
      selection: selection,
    );
    _internalChange = false;
    _prevContent = text;
    _markDirty();
  }

  void _wrapSelection(String marker) {
    final text = _contentController.text;
    var sel = _contentController.selection;
    if (!sel.isValid) sel = TextSelection.collapsed(offset: text.length);
    final s = sel.start;
    final e = sel.end;
    final m = marker.length;
    final selected = text.substring(s, e);

    final alreadyWrapped =
        s >= m &&
        e + m <= text.length &&
        text.substring(s - m, s) == marker &&
        text.substring(e, e + m) == marker;

    if (alreadyWrapped) {
      final newText =
          text.substring(0, s - m) + selected + text.substring(e + m);
      _setText(newText, TextSelection(baseOffset: s - m, extentOffset: e - m));
    } else {
      final newText =
          text.substring(0, s) + marker + selected + marker + text.substring(e);
      if (selected.isEmpty) {
        _setText(newText, TextSelection.collapsed(offset: s + m));
      } else {
        _setText(
          newText,
          TextSelection(baseOffset: s + m, extentOffset: e + m),
        );
      }
    }
    _contentFocus.requestFocus();
  }

  void _toggleLinePrefix(String kind) {
    final text = _contentController.text;
    var sel = _contentController.selection;
    if (!sel.isValid) sel = TextSelection.collapsed(offset: text.length);

    final blockStart = sel.start == 0
        ? 0
        : text.lastIndexOf('\n', sel.start - 1) + 1;
    var blockEnd = text.indexOf('\n', sel.end);
    if (blockEnd == -1) blockEnd = text.length;

    final lines = text.substring(blockStart, blockEnd).split('\n');

    RegExp own;
    switch (kind) {
      case 'bullet':
        own = RegExp(r'^• ');
        break;
      case 'numbered':
        own = RegExp(r'^\d+\. ');
        break;
      default:
        own = RegExp(r'^[☐☑] ');
    }

    final allHave = lines.every((l) => own.hasMatch(l));
    final out = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final clean = lines[i].replaceFirst(_listPrefix, '');
      if (allHave) {
        out.add(clean);
      } else if (kind == 'bullet') {
        out.add('• $clean');
      } else if (kind == 'numbered') {
        out.add('${i + 1}. $clean');
      } else {
        out.add('☐ $clean');
      }
    }
    final newBlock = out.join('\n');
    final newText =
        text.substring(0, blockStart) + newBlock + text.substring(blockEnd);
    _setText(
      newText,
      TextSelection.collapsed(offset: blockStart + newBlock.length),
    );
    _contentFocus.requestFocus();
  }

  void _insertFormatting(String tag) {
    switch (tag) {
      case 'bold':
        _wrapSelection('**');
        break;
      case 'italic':
        _wrapSelection('_');
        break;
      case 'underline':
        _wrapSelection('__');
        break;
      case 'strikethrough':
        _wrapSelection('~~');
        break;
      case 'bullet':
        _toggleLinePrefix('bullet');
        break;
      case 'numbered':
        _toggleLinePrefix('numbered');
        break;
      case 'checklist_item':
        _toggleLinePrefix('checklist');
        break;
    }
  }

  /// When the user presses Enter on a list line, continue the list.
  void _handleListContinuation() {
    final text = _contentController.text;
    final sel = _contentController.selection;
    if (text.length != _prevContent.length + 1) return;
    if (!sel.isCollapsed || sel.start < 1) return;
    if (text[sel.start - 1] != '\n') return;
    if (text.replaceRange(sel.start - 1, sel.start, '') != _prevContent) return;

    final lineStart = sel.start >= 2
        ? text.lastIndexOf('\n', sel.start - 2) + 1
        : 0;
    final line = text.substring(lineStart, sel.start - 1);
    final m = RegExp(r'^(• |☐ |☑ |(\d+)\. )(.*)$').firstMatch(line);
    if (m == null) return;

    final prefix = m.group(1)!;
    final rest = m.group(3)!;

    if (rest.trim().isEmpty) {
      // empty list item + Enter = end the list
      final newText = text.substring(0, lineStart) + text.substring(sel.start);
      _internalChange = true;
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: lineStart),
      );
      _internalChange = false;
      return;
    }

    String next;
    if (m.group(2) != null) {
      next = '${int.parse(m.group(2)!) + 1}. ';
    } else if (prefix == '☑ ') {
      next = '☐ ';
    } else {
      next = prefix;
    }
    final newText = text.substring(0, sel.start) + next + text.substring(sel.start);
    _internalChange = true;
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + next.length),
    );
    _internalChange = false;
  }

  /// Tap on a ☐ / ☑ at the start of a line to tick it.
  void _onContentTap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final text = _contentController.text;
      final sel = _contentController.selection;
      if (!sel.isValid || !sel.isCollapsed) return;
      final pos = sel.start;
      final lineStart = pos == 0 ? 0 : text.lastIndexOf('\n', pos - 1) + 1;
      if (lineStart + 1 >= text.length) return;
      final mark = text[lineStart];
      if ((mark == '☐' || mark == '☑') && pos <= lineStart + 1) {
        final flipped = mark == '☐' ? '☑' : '☐';
        final newText = text.replaceRange(lineStart, lineStart + 1, flipped);
        _setText(newText, TextSelection.collapsed(offset: lineStart + 2));
      }
    });
  }

  void _showColorPicker() {
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
                'Note Color',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorKeys.map((key) {
                  final color = _colorMap[key]!;
                  final isSelected = _noteColor == key;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _noteColor = key);
                      Navigator.pop(ctx);
                      _markDirty();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------ menu
  void _showMoreOptions() {
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
                const SizedBox(height: 8),
                _MoreOptionTile(
                  iconName: 'content_copy',
                  label: 'Duplicate Note',
                  onTap: () {
                    Navigator.pop(ctx);
                    _duplicate();
                  },
                ),
                _MoreOptionTile(
                  iconName: 'share',
                  label: 'Copy Note Text',
                  onTap: () {
                    Navigator.pop(ctx);
                    _copyText();
                  },
                ),
                _MoreOptionTile(
                  iconName: 'folder_open',
                  label: 'Move to Folder  ($_folder)',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showFolderPicker();
                  },
                ),
                _MoreOptionTile(
                  iconName: _isArchived ? 'unarchive' : 'archive',
                  label: _isArchived ? 'Unarchive Note' : 'Archive Note',
                  onTap: () {
                    Navigator.pop(ctx);
                    _toggleArchive();
                  },
                ),
                const Divider(height: 1),
                _MoreOptionTile(
                  iconName: 'delete_outline',
                  label: 'Delete Note',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _duplicate() {
    final saved = _commit();
    if (saved == null) {
      _snack('Write something first');
      return;
    }
    _store.duplicateNote(saved['id'] as String);
    setState(() {
      _isSaving = false;
      _saveStatus = 'All changes saved';
    });
    _snack('Note duplicated');
  }

  Future<void> _copyText() async {
    final title = _titleController.text.trim();
    final text = title.isEmpty
        ? _contentController.text
        : '$title\n\n${_contentController.text}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _snack('Note copied to clipboard');
  }

  void _showFolderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move to Folder',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _store.folderNames.map((name) {
                      final selected = name == _folder;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        trailing: selected
                            ? CustomIconWidget(
                                iconName: 'check',
                                color: theme.colorScheme.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _folder = name);
                          _markDirty();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleArchive() {
    _isArchived = !_isArchived;
    if (_isArchived) _isPinned = false;
    final saved = _commit();
    if (saved == null) {
      _isArchived = !_isArchived;
      _snack('Write something first');
      return;
    }
    final msg = _isArchived ? 'Note archived' : 'Note unarchived';
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Note?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This note will be moved to Trash. You can restore it within 30 days.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              Navigator.pop(ctx);
              _debounce?.cancel();
              _dirty = false;
              if (_noteId != null) _store.trashNote(_noteId!);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Moved to Trash')),
              );
            },
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.colorScheme.surface
        : (_colorMap[_noteColor] ?? AppTheme.noteDefault);
    final blockPop = _dirty && !_store.autosave;

    final editorBody = _EditorBody(
      titleController: _titleController,
      contentController: _contentController,
      contentFocus: _contentFocus,
      bgColor: bgColor,
      fontSize: _store.fontSize,
      onContentTap: _onContentTap,
    );

    return PopScope(
      canPop: !blockPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _askSaveOrDiscard();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              EditorAppBarWidget(
                isPinned: _isPinned,
                isFavorite: _isFavorite,
                isSaving: _isSaving,
                onBack: () => Navigator.of(context).maybePop(),
                onSave: () => _persist(showToast: true),
                onPinToggle: () {
                  setState(() => _isPinned = !_isPinned);
                  _markDirty();
                },
                onFavoriteToggle: () {
                  setState(() => _isFavorite = !_isFavorite);
                  _markDirty();
                },
                onColorTap: _showColorPicker,
                onMoreTap: _showMoreOptions,
              ),
              Expanded(
                child: isTablet
                    ? Row(
                        children: [
                          Expanded(flex: 3, child: editorBody),
                          VerticalDivider(
                            width: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          SizedBox(
                            width: 220,
                            child: EditorMetadataPanelWidget(
                              wordCount: _wordCount,
                              charCount: _charCount,
                              isPinned: _isPinned,
                              isFavorite: _isFavorite,
                              folder: _folder,
                              tags: _tags,
                            ),
                          ),
                        ],
                      )
                    : editorBody,
              ),
              EditorFormattingToolbarWidget(
                onFormat: _insertFormatting,
                onChecklistToggle: () {
                  setState(() => _isChecklist = !_isChecklist);
                  _markDirty();
                },
                isChecklist: _isChecklist,
              ),
              EditorFooterWidget(
                saveStatus: _saveStatus,
                isSaving: _isSaving,
                wordCount: _wordCount,
                charCount: _charCount,
                showCounts: _store.showWordCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorBody extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final FocusNode contentFocus;
  final Color bgColor;
  final double fontSize;
  final VoidCallback onContentTap;

  const _EditorBody({
    required this.titleController,
    required this.contentController,
    required this.contentFocus,
    required this.bgColor,
    required this.fontSize,
    required this.onContentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleController,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Note title',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 4),
          Divider(
            color: theme.colorScheme.outlineVariant.withAlpha(102),
            height: 1,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contentController,
            focusNode: contentFocus,
            onTap: onContentTap,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface,
              height: 1.7,
            ),
            decoration: InputDecoration(
              hintText: 'Start writing your note…',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: fontSize,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              contentFocus.requestFocus();
              contentController.selection = TextSelection.collapsed(
                offset: contentController.text.length,
              );
            },
            child: const SizedBox(height: 300, width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _MoreOptionTile extends StatelessWidget {
  final String iconName;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MoreOptionTile({
    required this.iconName,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? AppTheme.errorColor
        : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            CustomIconWidget(iconName: iconName, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}