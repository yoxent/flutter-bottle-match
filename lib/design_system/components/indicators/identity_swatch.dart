import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';

/// A bottle identity preview: color, symbol, and a readable name together.
class IdentitySwatch extends StatelessWidget {
  const IdentitySwatch({
    required this.name,
    required this.icon,
    required this.color,
    super.key,
  });

  final String name;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name bottle',
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: SizedBox(
                width: AppTouch.minimum,
                height: AppTouch.minimum,
                child: Icon(icon, color: AppColors.ink, size: 28),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              name,
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
