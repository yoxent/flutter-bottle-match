import 'package:flutter/material.dart';
import 'package:flutter_bottle_match/app.dart';
import 'package:flutter_bottle_match/application/providers.dart';
import 'package:flutter_bottle_match/design_system/components/buttons/game_switch.dart';
import 'package:flutter_bottle_match/design_system/tokens/colors.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_bottle_match/domain/rules/match_constraints.dart';
import 'package:flutter_bottle_match/features/gameplay/physical/player_faces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'support/match_fixtures.dart';
import 'support/memory_repositories.dart';

void main() {
  test('players use the first twelve piece colors', () {
    expect(bottleColors, hasLength(MatchConstraints.maxBottles));
    expect(bottleColors.toSet(), hasLength(bottleColors.length));
    expect(playerColors, bottleColors.sublist(0, MatchConstraints.maxPlayers));
  });

  testWidgets('a player icon is chosen from the panel', (tester) async {
    await _pump(tester, MemoryMatchRepository());
    await tester.tap(find.byKey(const Key('new-game')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Avatar:'), findsNothing);
    await tester.tap(find.byKey(const Key('player-icon-0')));
    await tester.pumpAndSettle();

    expect(find.byIcon(FLucideIcons.candyCane), findsNothing);
    expect(find.byKey(const Key('icon-category-more-left')), findsNothing);
    expect(find.byKey(const Key('icon-category-more-right')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('icon-category-more-right'))).left,
      greaterThanOrEqualTo(
        tester.getRect(find.byKey(const Key('icon-category-scroll'))).right,
      ),
    );
    await tester.drag(
      find.byKey(const Key('icon-category-scroll')),
      const Offset(-800, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('icon-category-more-left')), findsOneWidget);
    expect(find.byKey(const Key('icon-category-more-right')), findsNothing);
    expect(
      tester.getRect(find.byKey(const Key('icon-category-more-left'))).right,
      lessThanOrEqualTo(
        tester.getRect(find.byKey(const Key('icon-category-scroll'))).left,
      ),
    );
    await tester.drag(
      find.byKey(const Key('icon-category-scroll')),
      const Offset(800, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('icon-category-more-left')), findsNothing);
    expect(find.byKey(const Key('icon-category-more-right')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('icon-category-Animals'))).dx,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('icon-category-Emoji'))).dx,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('icon-category-Emoji'))).dx,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('icon-category-Food'))).dx,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('icon-category-bar'))).dy,
      greaterThan(
        tester.getBottomLeft(find.byKey(const Key('icon-category-Animals'))).dy,
      ),
    );
    expect(
      tester.getBottomLeft(find.byKey(const Key('icon-category-bar'))).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('icon-grid-0'))).dy,
      ),
    );
    final border =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const Key('icon-category-bar')),
                )
                .decoration
            as BoxDecoration;
    expect(border.border!.bottom.color.a, lessThan(1));
    final grid = tester.getRect(find.byKey(const Key('icon-grid-0')));
    final firstIcon = tester.getRect(find.byKey(const Key('icon-choice-0')));
    final fifthIcon = tester.getRect(find.byKey(const Key('icon-choice-4')));
    final thirdRow = tester.getRect(find.byKey(const Key('icon-choice-10')));
    final header = tester.getRect(
      find.byKey(const Key('icon-category-Animals')),
    );
    final headerBottom = tester
        .getBottomLeft(find.byKey(const Key('icon-category-Animals')))
        .dy;
    final barTop = tester
        .getTopLeft(find.byKey(const Key('icon-category-bar')))
        .dy;
    final barBottom = tester
        .getBottomLeft(find.byKey(const Key('icon-category-bar')))
        .dy;
    expect(firstIcon.top, closeTo(grid.top, 0.1));
    expect(firstIcon.width, closeTo(firstIcon.height, 0.5));
    expect(fifthIcon.width, closeTo(firstIcon.width, 0.5));
    expect(
      fifthIcon.left - firstIcon.left,
      closeTo((firstIcon.width + 8) * 4, 1),
    );
    expect(header.left, closeTo(firstIcon.left, 0.5));
    expect(header.width, closeTo(firstIcon.width, 0.5));
    expect(barTop - headerBottom, closeTo(grid.top - barBottom, 1));
    expect(firstIcon.bottom, lessThanOrEqualTo(grid.bottom));
    expect(thirdRow.bottom, lessThanOrEqualTo(grid.bottom + 0.1));
    expect(grid.height, greaterThanOrEqualTo(3 * 48 + 2 * 8));
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(const Key('icon-choice-3')),
              matching: find.byType(Icon),
            ),
          )
          .color,
      PieceColors.crimson,
    );
    final topBefore = tester.getTopLeft(find.byType(FDialog)).dy;
    final bottomBefore = tester.getBottomLeft(find.byType(FDialog)).dy;
    await tester.tap(find.byKey(const Key('icon-category-Food')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(FDialog)).dy, topBefore);
    expect(tester.getBottomLeft(find.byType(FDialog)).dy, bottomBefore);
    await tester.scrollUntilVisible(
      find.byIcon(FLucideIcons.candyCane),
      48,
      scrollable: find.descendant(
        of: find.byKey(const Key('icon-grid-2')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byIcon(FLucideIcons.candyCane), findsOneWidget);
    expect(find.byIcon(FLucideIcons.apple), findsWidgets);
    await tester.tap(find.byKey(const Key('icon-category-Animals')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<InkWell>(find.byKey(const Key('icon-choice-1'))).onTap,
      isNull,
    );
    expect(find.byKey(const Key('icon-unavailable-1')), findsOneWidget);
    expect(find.byKey(const Key('icon-unavailable-0')), findsNothing);
    final starting = tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(const Key('player-icon-0')),
            matching: find.byType(Icon),
          ),
        )
        .icon;
    final chosen = tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(const Key('icon-choice-3')),
            matching: find.byType(Icon),
          ),
        )
        .icon;
    await tester.tap(find.byKey(const Key('icon-choice-3')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(const Key('player-icon-0')),
              matching: find.byType(Icon),
            ),
          )
          .icon,
      starting,
    );

    await tester.tap(find.byKey(const Key('player-icon-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('icon-choice-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply-player-icon')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(const Key('player-icon-0')),
              matching: find.byType(Icon),
            ),
          )
          .icon,
      chosen,
    );

    await tester.tap(find.byKey(const Key('player-icon-1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(const Key('icon-category-Animals')),
              matching: find.byType(Icon),
            ),
          )
          .color,
      PieceColors.tangerine,
    );
  });

  testWidgets('match settings steps the bottle count and can reject repeats', (
    tester,
  ) async {
    final matches = MemoryMatchRepository();
    await _pump(tester, matches);
    await tester.tap(find.byKey(const Key('new-game')));
    await tester.pumpAndSettle();
    await _tap(tester, 'setup-tab-match');

    expect(find.text('5 bottles · Easy'), findsOneWidget);
    expect(find.byKey(const Key('setup-bottle-5')), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.byKey(const Key('setup-bottle-6')), findsNothing);
    expect(tester.widget<GameSwitch>(find.byType(GameSwitch)).value, isFalse);
    expect(_trackColor(tester), AppColors.danger);

    await _tapTooltip(tester, 'More bottles');
    expect(find.text('6 bottles · Easy'), findsOneWidget);
    expect(find.byKey(const Key('setup-bottle-6')), findsOneWidget);

    await _tapTooltip(tester, 'Fewer bottles');
    expect(find.text('5 bottles · Easy'), findsOneWidget);
    expect(find.byKey(const Key('setup-bottle-6')), findsNothing);

    await _tapTooltip(tester, 'Fewer bottles');
    expect(find.text('5 bottles · Easy'), findsOneWidget);

    final reject = find.text('Reject previous combinations');
    await tester.ensureVisible(reject);
    await tester.pumpAndSettle();
    await tester.tap(reject);
    await tester.pumpAndSettle();
    expect(tester.widget<GameSwitch>(find.byType(GameSwitch)).value, isTrue);
    expect(_trackColor(tester), AppColors.yellow);

    await _tap(tester, 'continue-to-review');
    expect(find.text('Rejected'), findsOneWidget);
    await _tap(tester, 'start-match');
    expect(matches.active!.settings.rejectPreviousCombinations, isTrue);
    expect(matches.active!.settings.bottleCount, 5);
  });

  testWidgets('shuffle reorders players and the review shows the order', (
    tester,
  ) async {
    final matches = MemoryMatchRepository();
    await _pump(tester, matches);
    await tester.tap(find.byKey(const Key('new-game')));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Amy');
    await tester.enterText(fields.at(1), 'Bo');
    await tester.pump();

    var first = 'Amy';
    for (var attempt = 0; attempt < 12 && first == 'Amy'; attempt++) {
      await _tap(tester, 'shuffle-players');
      first = tester
          .widget<TextField>(find.byType(TextField).at(0))
          .controller!
          .text;
    }
    final second = tester
        .widget<TextField>(find.byType(TextField).at(1))
        .controller!
        .text;
    expect({first, second}, {'Amy', 'Bo'});
    expect(first, 'Bo');

    await _tap(tester, 'setup-tab-match');
    await _tap(tester, 'turn-order');
    await _tap(tester, 'turn-order-linear');
    await _tap(tester, 'continue-to-review');
    expect(find.text('Linear'), findsOneWidget);
    expect(find.text('Same order every round'), findsNothing);
  });

  testWidgets('the first exact order scores one round win', (tester) async {
    final matches = MemoryMatchRepository();
    await _pump(tester, matches);

    await tester.tap(find.byKey(const Key('new-game')));
    await tester.pumpAndSettle();
    await _tap(tester, 'continue-to-review');

    expect(find.text('Play game'), findsOneWidget);
    expect(find.text('First player to 3 round wins'), findsOneWidget);
    final play = tester.getTopLeft(find.byKey(const Key('start-match'))).dy;
    final practice = tester
        .getTopLeft(find.byKey(const Key('practice-turn')))
        .dy;
    expect(play, lessThan(practice));
    await _tap(tester, 'start-match');

    expect(find.text('Start round'), findsOneWidget);
    expect(find.byKey(const Key('turn-order-preview')), findsOneWidget);
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('First to 3'), findsOneWidget);
    expect(find.text('Random'), findsOneWidget);
    expect(find.text('New order every round'), findsOneWidget);
    expect(find.text('Player 1'), findsWidgets);
    expect(find.text('Player 2'), findsWidgets);
    await _tap(tester, 'begin-round');
    await _tap(tester, 'bottle-position-0');
    expect(find.byKey(const Key('move-to-1')), findsOneWidget);
    await _tap(tester, 'move-to-1');
    await _solveShownBoard(tester, matches);

    expect(find.text('Winner!'), findsNWidgets(2));
    expect(find.text('Round 1'), findsNWidgets(2));
    expect(find.byKey(const Key('round-win-standings')), findsOneWidget);
    expect(find.byKey(const Key('next-round')), findsOneWidget);
    expect(find.text('Pause'), findsNothing);
    expect(matches.active!.wins.where((win) => !win.reversed), hasLength(1));
    expect(matches.active!.phase, MatchPhase.roundResult);
  });

  testWidgets('a timer stays covered until the current player presses play', (
    tester,
  ) async {
    await _pump(tester, MemoryMatchRepository());
    await tester.tap(find.byKey(const Key('new-game')));
    await tester.pumpAndSettle();
    await _tap(tester, 'setup-tab-match');
    await _tap(tester, 'turn-timer');
    await _tap(tester, 'timer-seconds30');
    await _tap(tester, 'continue-to-review');
    await _tap(tester, 'start-match');
    await _tap(tester, 'begin-round');

    expect(find.text('Play'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byKey(const Key('check-arrangement')), findsNothing);

    await _tap(tester, 'player-ready');

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byKey(const Key('check-arrangement')), findsOneWidget);
  });

  testWidgets('new game replaces the saved match without asking again', (
    tester,
  ) async {
    final matches = MemoryMatchRepository()
      ..active = sampleMatch(phase: MatchPhase.paused);
    await _pump(tester, matches);
    expect(find.byKey(const Key('continue-saved-match')), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-game')));
    await tester.pumpAndSettle();
    await _tap(tester, 'continue-to-review');
    await _tap(tester, 'start-match');

    expect(find.text('Replace the saved match?'), findsNothing);
    expect(find.byKey(const Key('begin-round')), findsOneWidget);
    expect(matches.active!.matchId, isNot('match-1'));
  });

  testWidgets('replacing an unfinished match asks first', (tester) async {
    final matches = MemoryMatchRepository();
    await _pump(tester, matches);
    await _startMatch(tester);
    final savedId = matches.active!.matchId;

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-match')));
    await tester.pumpAndSettle();

    expect(find.text('Replace the saved match?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel-replace-match')));
    await tester.pumpAndSettle();

    expect(matches.active!.matchId, savedId);
    expect(matches.active!.phase, MatchPhase.paused);
  });
}

