import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../application/controllers/match_session_controller.dart';
import '../../../application/controllers/saved_match_controller.dart';
import '../../../application/controllers/settings_controller.dart';
import '../../../design_system/components/action_footer.dart';
import '../../../design_system/components/buttons/game_button.dart';
import '../../../design_system/components/game_page.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../domain/models/configuration.dart';
import '../../../domain/models/match_phase.dart';
import '../../../domain/models/match_snapshot.dart';
import '../../../domain/models/player.dart';
import '../../../domain/rules/bottle_round.dart';
import '../../../domain/rules/goal_evaluation.dart';
import '../../../domain/rules/phase_transition.dart';
import '../../../domain/rules/player_names.dart';
import '../board/bottle_rack.dart';
import 'guess_feedback_view.dart';
import 'match_copy.dart';
import 'physical_companion_screen.dart';
import 'player_faces.dart';
import 'round_opening_view.dart';
import 'round_win_view.dart';

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
  DateTime? _expiredFor;
  var _leaving = false;
  var _allowPop = false;
  var _guessFeedback = false;

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

    final snapshot = session.asData?.value;
    final swapping = _isSwapping(snapshot);
    final gating = _isTurnGate(snapshot);
    final opening = snapshot?.phase == MatchPhase.roundIntroduction;
    final feedback = _guessFeedback && gating;
    final stage = opening || (gating && !feedback);
    final locked = _playLocked(snapshot);
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _leaving || _playLocked(snapshot)) {
          return;
        }
        unawaited(_leave());
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          GamePage(
            title: stage ? null : _pageTitle(snapshot),
            showBack: !stage && !locked,
            bleed: stage,
            onBack: () => unawaited(_leave()),
            actions: swapping || feedback
                ? _boardActions(snapshot!, showClock: swapping)
                : const [],
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
                  onHome: () {
                    ref.invalidate(savedMatchProvider);
                    context.go('/');
                  },
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
                  onBack: () => unawaited(_leave()),
                  guessFeedback: _guessFeedback && _isTurnGate(snapshot),
                  onCheck: _checkArrangement,
                );
              },
            ),
          ),
          if (feedback && snapshot != null)
            GuessFeedbackView(
              snapshot: snapshot,
              onNext: () => setState(() => _guessFeedback = false),
            ),
        ],
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
    _scheduleExpiry(snapshot);
  }

  void _scheduleExpiry(MatchSnapshot? snapshot) {
    if (snapshot == null || !snapshot.judgesGuesses) {
      return;
    }
    if (snapshot.phase != MatchPhase.activeTurn ||
        snapshot.settings.timer == TurnTimerDuration.off ||
        snapshot.timer.remainingAt(DateTime.now()) > Duration.zero ||
        _expiredFor == snapshot.updatedAt) {
      return;
    }
    _expiredFor = snapshot.updatedAt;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _run(() => ref.read(matchSessionProvider.notifier).expireTurn()),
      );
    });
  }

  Future<void> _run(Future<String?> Function() action) async {
    final error = await action();
    if (!mounted) {
      return;
    }
    setState(() => _error = error);
  }

  Future<void> _checkArrangement() async {
    final before = ref.read(matchSessionProvider).asData?.value;
    final error = await ref
        .read(matchSessionProvider.notifier)
        .submitArrangement();
    if (!mounted) {
      return;
    }
    final after = ref.read(matchSessionProvider).asData?.value;
    final feedback =
        error == null &&
        before?.phase == MatchPhase.activeTurn &&
        after?.phase == MatchPhase.playerHandoff &&
        (after?.board?.guesses.length ?? 0) >
            (before?.board?.guesses.length ?? 0);
    setState(() {
      _error = error;
      _guessFeedback = feedback;
    });
  }

  bool _playLocked(MatchSnapshot? snapshot) {
    final phase = snapshot?.phase;
    return phase == MatchPhase.activeTurn ||
        phase == MatchPhase.playerHandoff ||
        phase == MatchPhase.roundResult ||
        phase == MatchPhase.championship;
  }

  Future<void> _leave() async {
    if (_leaving) {
      return;
    }
    _leaving = true;
    final phase = ref.read(matchSessionProvider).asData?.value?.phase;
    if (phase == MatchPhase.championship) {
      if (!mounted) {
        return;
      }
      ref.invalidate(savedMatchProvider);
      context.go('/');
      return;
    }
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

  List<Widget> _boardActions(
    MatchSnapshot snapshot, {
    required bool showClock,
  }) {
    final timerOn = snapshot.settings.timer != TurnTimerDuration.off;
    return [
      if (showClock && timerOn)
        Text(
          formatRemaining(snapshot.timer.remainingAt(DateTime.now())),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      IconButton(
        tooltip: 'Pause',
        onPressed: () => unawaited(
          _run(() async {
            await ref
                .read(matchSessionProvider.notifier)
                .pauseForInterruption();
            return null;
          }),
        ),
        icon: const Icon(FLucideIcons.pause),
        color: AppColors.cream,
        constraints: const BoxConstraints(
          minWidth: AppTouch.minimum,
          minHeight: AppTouch.minimum,
        ),
      ),
    ];
  }
}

bool _isSwapping(MatchSnapshot? snapshot) {
  return snapshot != null &&
      snapshot.phase == MatchPhase.activeTurn &&
      snapshot.judgesGuesses;
}

bool _isTurnGate(MatchSnapshot? snapshot) {
  return snapshot != null &&
      snapshot.phase == MatchPhase.playerHandoff &&
      snapshot.judgesGuesses;
}

String? _pageTitle(MatchSnapshot? snapshot) {
  if (_isSwapping(snapshot) || _isTurnGate(snapshot)) {
    return currentPlayerName(snapshot!);
  }
  if (_celebratesRound(snapshot)) {
    return null;
  }
  return 'Match';
}

bool _celebratesRound(MatchSnapshot? snapshot) {
  if (snapshot == null) {
    return false;
  }
  if (snapshot.phase == MatchPhase.championship) {
    return true;
  }
  return snapshot.phase == MatchPhase.roundResult &&
      snapshot.board?.practice != true;
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({
    required this.snapshot,
    required this.error,
    required this.winnerId,
    required this.onWinner,
    required this.onRun,
    required this.onHome,
    required this.onChangeSettings,
    required this.onBack,
    required this.guessFeedback,
    required this.onCheck,
  });

  final MatchSnapshot snapshot;
  final String? error;
  final String? winnerId;
  final ValueChanged<String> onWinner;
  final Future<void> Function(Future<String?> Function() action) onRun;
  final VoidCallback onHome;
  final VoidCallback onChangeSettings;
  final VoidCallback onBack;
  final bool guessFeedback;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(matchSessionProvider.notifier);
    if (snapshot.phase == MatchPhase.roundIntroduction) {
      return RoundOpeningView(
        snapshot: snapshot,
        error: error,
        onBegin: () => onRun(notifier.beginRound),
        onBack: onBack,
        onPause: () => onRun(() async {
          await notifier.pauseForInterruption();
          return null;
        }),
      );
    }
    final reducedMotion = ref
        .watch(settingsControllerProvider)
        .maybeWhen(data: (value) => value.reducedMotion, orElse: () => true);
    final goal = evaluateMatchGoal(
      rule: snapshot.settings.winRule,
      target: snapshot.settings.targetRoundWins,
      selectedPlayerId: snapshot.settings.selectedPlayerId,
      scores: snapshot.scores,
    );

    final phase = _phase(
      context,
      notifier,
      reducedMotion: reducedMotion,
      goal: goal,
    );
    if (_isTurnGate(snapshot) && guessFeedback) {
      final board = snapshot.board!;
      return IgnorePointer(
        child: BottleRack(
          arrangement: board.pending,
          opening: board.labelOrder,
          onSwap: (_, _) {},
        ),
      );
    }
    if (_isTurnGate(snapshot)) {
      return PassPhoneView(
        snapshot: snapshot,
        error: error,
        onReady: () => onRun(notifier.markReady),
        onPause: () => onRun(() async {
          await notifier.pauseForInterruption();
          return null;
        }),
      );
    }
    if (_isSwapping(snapshot)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SwapStatus(snapshot: snapshot),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: BottleRack(
              arrangement: snapshot.board!.pending,
              opening: snapshot.board!.labelOrder,
              onSwap: (from, to) =>
                  onRun(() => notifier.moveBottle(from: from, to: to)),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(error!, style: Theme.of(context).textTheme.bodyLarge),
          ],
          ActionFooter(child: phase.actions.single),
        ],
      );
    }
    final celebrate = _celebratesRound(snapshot);
    final opening = snapshot.phase == MatchPhase.roundIntroduction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!celebrate && !opening) ...[
          _MatchHeader(
            snapshot: snapshot,
            showScores: _showsScores(snapshot.phase),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Expanded(
          child: celebrate
              ? phase.body.single
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: phase.body,
                  ),
                ),
        ),
        if (error != null || phase.actions.isNotEmpty)
          ActionFooter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null) ...[
                  Text(error!, style: Theme.of(context).textTheme.bodyLarge),
                  if (phase.actions.isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),
                ],
                for (var index = 0; index < phase.actions.length; index++) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.xs),
                  phase.actions[index],
                ],
              ],
            ),
          ),
      ],
    );
  }

  ({List<Widget> body, List<Widget> actions}) _phase(
    BuildContext context,
    MatchSessionController notifier, {
    required bool reducedMotion,
    required GoalEvaluation goal,
  }) {
    final text = Theme.of(context).textTheme;
    return switch (snapshot.phase) {
      MatchPhase.roundIntroduction => (body: const [], actions: const []),
      MatchPhase.playerHandoff => (
        body: [
          _playerHero(context, currentPlayerName(snapshot)),
          Text('Next: ${nextPlayerName(snapshot)}', style: text.bodyLarge),
          if (snapshot.settings.timer != TurnTimerDuration.off) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The timer starts when the player is ready.',
              style: text.bodyLarge,
            ),
          ],
          ..._latestCount(context),
        ],
        actions: [
          _primary(
            key: const Key('player-ready'),
            label: "I'm ready",
            color: AppColors.yellow,
            onPressed: () => onRun(notifier.markReady),
          ),
          _pause(notifier),
        ],
      ),
      MatchPhase.activeTurn => (
        body: [
          if (!snapshot.judgesGuesses) ...[
            _playerHero(context, currentPlayerName(snapshot)),
            Text('Next: ${nextPlayerName(snapshot)}', style: text.bodyLarge),
            ..._timerCopy(context),
          ],
        ],
        actions: [
          if (snapshot.judgesGuesses)
            _primary(
              key: const Key('check-arrangement'),
              label: 'Check arrangement',
              color: AppColors.hotPink,
              onPressed: onCheck,
            )
          else ...[
            _primary(
              key: const Key('record-winner'),
              label: 'Record round winner',
              color: AppColors.hotPink,
              onPressed: () => onRun(notifier.requestWinner),
            ),
            _primary(
              key: const Key('next-player'),
              label: 'Next player',
              color: AppColors.cyan,
              onPressed: () => onRun(notifier.advancePlayer),
            ),
          ],
          if (!snapshot.judgesGuesses) _pause(notifier),
        ],
      ),
      MatchPhase.physicalResultConfirmation => (
        body: [
          Text('Who won this round?', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final player in snapshot.roster)
            _WinnerChoice(
              label: visibleName(snapshot.roster, player.id),
              selected: winnerId == player.id,
              onPressed: () => onWinner(player.id),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text('The table records this winner.', style: text.bodyLarge),
        ],
        actions: [
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
      ),
      MatchPhase.roundResult => (
        body: [
          if (snapshot.board?.practice == true) ...[
            Text(_practiceTitle(), style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Practice does not score. The real round uses a new hidden order.',
              style: text.bodyLarge,
            ),
          ] else
            RoundWinView(
              snapshot: snapshot,
              reducedMotion: reducedMotion,
              note: goal.status == GoalStatus.ambiguous
                  ? 'More than one player is at the target. '
                        'This match does not name a champion.'
                  : null,
            ),
        ],
        actions: [
          if (snapshot.board?.practice == true)
            _primary(
              key: const Key('play-real-round'),
              label: 'Play the real round',
              color: AppColors.yellow,
              onPressed: () => onRun(notifier.finishPractice),
            )
          else if (goal.status == GoalStatus.inProgress)
            _primary(
              key: const Key('next-round'),
              label: 'Next round',
              color: AppColors.yellow,
              onPressed: () => onRun(notifier.startNextRound),
            ),
          if (goal.status == GoalStatus.ambiguous)
            _primary(
              key: const Key('end-unfinished'),
              label: 'End unfinished match',
              color: AppColors.cyan,
              onPressed: () => onRun(notifier.endEarly),
            ),
          if (_canCorrect) _correct(notifier),
          if (snapshot.board?.practice == true) _pause(notifier),
        ],
      ),
      MatchPhase.paused => (
        body: [
          Text('Paused', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            snapshot.judgesGuesses
                ? 'Resume returns to the same bottles and the same turn.'
                : 'Resume returns to ${_phaseName(snapshot.resumePhase)}. '
                      'The round order stays as it is.',
            style: text.bodyLarge,
          ),
          if (!snapshot.judgesGuesses) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'The app tracks turns and scores. Someone at the table records '
              'each round winner.',
              style: text.bodyLarge,
            ),
          ],
          if (snapshot.board?.hint != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Position ${snapshot.board!.hint!.position + 1} is '
              '${roundBottleLetter(snapshot.board!.labelOrder, snapshot.board!.hint!.bottle)}.',
              style: text.bodyLarge,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _PauseEditor(
            roster: snapshot.roster,
            onSave: (id, name) =>
                onRun(() => notifier.renamePlayer(playerId: id, rawName: name)),
            onAvatar: (id, index) => onRun(
              () => notifier.changeAvatar(playerId: id, avatarIndex: index),
            ),
          ),
        ],
        actions: [
          _primary(
            key: const Key('resume-match'),
            label: 'Resume',
            color: AppColors.yellow,
            onPressed: () => onRun(notifier.resume),
          ),
          if (_canSkip)
            _secondary(
              label: 'Skip turn',
              onPressed: () => onRun(notifier.skipTurn),
            ),
          if (_canHint)
            _secondary(
              key: const Key('show-hint'),
              label: 'Show a hint',
              onPressed: () => onRun(notifier.takeHint),
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
      ),
      MatchPhase.championship => (
        body: [
          RoundWinView(
            snapshot: snapshot,
            reducedMotion: reducedMotion,
            champion: true,
          ),
        ],
        actions: [
          _primary(
            key: const Key('play-again'),
            label: 'Play again',
            color: AppColors.yellow,
            onPressed: onChangeSettings,
          ),
          _primary(
            key: const Key('back-to-home'),
            label: 'Back to home',
            color: AppColors.electricBlue,
            onPressed: onHome,
          ),
        ],
      ),
      MatchPhase.unfinishedMatch => (
        body: [
          Text('Unfinished match', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'These are the current standings. This is not a championship.',
            style: text.bodyLarge,
          ),
        ],
        actions: const [],
      ),
      MatchPhase.setup => (
        body: const [Text('This match has not opened a round yet.')],
        actions: const [],
      ),
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
          snapshot.judgesGuesses
              ? 'Time is up. This arrangement was not submitted.'
              : 'Time is up. Record the result or move to the next player.',
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
    final color = playerColorFor(
      snapshot.roster.indexWhere((item) => item.id == player.id),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(face.icon, color: color, size: 32),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pause(MatchSessionController notifier) {
    return _secondary(
      label: 'Pause',
      onPressed: () => onRun(() async {
        await notifier.pauseForInterruption();
        return null;
      }),
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
    return !snapshot.judgesGuesses &&
        snapshot.wins.isNotEmpty &&
        !snapshot.wins.last.reversed &&
        canCorrectPhysicalResult(snapshot.phase);
  }

  bool get _canHint {
    final board = snapshot.board;
    return board != null &&
        board.hint == null &&
        snapshot.turnCycle >= bottleHintCycle;
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

  List<Widget> _latestCount(BuildContext context) {
    final guesses = snapshot.board?.guesses ?? const <BottleGuess>[];
    if (guesses.isEmpty) {
      return const [];
    }
    final latest = guesses.last;
    return [
      const SizedBox(height: AppSpacing.sm),
      Text(
        '${latest.correct} of ${snapshot.board!.target.length} correct.',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ];
  }

  String _practiceTitle() {
    final guesses = snapshot.board?.guesses ?? const <BottleGuess>[];
    if (guesses.isEmpty || snapshot.board == null) {
      return 'Practice';
    }
    final latest = guesses.last;
    return '${latest.correct} of ${snapshot.board!.target.length} correct';
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
          Row(
            children: [
              IconButton(
                tooltip: 'Change icon',
                onPressed: () => widget.onAvatar(
                  widget.roster[index].id,
                  widget.roster[index].avatarIndex + 1,
                ),
                icon: Icon(
                  playerFaceFor(widget.roster[index].avatarIndex).icon,
                  color: playerColorFor(index),
                ),
                constraints: const BoxConstraints(
                  minWidth: AppTouch.minimum,
                  minHeight: AppTouch.minimum,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextField(
                  controller: _names[index],
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: 'Name ${index + 1}',
                    counterText: '',
                  ),
                ),
              ),
            ],
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
  return _QuietButton(key: key, label: label, onPressed: onPressed);
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.creamMuted,
          minimumSize: const Size.fromHeight(AppTouch.minimum),
          textStyle: AppTypography.button.copyWith(color: AppColors.creamMuted),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _SwapStatus extends StatelessWidget {
  const _SwapStatus({required this.snapshot});

  final MatchSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final guesses = snapshot.board?.guesses ?? const <BottleGuess>[];
    final latest = guesses.isEmpty ? null : guesses.last.correct;
    final total = snapshot.board?.target.length;
    final hint = snapshot.board?.hint;
    final detail = [
      'Round ${snapshot.roundNumber}',
      'Next ${nextPlayerName(snapshot)}',
      if (latest != null && total != null) '$latest of $total correct',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Position ${hint.position + 1} is ${roundBottleLetter(snapshot.board!.labelOrder, hint.bottle)}.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ],
    );
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({required this.snapshot, required this.showScores});

  final MatchSnapshot snapshot;
  final bool showScores;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final names = visiblePlayerNames(snapshot.roster);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Round ${snapshot.roundNumber} · '
          '${snapshot.settings.bottleCount} bottles',
          style: text.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(goalLabel(snapshot), style: text.titleMedium),
        if (showScores) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (var index = 0; index < snapshot.roster.length; index++)
                _ScoreChip(
                  name: names[index],
                  score: snapshot.scores[snapshot.roster[index].id] ?? 0,
                  color: playerColorFor(index),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

bool _showsScores(MatchPhase phase) {
  return phase == MatchPhase.roundIntroduction ||
      phase == MatchPhase.roundResult ||
      phase == MatchPhase.paused ||
      phase == MatchPhase.championship ||
      phase == MatchPhase.unfinishedMatch;
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.name,
    required this.score,
    required this.color,
  });

  final String name;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox(width: 10, height: 10),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$name $score',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.cream),
            ),
          ],
        ),
      ),
    );
  }
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
