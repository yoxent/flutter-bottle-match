import 'package:flutter/material.dart';

import 'bottle_faces.dart';
import 'milk_bottle.dart';

/// The bottles in the current count. The count itself comes from the stepper.
class BottleCountPicker extends StatelessWidget {
  const BottleCountPicker({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return BottleGrid(
      itemCount: count,
      itemBuilder: (context, index) {
        final face = bottleFaceFor(index);
        return Semantics(
          label: 'Bottle ${index + 1}',
          child: MilkBottle(
            key: Key('setup-bottle-${index + 1}'),
            color: face.color,
            filled: true,
            selected: false,
          ),
        );
      },
    );
  }
}
