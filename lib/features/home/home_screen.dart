import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../application/controllers/saved_match_controller.dart';
import '../../application/controllers/settings_controller.dart';
import '../../core/constants/app_info.dart';
import '../../design_system/components/buttons/game_button.dart';
import '../../design_system/components/game_page.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../domain/models/match_phase.dart';
import '../../domain/models/match_snapshot.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedMatchProvider);
    final settings = ref.watch(settingsControllerProvider);
    final reduceMotion = settings.maybeWhen(
      data: (value) => value.reducedMotion,
      orElse: () => true,
    );

    return GamePage(
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
          icon: const Icon(FLucideIcons.settings),
          color: AppColors.cream,
          constraints: const BoxConstraints(
            minWidth: AppTouch.minimum,
            minHeight: AppTouch.minimum,
          ),
        ),
      ],
      body: saved.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _StatusMessage(title: 'Saved match unavailable', body: '$error'),
        data: (snapshot) =>
            _HomeContent(snapshot: snapshot, reduceMotion: reduceMotion),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({required this.snapshot, required this.reduceMotion});

  final MatchSnapshot? snapshot;
  final bool reduceMotion;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.reduceMotion) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && _entrance.value != 1) {
      _entrance.value = 1;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final showContinue =
        snapshot != null && snapshot.phase != MatchPhase.championship;

    return FadeTransition(
      opacity: _entrance,
      child: ListView(
        children: [
          Text(AppInfo.name, style: AppTypography.display),
          const SizedBox(height: AppSpacing.xs),
          Text(AppInfo.tagline, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          const _BottleColors(),
          const SizedBox(height: AppSpacing.xl),
          if (showContinue) ...[
            GameButton(
              key: const Key('continue-saved-match'),
              label: 'Continue saved match',
              semanticsLabel: 'Continue saved match',
              backgroundColor: AppColors.yellow,
              icon: FLucideIcons.play,
              onPressed: () => context.push('/recovery'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          GameButton(
            key: const Key('new-game'),
            label: 'New game',
            semanticsLabel: 'New game',
            backgroundColor: AppColors.hotPink,
            icon: FLucideIcons.play,
            onPressed: () {
              final replaceId = showContinue ? snapshot.matchId : null;
              context.push(
                replaceId == null
                    ? '/match'
                    : Uri(
                        path: '/match',
                        queryParameters: {'replace': replaceId},
                      ).toString(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Shared device. No account. Players take turns on one device.',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _BottleColors extends StatelessWidget {
  const _BottleColors();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Fifteen bottle colors',
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final color in PieceColors.values)
            DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox(width: 18, height: 18),
            ),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
