import 'package:flutter/material.dart';
import 'package:flutter_bottle_match/features/gameplay/board/shelf_rack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the rack follows the bottle count', () {
    expect(shelfRackFor(5).asset, endsWith('Rack_01.png'));
    expect(shelfRackFor(5).shelfTops, hasLength(1));

    expect(shelfRackFor(6).asset, endsWith('Rack_02.png'));
    expect(shelfRackFor(10).asset, endsWith('Rack_02.png'));
    expect(shelfRackFor(10).shelfTops, hasLength(2));

    expect(shelfRackFor(11).asset, endsWith('Rack_03.png'));
    expect(shelfRackFor(15).asset, endsWith('Rack_03.png'));
    expect(shelfRackFor(15).shelfTops, hasLength(3));
  });

  test('six or more bottles split evenly from the top shelf', () {
    expect(shelfRowCounts(5), [5]);
    expect(shelfRowCounts(6), [3, 3]);
    expect(shelfRowCounts(7), [4, 3]);
    expect(shelfRowCounts(8), [4, 4]);
    expect(shelfRowCounts(11), [4, 4, 3]);
    expect(shelfRowCounts(14), [5, 5, 4]);
    expect(shelfRowCounts(15), [5, 5, 5]);
  });

  testWidgets('split rows stay centered on their shelves', (tester) async {
    await _pump(tester, 6);
    expect(_sameRow(tester, 0, 2), isTrue);
    expect(_rect(tester, 3).top, greaterThan(_rect(tester, 0).top));
    expect(
      _groupCenter(tester, 0, 2),
      closeTo(_groupCenter(tester, 3, 5), 0.5),
    );

    await _pump(tester, 7);
    expect(_sameRow(tester, 0, 3), isTrue);
    expect(_rect(tester, 4).top, greaterThan(_rect(tester, 0).top));
    expect(
      _groupCenter(tester, 0, 3),
      closeTo(_groupCenter(tester, 4, 6), 0.5),
    );
  });
}

Future<void> _pump(WidgetTester tester, int count) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ShelfBoard(
          itemCount: count,
          itemBuilder: (context, index) => SizedBox(key: Key('bottle-$index')),
        ),
      ),
    ),
  );
}

Rect _rect(WidgetTester tester, int index) {
  return tester.getRect(find.byKey(Key('bottle-$index')));
}

bool _sameRow(WidgetTester tester, int start, int end) {
  final top = _rect(tester, start).top;
  for (var index = start + 1; index <= end; index++) {
    if ((_rect(tester, index).top - top).abs() > 0.5) {
      return false;
    }
  }
  return true;
}

double _groupCenter(WidgetTester tester, int start, int end) {
  return (_rect(tester, start).left + _rect(tester, end).right) / 2;
}
