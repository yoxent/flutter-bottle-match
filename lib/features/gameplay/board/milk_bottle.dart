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

/// The bottle artwork in [assets/images/bottles]. Each file is already colored.
abstract final class BottleArt {
  static const width = 96.0;
  static const height = 144.0;
}

class MilkBottle extends StatelessWidget {
  const MilkBottle({required this.asset, required this.selected, super.key});

  final String asset;
  final bool selected;

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
        Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      ],
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
