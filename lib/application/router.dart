import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/gameplay/physical/physical_companion_screen.dart';
import '../features/gameplay/physical/physical_session_screen.dart';
import '../features/home/home_screen.dart';
import '../features/recovery/recovery_screen.dart';
import '../features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'match',
            name: 'match',
            builder: (context, state) {
              final extra = state.extra;
              return PhysicalCompanionScreen(
                initial: extra is SetupDraft ? extra : null,
                replaceMatchId: state.uri.queryParameters['replace'],
              );
            },
            routes: [
              GoRoute(
                path: 'play',
                name: 'match-play',
                builder: (context, state) => const PhysicalSessionScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'recovery',
            name: 'recovery',
            builder: (context, state) => const RecoveryScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
