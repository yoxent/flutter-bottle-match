import 'package:flutter/material.dart';
import 'package:flutter_bottle_match/app.dart';
import 'package:flutter_bottle_match/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/match_fixtures.dart';
import 'support/memory_repositories.dart';

void main() {
  testWidgets('home offers both modes and marks digital as unavailable', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Colorful Bottle Match'), findsOneWidget);
    expect(find.text('Physical Companion'), findsOneWidget);
    expect(find.text('Fully Digital'), findsOneWidget);
    expect(find.text('Star'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fully-digital')));
    await tester.pumpAndSettle();

    expect(find.text('Not implemented'), findsOneWidget);
    expect(find.textContaining('proposed'), findsOneWidget);
  });

  testWidgets('settings changes reduced motion', (tester) async {
    final settings = MemorySettingsRepository();
    await _pumpApp(tester, settings: settings);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reduced motion'));
    await tester.pumpAndSettle();

    expect(settings.value.reducedMotion, isTrue);
  });

  testWidgets('an in-progress match opens as paused recovery', (tester) async {
    final matches = MemoryMatchRepository()..active = sampleMatch();
    await _pumpApp(tester, matches: matches);

    expect(find.byKey(const Key('continue-saved-match')), findsOneWidget);
    expect(matches.active!.phase.name, 'paused');

    await tester.tap(find.byKey(const Key('continue-saved-match')));
    await tester.pumpAndSettle();

    expect(find.textContaining('not reshuffled'), findsOneWidget);
    expect(find.textContaining('Maya, Leo'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  MemoryMatchRepository? matches,
  MemorySettingsRepository? settings,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchRepositoryProvider.overrideWithValue(
          matches ?? MemoryMatchRepository(),
        ),
        settingsRepositoryProvider.overrideWithValue(
          settings ?? MemorySettingsRepository(),
        ),
      ],
      child: const ColorfulBottleMatchApp(),
    ),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}
