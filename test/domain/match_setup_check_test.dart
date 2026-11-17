import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/domain/models/player.dart';
import 'package:flutter_bottle_match/domain/rules/match_setup_check.dart';
import 'package:flutter_bottle_match/domain/rules/player_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const roster = [
    Player(id: 'maya', name: 'Maya', avatarIndex: 0),
    Player(id: 'leo', name: 'Leo', avatarIndex: 1),
  ];

  test('physical defaults can start without a piece confirmation', () {
    final check = MatchSetupCheck.evaluate(
      roster: roster,
      settings: const MatchSettings(),
    );

    expect(check.isValid, isTrue);
  });

  test('selected-player mode requires a roster member', () {
    final check = MatchSetupCheck.evaluate(
      roster: roster,
      settings: const MatchSettings(
        winRule: WinRule.selectedPlayerReachesTarget,
      ),
    );

    expect(check.isValid, isFalse);
  });

  test('blank names become Player N and duplicates are numbered', () {
    expect(normalizePlayerName('  ', 3), 'Player 3');
    expect(
      visiblePlayerNames(const [
        Player(id: '1', name: 'Maya', avatarIndex: 0),
        Player(id: '2', name: 'Maya', avatarIndex: 1),
        Player(id: '3', name: 'Leo', avatarIndex: 2),
      ]),
      ['Maya 1', 'Maya 2', 'Leo'],
    );
  });

  test('player count, bottles, target, and name length are bounded', () {
    final check = MatchSetupCheck.evaluate(
      roster: const [Player(id: 'only', name: '', avatarIndex: 0)],
      settings: const MatchSettings(bottleCount: 4, targetRoundWins: 21),
    );

    expect(check.issues, contains('Choose 2 to 12 players.'));
    expect(check.issues, contains('Choose 5 to 15 bottles.'));
    expect(check.issues, contains('Choose a target from 1 to 20 round wins.'));
    expect(check.issues, contains('Player names must be 1 to 20 characters.'));
  });
}
