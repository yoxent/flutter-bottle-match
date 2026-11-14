import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';

class GameButton extends StatelessWidget {
  const GameButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    this.foregroundColor = AppColors.ink,
    this.icon,
    this.semanticsLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: foregroundColor),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(child: Text(label, textAlign: TextAlign.start)),
          ],
        ),
      ),
    );
  }
}
