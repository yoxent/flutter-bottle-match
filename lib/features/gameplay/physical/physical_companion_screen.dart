import 'package:flutter/material.dart';

import '../../../design_system/components/game_page.dart';
import '../../../design_system/tokens/spacing.dart';

/// Entry point for Release 1. Match setup is the next milestone.
class PhysicalCompanionScreen extends StatelessWidget {
  const PhysicalCompanionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GamePage(
      title: 'Physical Companion',
      showBack: true,
      body: ListView(
        children: [
          Text('Release 1', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The app will track player order, turns, the optional timer, '
            'facilitator-confirmed results, and scores. It will not inspect '
            'physical pieces.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This screen does not start a match. Player setup and the turn '
            'flow are the next milestone.',
            style: text.bodyLarge,
          ),
        ],
      ),
    );
  }
}
