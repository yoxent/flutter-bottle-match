import 'package:flutter_bottle_match/application/controllers/settings_controller.dart';
import 'package:flutter_bottle_match/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_repositories.dart';

void main() {
  test(
    'settings changes are saved and a failed write is rolled back',
    () async {
      final repository = MemorySettingsRepository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final initial = await container.read(settingsControllerProvider.future);
      expect(initial.soundEnabled, isTrue);

      await container
          .read(settingsControllerProvider.notifier)
          .setSoundEnabled(false);
      expect(repository.value.soundEnabled, isFalse);

      repository.failNextSave = true;
      await expectLater(
        container
            .read(settingsControllerProvider.notifier)
            .setReducedMotion(true),
        throwsStateError,
      );
      expect(
        container.read(settingsControllerProvider).requireValue.reducedMotion,
        isFalse,
      );
      expect(repository.value.reducedMotion, isFalse);
    },
  );
}
