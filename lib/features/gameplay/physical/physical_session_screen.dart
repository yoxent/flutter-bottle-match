import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/controllers/match_session_controller.dart';
import '../../../application/controllers/saved_match_controller.dart';
import '../../../application/controllers/settings_controller.dart';
import '../../../design_system/components/buttons/game_button.dart';
import '../../../design_system/components/game_page.dart';
import '../../../design_system/components/indicators/identity_swatch.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../domain/models/configuration.dart';
import '../../../domain/models/match_phase.dart';
import '../../../domain/models/match_snapshot.dart';
import '../../../domain/models/player.dart';
import '../../../domain/rules/goal_evaluation.dart';
import '../../../domain/rules/phase_transition.dart';
import 'match_copy.dart';
import 'physical_companion_screen.dart';
import 'player_faces.dart';

class PhysicalSessionScreen extends ConsumerStatefulWidget {
  const PhysicalSessionScreen({super.key});

  @override
  ConsumerState<PhysicalSessionScreen> createState() =>
      _PhysicalSessionScreenState();
}

class _PhysicalSessionScreenState extends ConsumerState<PhysicalSessionScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  String? _error;
  String? _winnerId;
  var _leaving = false;
  var _allowPop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(ref.read(matchSessionProvider.notifier).pauseForInterruption());
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(matchSessionProvider);
    ref.listen(matchSessionProvider, (_, next) => _syncTicker(next.value));
    _scheduleTicker(session.value);

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _leaving) {
          return;
        }
        unawaited(_leave());
      },
      child: GamePage(
        title: 'Match',
        showBack: true,
        onBack: () => unawaited(_leave()),
        body: session.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('$error'),
          data: (snapshot) {
            if (snapshot == null) {
              return const Text('There is no saved match to play.');
            }
            _rememberWinner(snapshot);
            return _SessionBody(
              snapshot: snapshot,
              error: _error,
              winnerId: _winnerId,
              onWinner: (id) => setState(() => _winnerId = id),
              onRun: _run,
              onPlayAgain: () => _run(
                () => ref.read(matchSessionProvider.notifier).playAgain(),
              ),
              onChangeSettings: () {
                ref.invalidate(savedMatchProvider);
                context.go(
                  '/match',
                  extra: SetupDraft(
                    roster: snapshot.roster,
                    settings: snapshot.settings,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _rememberWinner(MatchSnapshot snapshot) {
    if (snapshot.phase != MatchPhase.physicalResultConfirmation) {
      _winnerId = null;
      return;
    }
    _winnerId ??= currentPlayerId(snapshot);
  }

  void _scheduleTicker(MatchSnapshot? snapshot) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncTicker(snapshot);
      }
    });
  }

  void _syncTicker(MatchSnapshot? snapshot) {
    final running =
        snapshot != null &&
        snapshot.phase == MatchPhase.activeTurn &&
        snapshot.timer.isRunning;
    if (running && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
      return;
    }
    if (!running) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _run(Future<String?> Function() action) async {
    final error = await action();
    if (!mounted) {
      return;
    }
    setState(() => _error = error);
  }

  Future<void> _leave() async {
    if (_leaving) {
      return;
    }
    _leaving = true;
    await ref.read(matchSessionProvider.notifier).pauseForInterruption();
    ref.invalidate(savedMatchProvider);
    if (!mounted) {
      return;
    }
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.pop();
      }
    });
  }
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({
    required this.snapshot,
    required this.error,
    required this.winnerId,
    required this.onWinner,
    required this.onRun,
    required this.onPlayAgain,
    required this.onChangeSettings,
  });

  final MatchSnapshot snapshot;
  final String? error;
  final String? winnerId;
  final ValueChanged<String> onWinner;
  final Future<void> Function(Future<String?> Function() action) onRun;
  final VoidCallback onPlayAgain;
  final VoidCallback onChangeSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(matchSessionProvider.notifier);
    final reducedMotion = ref
        .watch(settingsControllerProvider)
        .maybeWhen(data: (value) => value.reducedMotion, orElse: () => true);
    final goal = evaluateMatchGoal(
      rule: snapshot.settings.winRule,
      target: snapshot.settings.targetRoundWins,
      selectedPlayerId: snapshot.settings.selectedPlayerId,
      scores: snapshot.scores,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Round ${snapshot.roundNumber} · ${goalLabel(snapshot)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${snapshot.settings.bottleCount} bottles · '
            '${standingsLabel(snapshot)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          ..._phase(
            context,
            notifier,
            reducedMotion: reducedMotion,
            goal: goal,
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(error!, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }

  List<Widget> _phase(
    BuildContext context,
    MatchSessionController notifier, {
    required bool reducedMotion,
    required GoalEvaluation goal,
  }) {
    return switch (snapshot.phase) {
      MatchPhase.roundIntroduction => [
        Text(
          'Order: ${_orderNames()}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        _primary(
          key: const Key('begin-round'),
          label: 'Begin round',
          color: AppColors.hotPink,
          onPressed: () => onRun(notifier.beginRound),
        ),
        _pause(notifier),
      ],
      MatchPhase.playerHandoff => [
        _playerHero(context, currentPlayerName(snapshot)),
        Text(
          'Next: ${nextPlayerName(snapshot)}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (snapshot.settings.timer != TurnTimerDuration.off) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The timer starts when the player is ready.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _primary(
          key: const Key('player-ready'),
          label: "I'm ready",
          color: AppColors.yellow,
          onPressed: () => onRun(notifier.markReady),
        ),
        _pause(notifier),
      ],
      MatchPhase.activeTurn => [
        _playerHero(context, currentPlayerName(snapshot)),
        Text(
          'Next: ${nextPlayerName(snapshot)}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        ..._timerCopy(context),
        const SizedBox(height: AppSpacing.md),
        _primary(
          key: const Key('record-winner'),
          label: 'Record round winner',
          color: AppColors.hotPink,
          onPressed: () => onRun(notifier.requestWinner),
        ),
        const SizedBox(height: AppSpacing.sm),
        _primary(
          key: const Key('next-player'),
          label: 'Next player',
          color: AppColors.cyan,
          onPressed: () => onRun(notifier.advancePlayer),
        ),
        _pause(notifier),
      ],
      MatchPhase.physicalResultConfirmation => [
        Text(
          'Who won this round?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final player in snapshot.roster)
          _WinnerChoice(
            label: visibleName(snapshot.roster, player.id),
            selected: winnerId == player.id,
            onPressed: () => onWinner(player.id),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'The table records this winner.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        _primary(
          key: const Key('confirm-winner'),
          label: 'Confirm winner',
          color: AppColors.hotPink,
          onPressed: winnerId == null
              ? null
              : () => onRun(() => notifier.confirmWinner(winnerId!)),
        ),
        _pause(notifier),
      ],
      MatchPhase.roundResult => [
        Text('+1 point', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          goal.status == GoalStatus.ambiguous
              ? 'More than one player is at the target. '
                    'This match does not name a champion.'
              : 'The round is recorded. Check the standings above.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        if (goal.status == GoalStatus.inProgress)
          _primary(
            key: const Key('next-round'),
            label: 'Next round',
            color: AppColors.yellow,
            onPressed: () => onRun(notifier.startNextRound),
          ),
        if (goal.status == GoalStatus.ambiguous) ...[
          const SizedBox(height: AppSpacing.sm),
          _primary(
            key: const Key('end-unfinished'),
            label: 'End unfinished match',
            color: AppColors.cyan,
            onPressed: () => onRun(notifier.endEarly),
          ),
        ],
        if (_canCorrect) _correct(notifier),
        _pause(notifier),
      ],
      MatchPhase.paused => [
        Text('Paused', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Resume returns to ${_phaseName(snapshot.resumePhase)}. '
          'The round order stays as it is.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        _primary(
          key: const Key('resume-match'),
          label: 'Resume',
          color: AppColors.yellow,
          onPressed: () => onRun(notifier.resume),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'The app tracks turns and scores. Someone at the table records '
          'each round winner. The digital bottles are not on screen yet.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        _PauseEditor(
          roster: snapshot.roster,
          onSave: (id, name) =>
              onRun(() => notifier.renamePlayer(playerId: id, rawName: name)),
          onAvatar: (id, index) => onRun(
            () => notifier.changeAvatar(playerId: id, avatarIndex: index),
          ),
        ),
        if (_canSkip)
          _secondary(
            label: 'Skip turn',
            onPressed: () => onRun(notifier.skipTurn),
          ),
        if (_canAbandon)
          _secondary(
            label: 'Abandon round',
            onPressed: () => onRun(notifier.abandonRound),
          ),
        _secondary(
          label: 'End unfinished match',
          onPressed: () => onRun(notifier.endEarly),
        ),
      ],
      MatchPhase.championship => [
        _Championship(snapshot: snapshot, reducedMotion: reducedMotion),
        const SizedBox(height: AppSpacing.md),
        _primary(
          key: const Key('play-again'),
          label: 'Play again',
          color: AppColors.hotPink,
          onPressed: onPlayAgain,
        ),
        const SizedBox(height: AppSpacing.sm),
        _primary(
          key: const Key('change-settings'),
          label: 'Change settings',
          color: AppColors.yellow,
          onPressed: onChangeSettings,
        ),
        if (_canCorrect) _correct(notifier),
      ],
      MatchPhase.unfinishedMatch => [
        Text(
          'Unfinished match',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'These are the current standings. This is not a championship.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
      MatchPhase.setup => [
        const Text('This match has not opened a round yet.'),
      ],
    };
  }

  List<Widget> _timerCopy(BuildContext context) {
    if (snapshot.settings.timer == TurnTimerDuration.off) {
      return const [];
    }
    final remaining = snapshot.timer.remainingAt(DateTime.now());
    if (remaining == Duration.zero) {
      return [
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Time is up. Record the result or move to the next player.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ];
    }
    return [
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Time left ${formatRemaining(remaining)}',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ];
  }

  Widget _playerHero(BuildContext context, String name) {
    final index = snapshot.currentPlayerIndex;
    final player = index == null
        ? snapshot.roster.first
        : snapshot.roster.firstWhere(
            (item) => item.id == snapshot.roundOrder[index],
            orElse: () => snapshot.roster.first,
          );
    final face = playerFaceFor(player.avatarIndex);
    return Column(
      children: [
        IdentitySwatch(
          name: face.label,
          icon: face.icon,
          color: playerColorFor(
            snapshot.roster.indexWhere((item) => item.id == player.id),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _pause(MatchSessionController notifier) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: _secondary(
        label: 'Pause',
        onPressed: () => onRun(() async {
          await notifier.pauseForInterruption();
          return null;
        }),
      ),
    );
  }

  Widget _correct(MatchSessionController notifier) {
    return _secondary(
      key: const Key('correct-last-result'),
      label: 'Correct last result',
      onPressed: () => onRun(notifier.correctLastResult),
    );
  }

  bool get _canCorrect {
    return snapshot.wins.isNotEmpty &&
        !snapshot.wins.last.reversed &&
        canCorrectPhysicalResult(snapshot.phase);
  }

  bool get _canSkip {
    const phases = {
      MatchPhase.playerHandoff,
      MatchPhase.activeTurn,
      MatchPhase.physicalResultConfirmation,
    };
    return snapshot.resumePhase != null &&
        phases.contains(snapshot.resumePhase);
  }

  bool get _canAbandon {
    const phases = {
      MatchPhase.roundIntroduction,
      MatchPhase.playerHandoff,
      MatchPhase.activeTurn,
      MatchPhase.physicalResultConfirmation,
    };
    return snapshot.resumePhase != null &&
        phases.contains(snapshot.resumePhase);
  }

  String _orderNames() {
    return [
      for (final id in snapshot.roundOrder) visibleName(snapshot.roster, id),
    ].join(', ');
  }
}

class _WinnerChoice extends StatelessWidget {
  const _WinnerChoice({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: GameButton(
        label: label,
        semanticsLabel: selected ? '$label, selected' : label,
        backgroundColor: selected ? AppColors.yellow : AppColors.card,
        foregroundColor: selected ? AppColors.ink : AppColors.cream,
        onPressed: onPressed,
      ),
    );
  }
}

class _PauseEditor extends StatefulWidget {
  const _PauseEditor({
    required this.roster,
    required this.onSave,
    required this.onAvatar,
  });

  final List<Player> roster;
  final Future<void> Function(String id, String name) onSave;
  final void Function(String id, int avatarIndex) onAvatar;

  @override
  State<_PauseEditor> createState() => _PauseEditorState();
}

class _PauseEditorState extends State<_PauseEditor> {
  late final List<TextEditingController> _names;

  @override
  void initState() {
    super.initState();
    _names = [
      for (final player in widget.roster)
        TextEditingController(text: player.name),
    ];
  }

  @override
  void dispose() {
    for (final controller in _names) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < widget.roster.length; index++) ...[
          TextField(
            controller: _names[index],
            maxLength: 20,
            decoration: InputDecoration(
              labelText: 'Name ${index + 1}',
              counterText: '',
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(AppTouch.minimum, AppTouch.minimum),
              ),
              onPressed: () => widget.onAvatar(
                widget.roster[index].id,
                widget.roster[index].avatarIndex + 1,
              ),
              child: Text(
                'Avatar: ${playerFaceFor(widget.roster[index].avatarIndex).label}',
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        GameButton(
          label: 'Save names',
          backgroundColor: AppColors.cyan,
          onPressed: () async {
            for (var index = 0; index < widget.roster.length; index++) {
              await widget.onSave(widget.roster[index].id, _names[index].text);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _Championship extends StatefulWidget {
  const _Championship({required this.snapshot, required this.reducedMotion});

  final MatchSnapshot snapshot;
  final bool reducedMotion;

  @override
  State<_Championship> createState() => _ChampionshipState();
}

class _ChampionshipState extends State<_Championship>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.reducedMotion) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _Championship oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion && _entrance.value != 1) {
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
    final text = Theme.of(context).textTheme;
    final selected =
        widget.snapshot.settings.winRule == WinRule.selectedPlayerReachesTarget;
    return FadeTransition(
      opacity: _entrance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(championTitle(widget.snapshot), style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          if (selected)
            Text(
              'You reached ${widget.snapshot.settings.targetRoundWins} round wins.',
              style: text.bodyLarge,
            ),
          Text(
            '${widget.snapshot.settings.bottleCount} bottles · '
            '${widget.snapshot.roundNumber} rounds played',
            style: text.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(roundWinnerLines(widget.snapshot), style: text.bodyLarge),
        ],
      ),
    );
  }
}

Widget _primary({
  required Key key,
  required String label,
  required Color color,
  required VoidCallback? onPressed,
}) {
  return GameButton(
    key: key,
    label: label,
    backgroundColor: color,
    onPressed: onPressed,
  );
}

Widget _secondary({
  Key? key,
  required String label,
  required VoidCallback? onPressed,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: GameButton(
      key: key,
      label: label,
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.cream,
      onPressed: onPressed,
    ),
  );
}

String _phaseName(MatchPhase? phase) {
  return switch (phase) {
    MatchPhase.roundIntroduction => 'the round introduction',
    MatchPhase.playerHandoff => 'the player handoff',
    MatchPhase.activeTurn => 'the active turn',
    MatchPhase.physicalResultConfirmation => 'winner confirmation',
    MatchPhase.roundResult => 'the round result',
    _ => 'the saved phase',
  };
}
