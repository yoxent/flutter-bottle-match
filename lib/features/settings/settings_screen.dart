import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../application/controllers/settings_controller.dart';
import '../../design_system/components/game_page.dart';
import '../../design_system/components/section_card.dart';
import '../../design_system/tokens/spacing.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    return GamePage(
      title: 'Settings',
      showBack: true,
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('$error'),
        data: (value) => ListView(
          children: [
            SectionCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  FSwitch(
                    value: value.soundEnabled,
                    semanticsLabel: 'Sound',
                    label: const Text('Sound'),
                    description: const Text('Selection and result sounds.'),
                    onChange: (enabled) => _save(
                      () => ref
                          .read(settingsControllerProvider.notifier)
                          .setSoundEnabled(enabled),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FSwitch(
                    value: value.hapticsEnabled,
                    semanticsLabel: 'Haptics',
                    label: const Text('Haptics'),
                    description: const Text('Vibration separate from sound.'),
                    onChange: (enabled) => _save(
                      () => ref
                          .read(settingsControllerProvider.notifier)
                          .setHapticsEnabled(enabled),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FSwitch(
                    value: value.reducedMotion,
                    semanticsLabel: 'Reduced motion',
                    label: const Text('Reduced motion'),
                    description: const Text('Short fades instead of movement.'),
                    onChange: (enabled) => _save(
                      () => ref
                          .read(settingsControllerProvider.notifier)
                          .setReducedMotion(enabled),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }

  void _save(Future<void> Function() action) {
    setState(() => _error = null);
    unawaited(
      action().catchError((Object _) {
        if (mounted) {
          setState(() => _error = 'Could not save that setting.');
        }
      }),
    );
  }
}
