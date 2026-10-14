import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/app_lock_screen/app_lock_screen.dart';
import '../data/app_store.dart';
import '../presentation/folder_notes_screen/folder_notes_screen.dart';
import '../presentation/folders_screen/folders_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/note_editor_screen/note_editor_screen.dart';
import '../presentation/search_screen/search_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/';
  static const String homeScreen = '/home-screen';
  static const String noteEditorScreen = '/note-editor-screen';
  static const String foldersScreen = '/folders-screen';
  static const String searchScreen = '/search-screen';
  static const String settingsScreen = '/settings-screen';
  static const String appLockScreen = '/app-lock-screen';
  static const String pinSetupScreen = '/pin-setup';
  static const String folderNotesScreen = '/folder-notes';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.homeScreen,
  refreshListenable: AppStore.instance,
  redirect: (context, state) {
    final store = AppStore.instance;
    final loc = state.matchedLocation;
    if (loc == AppRoutes.initial) {
      return store.isLocked ? AppRoutes.appLockScreen : AppRoutes.homeScreen;
    }
    if (store.isLocked && loc != AppRoutes.appLockScreen) {
      return AppRoutes.appLockScreen;
    }
    if (!store.isLocked && loc == AppRoutes.appLockScreen) {
      return AppRoutes.homeScreen;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      redirect: (context, state) => AppRoutes.homeScreen,
      builder: (context, state) => const SizedBox.shrink(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.foldersScreen,
              builder: (context, state) => const FoldersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.searchScreen,
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settingsScreen,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.noteEditorScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: NoteEditorScreen(noteData: extra),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.appLockScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AppLockScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.pinSetupScreen,
      builder: (context, state) => const AppLockScreen(setupMode: true),
    ),
    GoRoute(
      path: AppRoutes.folderNotesScreen,
      builder: (context, state) {
        final extra = (state.extra as Map<String, dynamic>?) ?? {};
        return FolderNotesScreen(
          type: (extra['type'] as String?) ?? 'folder',
          name: (extra['name'] as String?) ?? '',
        );
      },
    ),
  ],
);
