import 'package:flutter/material.dart';

import 'colors.dart';

/// Product faces. Both are Inter until a display face is chosen.
///
/// The family is the variable Inter already bundled by Forui, so the app
/// does not ship a second copy. Weights from 400 through 900 come from that
/// file's weight axis.
abstract final class AppFontFamily {
  static const header = 'packages/forui/Inter';
  static const body = 'packages/forui/Inter';
}

abstract final class AppTypography {
  static const display = TextStyle(
    fontFamily: AppFontFamily.header,
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w800,
    color: AppColors.cream,
  );

  static const title = TextStyle(
    fontFamily: AppFontFamily.header,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w800,
    color: AppColors.cream,
  );

  static const headline = TextStyle(
    fontFamily: AppFontFamily.header,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: AppColors.cream,
  );

  static const body = TextStyle(
    fontFamily: AppFontFamily.body,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.cream,
  );

  static const emphasis = TextStyle(
    fontFamily: AppFontFamily.body,
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: AppColors.cream,
  );

  static const label = TextStyle(
    fontFamily: AppFontFamily.body,
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.creamMuted,
  );

  static const button = TextStyle(
    fontFamily: AppFontFamily.header,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );

  static const stageKicker = TextStyle(
    fontFamily: AppFontFamily.header,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
    color: AppColors.cream,
  );

  static const stageScore = TextStyle(
    fontFamily: AppFontFamily.body,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AppColors.cream,
  );

  static const stageAnnouncement = TextStyle(
    fontFamily: AppFontFamily.header,
    fontSize: 32,
    height: 1.05,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.6,
    color: AppColors.stageYellow,
  );

  static const stageOrder = TextStyle(
    fontFamily: AppFontFamily.header,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w800,
    color: AppColors.cream,
  );

  static const stageName = TextStyle(
    fontFamily: AppFontFamily.header,
    fontSize: 18,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
    color: AppColors.cream,
  );

  static const stageNote = TextStyle(
    fontFamily: AppFontFamily.body,
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.cream,
  );

  static const stageButton = TextStyle(
    fontFamily: AppFontFamily.header,
    fontSize: 18,
    height: 1.1,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.6,
  );

  static const stageSeat = TextStyle(
    fontSize: 16,
    height: 1,
    fontWeight: FontWeight.w800,
    color: AppColors.stagePanelTop,
  );

  static TextTheme textTheme() {
    return const TextTheme(
      displaySmall: display,
      headlineMedium: title,
      headlineSmall: headline,
      titleLarge: headline,
      titleMedium: emphasis,
      bodyLarge: body,
      bodyMedium: body,
      labelLarge: label,
    );
  }
}
