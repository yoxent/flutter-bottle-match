import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../application/controllers/saved_match_controller.dart';
import '../../application/controllers/settings_controller.dart';
import '../../core/constants/app_info.dart';
import '../../design_system/components/buttons/game_button.dart';
import '../../design_system/components/game_page.dart';
import '../../design_system/components/indicators/identity_swatch.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
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
      title: AppInfo.name,
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
          Text(AppInfo.tagline, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              IdentitySwatch(
                name: 'Star',
                icon: FLucideIcons.star,
                color: AppColors.yellow,
              ),
              IdentitySwatch(
                name: 'Moon',
                icon: FLucideIcons.moon,
                color: AppColors.cyan,
              ),
              IdentitySwatch(
                name: 'Heart',
                icon: FLucideIcons.heart,
                color: AppColors.hotPink,
              ),
              IdentitySwatch(
                name: 'Bolt',
                icon: FLucideIcons.zap,
                color: AppColors.electricBlue,
              ),
              IdentitySwatch(
                name: 'Drop',
                icon: FLucideIcons.droplet,
                color: AppColors.lime,
              ),
            ],
          ),
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
            key: const Key('physical-companion'),
            label: 'Physical Companion',
            semanticsLabel: 'Physical Companion',
            backgroundColor: AppColors.hotPink,
            icon: FLucideIcons.users,
            onPressed: () => context.push('/physical'),
          ),
          const SizedBox(height: AppSpacing.sm),
          GameButton(
            key: const Key('fully-digital'),
            label: 'Fully Digital',
            semanticsLabel: 'Fully Digital, not implemented',
            backgroundColor: AppColors.cyan,
            icon: FLucideIcons.smartphone,
            onPressed: () => context.push('/digital'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Shared device. No account. Release 1 tracks a physical match. '
            'Fully Digital is Release 2 and is not playable yet.',
            style: Theme.of(context).textTheme.labelLarge,
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
