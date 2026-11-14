import 'package:flutter/material.dart';

import 'colors.dart';

abstract final class AppTypography {
  static const display = TextStyle(
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w800,
    color: AppColors.cream,
  );

  static const title = TextStyle(
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w800,
    color: AppColors.cream,
  );

  static const headline = TextStyle(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: AppColors.cream,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.cream,
  );

  static const emphasis = TextStyle(
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: AppColors.cream,
  );

  static const label = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.creamMuted,
  );

  static const button = TextStyle(
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w800,
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
