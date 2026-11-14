import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

/// Portrait column that stays readable when the window is wide.
class GameViewport extends StatelessWidget {
  const GameViewport({required this.child, super.key});

  final Widget child;

  static const maxWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
