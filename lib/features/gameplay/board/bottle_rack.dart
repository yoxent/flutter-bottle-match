import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../domain/rules/bottle_round.dart';
import 'bottle_faces.dart';
import 'milk_bottle.dart';

/// The shared arrangement. A drag onto another bottle swaps those two.
/// Tapping two bottles, or Move to position, does the same swap.
class BottleRack extends StatefulWidget {
  const BottleRack({
    required this.arrangement,
    required this.opening,
    required this.onSwap,
    this.hint,
    super.key,
  });

  final List<int> arrangement;
  final List<int> opening;
  final void Function(int from, int to) onSwap;
  final BottleHint? hint;

  @override
  State<BottleRack> createState() => _BottleRackState();
}

class _BottleRackState extends State<BottleRack> {
  int? _selected;

  @override
  void didUpdateWidget(BottleRack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_same(oldWidget.arrangement, widget.arrangement)) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.hint;
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null) ...[
          Text(
            'Position ${hint.position + 1} is '
            '${_letter(hint.bottle)}.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Expanded(
          child: BottleGrid(
            itemCount: widget.arrangement.length,
            itemBuilder: (context, index) => _tile(index),
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Move ${_letter(widget.arrangement[selected])} to',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (var index = 0; index < widget.arrangement.length; index++)
                if (index != selected)
                  SizedBox(
                    width: AppTouch.minimum,
                    height: AppTouch.minimum,
                    child: FilledButton(
                      key: Key('move-to-$index'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.cream,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => widget.onSwap(selected, index),
                      child: Text(
                        '${index + 1}',
                        semanticsLabel: 'Move to position ${index + 1}',
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _tile(int index) {
    final bottle = widget.arrangement[index];
    final face = bottleFaceFor(bottle);
    final letter = _letter(bottle);
    final selected = _selected == index;
    final label =
        'Position ${index + 1}, $letter'
        '${selected ? ', selected' : ''}';
    MilkBottle tile() {
      return MilkBottle(
        color: face.color,
        filled: true,
        selected: selected,
        letter: letter,
      );
    }

    return Draggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 88, height: 168, child: tile()),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile()),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) => widget.onSwap(details.data, index),
        builder: (context, candidates, _) {
          return Semantics(
            button: true,
            label: label,
            selected: selected,
            child: GestureDetector(
              key: Key('bottle-position-$index'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _tap(index),
              child: SizedBox.expand(child: tile()),
            ),
          );
        },
      ),
    );
  }

  String _letter(int bottle) => roundBottleLetter(widget.opening, bottle);

  void _tap(int index) {
    final selected = _selected;
    if (selected == null || selected == index) {
      setState(() => _selected = selected == index ? null : index);
      return;
    }
    widget.onSwap(selected, index);
    setState(() => _selected = null);
  }
}

bool _same(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
