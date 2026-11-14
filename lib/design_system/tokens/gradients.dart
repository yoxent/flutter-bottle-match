import 'package:flutter/material.dart';

import 'colors.dart';

abstract final class AppGradients {
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.backgroundLift,
      AppColors.background,
      AppColors.backgroundDeep,
    ],
  );
}
