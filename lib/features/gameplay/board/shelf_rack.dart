import 'dart:math';

import 'package:flutter/material.dart';

import 'milk_bottle.dart';

/// A shelf image measured in pixels. [shelfTops] are the lip rows bottles
/// stand on. [left] and [right] are the ends of that lip.
class ShelfRack {
  const ShelfRack({
    required this.asset,
    required this.width,
    required this.height,
    required this.shelfTops,
    required this.left,
    required this.right,
  });

  final String asset;
  final double width;
  final double height;
  final List<double> shelfTops;
  final double left;
  final double right;
}

/// Five bottles use one shelf. Six to ten use two. Eleven and above use three.
ShelfRack shelfRackFor(int bottleCount) {
  if (bottleCount <= bottleGridColumns) {
    return _oneShelf;
  }
  if (bottleCount <= bottleGridColumns * 2) {
    return _twoShelves;
  }
  return _threeShelves;
}

/// How many bottles sit on each shelf. Six or more are split evenly, and a
/// remainder fills the upper shelves first.
List<int> shelfRowCounts(int bottleCount) {
  final rows = shelfRackFor(bottleCount).shelfTops.length;
  if (rows <= 1) {
    return [bottleCount];
  }
  final base = bottleCount ~/ rows;
  final extra = bottleCount % rows;
  return [for (var row = 0; row < rows; row++) base + (row < extra ? 1 : 0)];
}

const _oneShelf = ShelfRack(
  asset: 'assets/images/racks/Rack_01.png',
  width: 360,
  height: 118,
  shelfTops: [86],
  left: 37,
  right: 321,
);

const _twoShelves = ShelfRack(
  asset: 'assets/images/racks/Rack_02.png',
  width: 360,
  height: 224,
  shelfTops: [88, 191],
  left: 23,
  right: 336,
);

const _threeShelves = ShelfRack(
  asset: 'assets/images/racks/Rack_03.png',
  width: 360,
  height: 330,
  shelfTops: [88, 191, 298],
  left: 23,
  right: 336,
);

/// The rack image's center stays on the screen center.
/// A taller rack grows equally up and down from that point.
class _CenterPin extends StatefulWidget {
  const _CenterPin({required this.screenHeight, required this.builder});

  final double screenHeight;
  final _PinnedRack Function(BoxConstraints constraints) builder;

  @override
  State<_CenterPin> createState() => _CenterPinState();
}

class _PinnedRack {
  const _PinnedRack({
    required this.child,
    required this.width,
    required this.imageCenterY,
  });

  final Widget child;
  final double width;
  final double imageCenterY;
}

class _CenterPinState extends State<_CenterPin> {
  double? _pin;

  void _measure() {
    if (!mounted) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      return;
    }
    final raw = widget.screenHeight / 2 - box.localToGlobal(Offset.zero).dy;
    if (!raw.isFinite) {
      return;
    }
    if (_pin == null || (raw - _pin!).abs() > 0.5) {
      setState(() => _pin = raw);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 0.0;
        final pin = _pin ?? height / 2;
        final rack = widget.builder(
          BoxConstraints(maxWidth: width, maxHeight: widget.screenHeight),
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: (width - rack.width) / 2,
              top: pin - rack.imageCenterY,
              child: rack.child,
            ),
          ],
        );
      },
    );
  }
}

/// The bottle picture has a few transparent rows under the glass.
const _baseInset = 5 / BottleArt.height;

/// Extra drop per shelf, in logical pixels. Positive moves a bottle down.
/// The first shelf is already seated. The lower shelves need their own nudge.
const _seatDrop = <double>[4, 8, 8];

/// Extra drop for the single five-bottle row. Six or more bottles skip it.
const _singleRowDrop = 4.0;

/// Empty space at each end of a bottle row, in logical pixels.
const _rowPadding = 2.0;

/// End padding when the rack has six or more bottles.
const _wideRowPadding = 3.0;

