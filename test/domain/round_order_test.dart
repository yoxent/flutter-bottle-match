import 'dart:math';

import 'package:flutter_bottle_match/domain/rules/round_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const roster = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l'];

  test('a seeded shuffle is stable and contains every player once', () {
    final first = shufflePlayerOrder(roster, Random(7));
    final second = shufflePlayerOrder(roster, Random(7));

    expect(first, second);
    expect(first.toSet(), roster.toSet());
    expect(first, hasLength(roster.length));
  });

  test('an unchanged order is a legal result', () {
    List<String>? unchanged;
    for (var seed = 0; seed < 20; seed++) {
      final order = shufflePlayerOrder(const ['maya', 'leo'], Random(seed));
      if (order.first == 'maya' && order.last == 'leo') {
        unchanged = order;
        break;
      }
    }

    expect(unchanged, ['maya', 'leo']);
  });
}
