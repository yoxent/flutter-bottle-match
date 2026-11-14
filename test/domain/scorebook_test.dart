import 'package:flutter_bottle_match/domain/rules/match_constraints.dart';
import 'package:flutter_bottle_match/domain/rules/scorebook.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a round win is worth one point and cannot be awarded twice', () {
    const book = Scorebook();
    final awarded = book.award(roundNumber: 1, winnerId: 'maya');
    expect(awarded, isA<ScorebookAccepted>());
    final next = (awarded as ScorebookAccepted).scorebook;

    expect(next.scoresFor(['maya', 'leo']), {'maya': 1, 'leo': 0});
    expect(MatchConstraints.roundWinPoints, 1);

    final duplicate = next.award(roundNumber: 1, winnerId: 'leo');
    expect(duplicate, isA<ScorebookRejected>());
    expect(next.scoresFor(['maya', 'leo'])['maya'], 1);
  });

  test('reversing the last result removes its point once', () {
    final awarded =
        (const Scorebook().award(roundNumber: 1, winnerId: 'maya')
                    as ScorebookAccepted)
                .scorebook
                .award(roundNumber: 2, winnerId: 'leo')
            as ScorebookAccepted;
    final reversed = awarded.scorebook.reverseLast() as ScorebookAccepted;

    expect(reversed.scorebook.scoresFor(['maya', 'leo']), {
      'maya': 1,
      'leo': 0,
    });
    expect(reversed.scorebook.reverseLast(), isA<ScorebookRejected>());
  });

  test('a reversed round can be confirmed again', () {
    final reversed =
        ((const Scorebook().award(roundNumber: 1, winnerId: 'maya')
                        as ScorebookAccepted)
                    .scorebook
                    .reverseLast()
                as ScorebookAccepted)
            .scorebook;
    final again = reversed.award(roundNumber: 1, winnerId: 'leo');

    expect(again, isA<ScorebookAccepted>());
    expect((again as ScorebookAccepted).scorebook.scoresFor(['leo']), {
      'leo': 1,
    });
  });
}
