import 'package:flutter/material.dart';
import 'package:flutter_bottle_match/app.dart';
import 'package:flutter_bottle_match/application/providers.dart';
import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/features/gameplay/physical/physical_companion_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/match_fixtures.dart';
import 'support/memory_repositories.dart';

void main() {
  testWidgets('back moves through setup, then home', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('new-game')));
    await tester.pumpAndSettle();
    await _tap(tester, 'continue-to-rules');
    await _tap(tester, 'continue-to-review');

    await _back(tester);
    expect(find.text('Match settings'), findsOneWidget);
    expect(find.text('New game'), findsNothing);

    await _back(tester);
    expect(find.text('Players'), findsOneWidget);
    expect(find.text('New game'), findsNothing);

    await _back(tester);
    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Players'), findsNothing);
  });

  testWidgets('back from a match returns to the page that opened it', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('new-game')));
    await tester.pumpAndSettle();
    await _tap(tester, 'continue-to-rules');
    await _tap(tester, 'continue-to-review');
    await _tap(tester, 'start-match');

    expect(find.byKey(const Key('begin-round')), findsOneWidget);
    await _back(tester);

    expect(find.text('Play game'), findsOneWidget);
    expect(find.text('New game'), findsNothing);
  });

  testWidgets('back from a recovered match returns to recovery', (
    tester,
  ) async {
    await _pump(
      tester,
      matches: MemoryMatchRepository()..active = sampleMatch(),
    );

    await tester.tap(find.byKey(const Key('continue-saved-match')));
    await tester.pumpAndSettle();
    await _tap(tester, 'resume-saved-match');
    expect(find.byKey(const Key('begin-round')), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);

    await _back(tester);

    expect(find.textContaining('not reshuffled'), findsOneWidget);
    expect(find.text('Players'), findsNothing);
    expect(find.text('New game'), findsNothing);
  });

  testWidgets('back from settings returns home', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await _back(tester);

    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('back from replaced setup still returns home', (tester) async {
    await _pump(tester);
    final context = tester.element(find.text('New game'));
    GoRouter.of(context).go(
      '/match',
      extra: SetupDraft(
        roster: sampleMatch().roster,
        settings: const MatchSettings(physicalEquipmentConfirmed: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Players'), findsOneWidget);
    await _back(tester);

    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Players'), findsNothing);
  });
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  MemoryMatchRepository? matches,
}) async {
  tester.view.physicalSize = const Size(500, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchRepositoryProvider.overrideWithValue(
          matches ?? MemoryMatchRepository(),
        ),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
      ],
      child: const ColorfulBottleMatchApp(),
    ),
  );
  await tester.pumpAndSettle();
}
