import 'dart:math';

import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';

/// Five columns fit the 15-bottle maximum on a phone without shrinking
/// a bottle below a touch target.
const bottleGridColumns = 5;

double bottleCellExtent(double maxWidth) {
  const gap = AppSpacing.xs;
  final width = (maxWidth - gap * (bottleGridColumns - 1)) / bottleGridColumns;
  return min(width * BottleArt.height / BottleArt.width, 168.0);
}

/// The bottle artwork in [assets/images]. The outline stays dark. The fill
/// image is the interior below the liquid line, tinted per bottle.
abstract final class BottleArt {
  static const outline = 'assets/images/filled-bottle.png';
  static const fill = 'assets/images/filled-bottle-fill.png';
  static const width = 238.0;
  static const height = 512.0;
}

class MilkBottle extends StatelessWidget {
  const MilkBottle({
    required this.color,
    required this.filled,
    required this.selected,
    this.letter = '',
    super.key,
  });

  final Color color;
  final bool filled;
  final bool selected;
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        if (selected)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.hotPink.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.all(Radius.circular(18)),
            ),
          ),
        if (filled)
          ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: Image.asset(
              BottleArt.fill,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
          ),
        Image.asset(
          BottleArt.outline,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
        if (letter.isNotEmpty)
          Align(
            alignment: const Alignment(0, 0.28),
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 0.2,
              child: _BottleLetter(letter),
            ),
          ),
      ],
    );
  }
}

class _BottleLetter extends StatelessWidget {
  const _BottleLetter(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      height: 1,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = AppColors.ink;
    return ExcludeSemantics(
      child: FittedBox(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(letter, style: style.copyWith(foreground: stroke)),
            Text(letter, style: style.copyWith(color: AppColors.cream)),
          ],
        ),
      ),
    );
  }
}

class BottleGrid extends StatelessWidget {
  const BottleGrid({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.xs;
        final rows = (itemCount / bottleGridColumns).ceil();
        final natural = bottleCellExtent(constraints.maxWidth);
        var extent = natural;
        if (constraints.maxHeight.isFinite && rows > 0) {
          final fitted = (constraints.maxHeight - gap * (rows - 1)) / rows;
          if (fitted.isFinite && fitted > 0) {
            extent = min(natural, fitted);
          }
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row < rows; row++) ...[
              if (row > 0) const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (
                    var column = 0;
                    column < bottleGridColumns;
                    column++
                  ) ...[
                    if (column > 0) const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: SizedBox(
                        height: extent,
                        child: _child(context, row, column),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _child(BuildContext context, int row, int column) {
    final index = row * bottleGridColumns + column;
    if (index >= itemCount) {
      return const SizedBox.shrink();
    }
    return itemBuilder(context, index);
  }
}
