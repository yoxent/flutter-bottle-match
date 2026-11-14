import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';

/// One bottle identity. The liquid color stays with the bottle.
/// Letters are assigned per round, from the opening order.
class BottleFace {
  const BottleFace({required this.label, required this.color});

  final String label;
  final Color color;
}

const bottleFaces = <BottleFace>[
  BottleFace(label: 'Crimson', color: PieceColors.crimson),
  BottleFace(label: 'Tangerine', color: PieceColors.tangerine),
  BottleFace(label: 'Golden Yellow', color: PieceColors.goldenYellow),
  BottleFace(label: 'Chartreuse', color: PieceColors.chartreuse),
  BottleFace(label: 'Forest Green', color: PieceColors.forestGreen),
  BottleFace(label: 'Emerald', color: PieceColors.emerald),
  BottleFace(label: 'Turquoise', color: PieceColors.turquoise),
  BottleFace(label: 'Deep Teal', color: PieceColors.deepTeal),
  BottleFace(label: 'Royal Blue', color: PieceColors.royalBlue),
  BottleFace(label: 'Navy', color: PieceColors.navy),
  BottleFace(label: 'Violet', color: PieceColors.violet),
  BottleFace(label: 'Magenta', color: PieceColors.magenta),
  BottleFace(label: 'Hot Pink', color: PieceColors.hotPink),
  BottleFace(label: 'Coral', color: PieceColors.coral),
  BottleFace(label: 'Slate Blue', color: PieceColors.slateBlue),
];

BottleFace bottleFaceFor(int bottle) {
  final index = bottle < 0 ? 0 : bottle % bottleFaces.length;
  return bottleFaces[index];
}
