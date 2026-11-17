import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Material theme for game screens, plus a Forui theme for standard controls.
abstract final class AppTheme {
  static final ThemeData materialTheme = _material();
  static final FThemeData foruiTheme = _forui();

  static ThemeData _material() {
    const scheme = ColorScheme.dark(
      primary: AppColors.hotPink,
      onPrimary: AppColors.ink,
      secondary: AppColors.cyan,
      onSecondary: AppColors.ink,
      surface: AppColors.card,
      onSurface: AppColors.cream,
      error: AppColors.danger,
      onError: AppColors.cream,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFontFamily.body,
      textTheme: AppTypography.textTheme(),
      splashFactory: InkSparkle.splashFactory,
      // The app plays button_click.wav. Leave the platform click off.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(enableFeedback: false),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(enableFeedback: false),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(enableFeedback: false),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        labelStyle: AppTypography.label,
        floatingLabelStyle: TextStyle(
          fontFamily: AppFontFamily.body,
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: AppColors.yellow,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
          borderSide: BorderSide(color: AppColors.yellow, width: 2),
        ),
      ),
    );
  }

  static FThemeData _forui() {
    final colors = FColors(
      brightness: Brightness.dark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      barrier: Color(0xB314061F),
      background: AppColors.background,
      foreground: AppColors.cream,
      primary: AppColors.hotPink,
      primaryForeground: AppColors.ink,
      secondary: AppColors.electricBlue,
      secondaryForeground: AppColors.cream,
      muted: AppColors.card,
      mutedForeground: AppColors.creamMuted,
      destructive: AppColors.danger,
      destructiveForeground: AppColors.cream,
      error: AppColors.danger,
      errorForeground: AppColors.cream,
      card: AppColors.card,
      border: Color(0x33FFF7E8),
    );
    return FThemeData(
      colors: colors,
      touch: true,
      debugLabel: 'Bottle Match',
      typography: FTypography(
        display: FTypeface.inherit(
          colors: colors,
          touch: true,
          fontFamily: AppFontFamily.header,
        ),
        body: FTypeface.inherit(
          colors: colors,
          touch: true,
          fontFamily: AppFontFamily.body,
        ),
      ),
    );
  }
}
