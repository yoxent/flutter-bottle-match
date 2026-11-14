import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../design_system/tokens/colors.dart';

/// One bottle identity. Color, symbol, and label travel together.
class BottleFace {
  const BottleFace({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

const bottleFaces = <BottleFace>[
  BottleFace(
    label: 'Star',
    icon: FLucideIcons.star,
    color: PieceColors.crimson,
  ),
  BottleFace(
    label: 'Moon',
    icon: FLucideIcons.moon,
    color: PieceColors.tangerine,
  ),
  BottleFace(
    label: 'Heart',
    icon: FLucideIcons.heart,
    color: PieceColors.goldenYellow,
  ),
  BottleFace(
    label: 'Bolt',
    icon: FLucideIcons.zap,
    color: PieceColors.chartreuse,
  ),
  BottleFace(
    label: 'Drop',
    icon: FLucideIcons.droplet,
    color: PieceColors.forestGreen,
  ),
  BottleFace(
    label: 'Shell',
    icon: FLucideIcons.shell,
    color: PieceColors.emerald,
  ),
  BottleFace(
    label: 'Leaf',
    icon: FLucideIcons.leaf,
    color: PieceColors.turquoise,
  ),
  BottleFace(
    label: 'Bird',
    icon: FLucideIcons.bird,
    color: PieceColors.deepTeal,
  ),
  BottleFace(
    label: 'Fish',
    icon: FLucideIcons.fish,
    color: PieceColors.royalBlue,
  ),
  BottleFace(label: 'Cat', icon: FLucideIcons.cat, color: PieceColors.navy),
  BottleFace(label: 'Sun', icon: FLucideIcons.sun, color: PieceColors.violet),
  BottleFace(
    label: 'Crown',
    icon: FLucideIcons.crown,
    color: PieceColors.magenta,
  ),
  BottleFace(label: 'Key', icon: FLucideIcons.key, color: PieceColors.hotPink),
  BottleFace(
    label: 'Anchor',
    icon: FLucideIcons.anchor,
    color: PieceColors.coral,
  ),
  BottleFace(
    label: 'Flower',
    icon: FLucideIcons.flower,
    color: PieceColors.slateBlue,
  ),
];

BottleFace bottleFaceFor(int bottle) {
  final index = bottle < 0 ? 0 : bottle % bottleFaces.length;
  return bottleFaces[index];
}

String bottleOrderLabel(List<int> bottles) {
  return [for (final bottle in bottles) bottleFaceFor(bottle).label].join(', ');
}