class ShelfBoard extends StatelessWidget {
  const ShelfBoard({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final rack = shelfRackFor(itemCount);
    return _CenterPin(
      screenHeight: MediaQuery.sizeOf(context).height,
      builder: (constraints) {
        final frame = _ShelfFrame.fit(rack, constraints, itemCount);
        return _PinnedRack(
          width: frame.width,
          imageCenterY: frame.imageTop + frame.imageHeight / 2,
          child: SizedBox(
            width: frame.width,
            height: frame.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: frame.imageTop,
                  width: frame.imageWidth,
                  height: frame.imageHeight,
                  child: IgnorePointer(
                    child: Image.asset(
                      rack.asset,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                for (var index = 0; index < itemCount; index++)
                  Positioned(
                    left: frame.leftFor(index),
                    top: frame.topFor(index),
                    width: frame.slotWidth,
                    height: frame.bottleHeight,
                    child: itemBuilder(context, index),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShelfFrame {
  const _ShelfFrame({
    required this.rack,
    required this.scale,
    required this.overflow,
    required this.itemCount,
  });

  final ShelfRack rack;
  final double scale;
  final double overflow;
  final int itemCount;

  double get rowPadding =>
      itemCount <= bottleGridColumns ? _rowPadding : _wideRowPadding;

  double get width => rack.width * scale;

  double get height => (rack.height + overflow) * scale;

  double get imageTop => overflow * scale;

  double get imageWidth => rack.width * scale;

  double get imageHeight => rack.height * scale;

  double get slotWidth =>
      ((rack.right - rack.left) * scale - rowPadding * 2) / bottleGridColumns;

  double get bottleHeight => slotWidth * BottleArt.height / BottleArt.width;

  factory _ShelfFrame.fit(
    ShelfRack rack,
    BoxConstraints constraints,
    int itemCount,
  ) {
    final slot = (rack.right - rack.left) / bottleGridColumns;
    final bottleHeight = slot * BottleArt.height / BottleArt.width;
    final top = rack.shelfTops.first - bottleHeight + bottleHeight * _baseInset;
    final overflow = top < 0 ? -top : 0.0;
    var maxWidth = constraints.maxWidth;
    var maxHeight = constraints.maxHeight;
    if (!maxWidth.isFinite || maxWidth <= 0) {
      maxWidth = rack.width;
    }
    if (!maxHeight.isFinite || maxHeight <= 0) {
      maxHeight = rack.height + overflow;
    }
    final scale = min(
      maxWidth / rack.width,
      maxHeight / (rack.height + overflow),
    );
    return _ShelfFrame(
      rack: rack,
      scale: scale,
      overflow: overflow,
      itemCount: itemCount,
    );
  }

  double leftFor(int index) {
    final place = _place(index);
    final inset = (bottleGridColumns - place.rowCount) * slotWidth / 2;
    return rack.left * scale + rowPadding + inset + place.column * slotWidth;
  }

  double topFor(int index) {
    final row = _place(index).row;
    final shelf = row < rack.shelfTops.length
        ? rack.shelfTops[row]
        : rack.shelfTops.last;
    final shelfY = (overflow + shelf) * scale;
    final drop = row < _seatDrop.length ? _seatDrop[row] : _seatDrop.last;
    final singleRow = itemCount <= bottleGridColumns ? _singleRowDrop : 0.0;
    return shelfY - bottleHeight + bottleHeight * _baseInset + drop + singleRow;
  }

  ({int row, int column, int rowCount}) _place(int index) {
    final counts = shelfRowCounts(itemCount);
    var start = 0;
    for (var row = 0; row < counts.length; row++) {
      final rowCount = counts[row];
      if (index < start + rowCount) {
        return (row: row, column: index - start, rowCount: rowCount);
      }
      start += rowCount;
    }
    final last = counts.length - 1;
    return (row: last, column: 0, rowCount: counts[last]);
  }
}
