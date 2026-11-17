import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'ads/ad_banner.dart';
import 'application/audio/game_audio.dart';
import 'application/controllers/settings_controller.dart';
import 'application/router.dart';
import 'core/constants/app_info.dart';
import 'design_system/components/bubble_field.dart';
import 'design_system/themes/app_theme.dart';

class ColorfulBottleMatchApp extends ConsumerWidget {
  const ColorfulBottleMatchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(gameAudioProvider);
    final reducedMotion = ref
        .watch(settingsControllerProvider)
        .maybeWhen(data: (value) => value.reducedMotion, orElse: () => true);
    return MaterialApp.router(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.materialTheme,
      routerConfig: router,
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      builder: (context, child) {
        final page = child ?? const SizedBox.shrink();
        return FTheme(
          data: AppTheme.foruiTheme,
          child: Column(
            children: [
              const AdBanner(),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BubbleField(reducedMotion: reducedMotion),
                    Positioned.fill(
                      child: FToaster(
                        child: FTooltipGroup(
                          child: MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: page,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({required this.details, super.key});

  final String details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      theme: AppTheme.materialTheme,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${AppInfo.name} could not open local storage.\n\n$details',
            ),
          ),
        ),
      ),
    );
  }
}
