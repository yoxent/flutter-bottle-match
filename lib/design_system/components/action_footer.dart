import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Pins the page actions under a scrolling body.
class ActionFooter extends StatelessWidget {
  const ActionFooter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.cream.withValues(alpha: 0.16)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: child,
        ),
      ),
    );
  }
}
