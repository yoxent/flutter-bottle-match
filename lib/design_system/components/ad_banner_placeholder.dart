import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// Top slot the size of a standard 320×50 banner.
///
/// One instance stays mounted for the whole app. [child] is the loaded banner.
/// Until that view is ready, the slot shows its label so the height stays put.
class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({this.child, super.key});

  final Widget? child;

  /// Standard banner height, in logical pixels.
  static const height = 50.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.creamMuted)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child:
              child ??
              const Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Ad banner', style: AppTypography.label),
                ),
              ),
        ),
      ),
    );
  }
}
