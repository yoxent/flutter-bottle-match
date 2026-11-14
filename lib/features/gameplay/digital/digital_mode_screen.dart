import 'package:flutter/material.dart';

import '../../../design_system/components/game_page.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Release 2 is not implemented. The puzzle rules remain proposed.
class DigitalModeScreen extends StatelessWidget {
  const DigitalModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GamePage(
      title: 'Fully Digital',
      showBack: true,
      body: ListView(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Not implemented',
                style: text.headlineSmall?.copyWith(color: AppColors.yellow),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Release 2 will add the shared hidden-order puzzle. '
            'Exact-position feedback is a proposed mechanic pending '
            'playtesting. It is not an official tabletop rule.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'The match shell is shared with Physical Companion so the digital '
            'mode can be added without replacing session recovery, scoring, '
            'or turn order.',
            style: text.bodyLarge,
          ),
        ],
      ),
    );
  }
}
