import 'package:flutter/material.dart';

/// Party-game palette. Widgets use these tokens instead of raw color values.
abstract final class AppColors {
  static const background = Color(0xFF33157C);
  static const card = Color(0xFF3B1764);
  static const cream = Color(0xFFFFF7E8);
  static const creamMuted = Color(0xFFD8C7E8);
  static const ink = Color(0xFF1A0530);
  static const hotPink = Color(0xFFFF2E8A);
  static const cyan = Color(0xFF2DE2E6);
  static const electricBlue = Color(0xFF3D5AFE);
  static const yellow = Color(0xFFFFE14A);
  static const lime = Color(0xFFB8F25A);
  static const danger = Color(0xFFFF5A6A);
}

/// Fifteen distinct piece colors. Players use the first twelve.
abstract final class PieceColors {
  static const crimson = Color(0xFFE6194B);
  static const tangerine = Color(0xFFFF7F00);
  static const goldenYellow = Color(0xFFFFD700);
  static const chartreuse = Color(0xFF9ACD32);
  static const forestGreen = Color(0xFF228B22);
  static const emerald = Color(0xFF00A86B);
  static const turquoise = Color(0xFF40E0D0);
  static const deepTeal = Color(0xFF008B8B);
  static const royalBlue = Color(0xFF2455D6);
  static const navy = Color(0xFF191970);
  static const violet = Color(0xFF7B2CBF);
  static const magenta = Color(0xFFD500A9);
  static const hotPink = Color(0xFFFF1493);
  static const coral = Color(0xFFFF4F50);
  static const slateBlue = Color(0xFF6A5ACD);

  static const values = <Color>[
    crimson,
    tangerine,
    goldenYellow,
    chartreuse,
    forestGreen,
    emerald,
    turquoise,
    deepTeal,
    royalBlue,
    navy,
    violet,
    magenta,
    hotPink,
    coral,
    slateBlue,
  ];
}