Future<void> _startMatch(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('new-game')));
  await tester.pumpAndSettle();
  await _tap(tester, 'continue-to-review');
  await _tap(tester, 'start-match');
}

Future<void> _solveShownBoard(
  WidgetTester tester,
  MemoryMatchRepository matches,
) async {
  final target = [...matches.active!.board!.target];
  while (true) {
    final pending = [...matches.active!.board!.pending];
    var destination = -1;
    for (var index = 0; index < target.length; index++) {
      if (pending[index] != target[index]) {
        destination = index;
        break;
      }
    }
    if (destination < 0) {
      break;
    }
    final from = pending.indexOf(target[destination]);
    await _tap(tester, 'bottle-position-$from');
    await _tap(tester, 'bottle-position-$destination');
  }
  await _tap(tester, 'check-arrangement');
}

Color _trackColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(GameSwitch),
      matching: find.byWidgetPredicate((widget) {
        final decoration = widget is DecoratedBox ? widget.decoration : null;
        return decoration is BoxDecoration &&
            (decoration.color == AppColors.danger ||
                decoration.color == AppColors.yellow);
      }),
    ),
  );
  return (box.decoration as BoxDecoration).color!;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  final finder = find.byTooltip(tooltip);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(WidgetTester tester, MemoryMatchRepository matches) async {
  tester.view.physicalSize = const Size(500, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchRepositoryProvider.overrideWithValue(matches),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
      ],
      child: const ColorfulBottleMatchApp(),
    ),
  );
  await tester.pumpAndSettle();
}
