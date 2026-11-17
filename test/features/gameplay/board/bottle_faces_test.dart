import 'package:flutter_bottle_match/domain/rules/match_constraints.dart';
import 'package:flutter_bottle_match/features/gameplay/board/bottle_faces.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bottle faces follow the image filename order', () {
    expect(bottleFaces, hasLength(MatchConstraints.maxBottles));
    expect(bottleFaces.map((face) => face.asset).toSet(), hasLength(15));
    expect(bottleFaces.first.asset, endsWith('01 Pink Heart.png'));
    expect(bottleFaces.last.asset, endsWith('15 Electric Waves.png'));
    expect(bottleFaceFor(0).asset, bottleFaces.first.asset);
    expect(bottleFaceFor(15).asset, bottleFaces.first.asset);
    expect(bottleFaceFor(-1).asset, bottleFaces.first.asset);
  });
}
