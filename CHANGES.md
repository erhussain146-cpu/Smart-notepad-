# SmartNotepad - fixes

Root problem: the app was a UI prototype. Notes, folders and settings were
hard-coded demo data and most buttons were empty. Now everything is real and
saved on the phone (SharedPreferences) through `lib/data/app_store.dart`.

## Fixed
- Notes: create, edit, save, delete (Trash, 30 days), restore, duplicate, archive, pin, favorite, color, move to folder
- Autosave ON: saves while typing. Autosave OFF: shows "Unsaved changes", Save button works, asks before leaving
- Word/char count in editor hides when "Show Word Count" is OFF
- Font size setting now changes the editor text size
- Formatting: bold/italic/underline/strike toggle properly, bullet/numbered/checklist work on lines,
  Enter continues the list, tap on a checkbox to tick it
- Folders: create, rename, delete, open folder to see its notes, Archived and Trash views, real note counts
- Search: searches real notes (title, text, folder, tags), filters work, recent searches saved
- Theme (Light/Dark/System), Default View, Default Sort now apply
- App Lock: real PIN (set / change / verify, stored hashed), lockout after 5 wrong tries,
  auto-lock timer, lock-now button on home, fingerprint/face unlock (local_auth)
- Removed the "recovery option" button that skipped the PIN
- Backup: Export copies a backup to clipboard, Restore pastes it back (merge), Export All Notes copies plain text
- Performance: icon table was rebuilt on every icon draw, now built once
- Removed buttons that did nothing (align, image, mic, reminders, rate/share/support, PDF export)

## Build
flutter pub get
flutter build apk --release
