import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/gameplay/digital/digital_mode_screen.dart';
import '../features/gameplay/physical/physical_companion_screen.dart';
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
      ),
      GoRoute(
        path: '/physical',
        name: 'physical',
        builder: (context, state) => const PhysicalCompanionScreen(),
      ),
      GoRoute(
        path: '/digital',
        name: 'digital',
        builder: (context, state) => const DigitalModeScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/recovery',
        name: 'recovery',
        builder: (context, state) => const RecoveryScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
