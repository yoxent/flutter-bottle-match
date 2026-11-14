import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../application/controllers/match_session_controller.dart';
import '../../../design_system/components/buttons/game_button.dart';
import '../../../design_system/components/game_page.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../domain/models/configuration.dart';
import '../../../domain/models/player.dart';
import '../../../domain/rules/match_constraints.dart';
import '../../../domain/rules/match_setup_check.dart';
import '../../../domain/rules/player_names.dart';
import 'match_copy.dart';
import 'player_faces.dart';
import 'player_icon_picker.dart';

/// Roster and settings carried back from a finished match.
class SetupDraft {
  const SetupDraft({required this.roster, required this.settings});

  final List<Player> roster;
  final MatchSettings settings;
}

class PhysicalCompanionScreen extends ConsumerStatefulWidget {
  const PhysicalCompanionScreen({this.initial, super.key});

  final SetupDraft? initial;

  @override
  ConsumerState<PhysicalCompanionScreen> createState() =>
      _PhysicalCompanionScreenState();
}

class _PhysicalCompanionScreenState
    extends ConsumerState<PhysicalCompanionScreen> {
  final List<TextEditingController> _names = [];
  final List<int> _avatars = [];
  var _step = 0;
  var _rule = WinRule.firstToTarget;
  var _target = MatchConstraints.defaultTarget;
  var _bottles = MatchConstraints.defaultBottles;
  var _timer = TurnTimerDuration.off;
  String? _selectedId;
  String? _error;
  var _starting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) {
      _setCount(MatchConstraints.minPlayers, notify: false);
      return;
    }
    for (final player in initial.roster) {
      _names.add(TextEditingController(text: player.name));
      _avatars.add(player.avatarIndex);
    }
    _rule = initial.settings.winRule;
    _target = initial.settings.targetRoundWins;
    _bottles = initial.settings.bottleCount;
    _timer = initial.settings.timer;
    _selectedId = initial.settings.selectedPlayerId ?? initial.roster.first.id;
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
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _step == 0) {
          return;
        }
        setState(() => _step -= 1);
      },
      child: GamePage(
        title: switch (_step) {
          0 => 'Players',
          1 => 'Match settings',
          _ => 'Review',
        },
        showBack: true,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...switch (_step) {
                0 => _playerStep(),
                1 => _rulesStep(),
                _ => _reviewStep(),
              },
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _playerStep() {
    return [
      Text(
        'Choose who is playing. Blank names become Player 1, Player 2, and so on.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.md),
      _Stepper(
        label: '${_names.length} players',
        fewerLabel: 'Fewer players',
        moreLabel: 'More players',
        onFewer: _names.length <= MatchConstraints.minPlayers
            ? null
            : () => _setCount(_names.length - 1),
        onMore: _names.length >= MatchConstraints.maxPlayers
            ? null
            : () => _setCount(_names.length + 1),
      ),
      const SizedBox(height: AppSpacing.md),
      for (var index = 0; index < _names.length; index++) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PlayerIconButton(
              index: index,
              face: playerFaceFor(_avatars[index]),
              onPressed: () => _chooseIcon(index),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _names[index],
                maxLength: MatchConstraints.maxNameLength,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Player ${index + 1}',
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      GameButton(
        key: const Key('continue-to-rules'),
        label: 'Continue',
        backgroundColor: AppColors.hotPink,
        onPressed: () => setState(() {
          _error = null;
          _step = 1;
        }),
      ),
    ];
  }

  List<Widget> _rulesStep() {
    final roster = _roster();
    final names = visiblePlayerNames(roster);
    return [
      Text('Win rule', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      _Choice(
        label: 'First player to the target',
        selected: _rule == WinRule.firstToTarget,
        onPressed: () => setState(() => _rule = WinRule.firstToTarget),
      ),
      _Choice(
        label: 'Selected player reaches the target',
        selected: _rule == WinRule.selectedPlayerReachesTarget,
        onPressed: () => setState(() {
          _rule = WinRule.selectedPlayerReachesTarget;
          _selectedId ??= roster.first.id;
        }),
      ),
      if (_rule == WinRule.selectedPlayerReachesTarget) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Only this player ends the match.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var index = 0; index < roster.length; index++)
          _Choice(
            label: names[index],
            selected: _selectedId == roster[index].id,
            onPressed: () => setState(() => _selectedId = roster[index].id),
          ),
      ],
      const SizedBox(height: AppSpacing.md),
      _Stepper(
        label: 'First to $_target',
        fewerLabel: 'Lower target',
        moreLabel: 'Higher target',
        onFewer: _target <= MatchConstraints.minTarget
            ? null
            : () => setState(() => _target -= 1),
        onMore: _target >= MatchConstraints.maxTarget
            ? null
            : () => setState(() => _target += 1),
      ),
      const SizedBox(height: AppSpacing.md),
      _Stepper(
        label: '$_bottles bottles · ${bottleDifficultyLabel(_bottles)}',
        fewerLabel: 'Fewer bottles',
        moreLabel: 'More bottles',
        onFewer: _bottles <= MatchConstraints.minBottles
            ? null
            : () => setState(() => _bottles -= 1),
        onMore: _bottles >= MatchConstraints.maxBottles
            ? null
            : () => setState(() => _bottles += 1),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'The difficulty label does not change scoring or the timer. '
        'Each round uses this many digital bottles.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.md),
      Text('Turn timer', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      for (final choice in TurnTimerDuration.values)
        _Choice(
          label: switch (choice) {
            TurnTimerDuration.off => 'Off',
            TurnTimerDuration.seconds30 => '30 seconds',
            TurnTimerDuration.seconds60 => '60 seconds',
            TurnTimerDuration.seconds90 => '90 seconds',
          },
          selected: _timer == choice,
          onPressed: () => setState(() => _timer = choice),
        ),
      const SizedBox(height: AppSpacing.lg),
      GameButton(
        key: const Key('continue-to-review'),
        label: 'Review match',
        backgroundColor: AppColors.yellow,
        onPressed: () => setState(() {
          _error = null;
          _step = 2;
        }),
      ),
    ];
  }

  List<Widget> _reviewStep() {
    final roster = _roster();
    final settings = _settings();
    final names = visiblePlayerNames(roster);
    final check = MatchSetupCheck.evaluate(roster: roster, settings: settings);
    return [
      _SummaryLine(label: 'Win', value: winConditionSummary(roster, settings)),
      _SummaryLine(
        label: 'Players',
        value: '${names.length}: ${names.join(', ')}',
      ),
      _SummaryLine(
        label: 'Bottles',
        value:
            '${settings.bottleCount} · ${bottleDifficultyLabel(settings.bottleCount)}',
      ),
      _SummaryLine(label: 'Timer', value: timerSummary(settings.timer)),
      const _SummaryLine(label: 'Order', value: 'New order every round'),
      Text(
        'The bottles are digital. The board is not on screen yet, so someone '
        'at the table still records each round winner. The app tracks the '
        'order, the timer, and the score.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      if (!check.isValid) ...[
        const SizedBox(height: AppSpacing.md),
        Text(check.issues.first, style: Theme.of(context).textTheme.bodyLarge),
      ],
      const SizedBox(height: AppSpacing.lg),
      GameButton(
        key: const Key('start-match'),
        label: _starting ? 'Starting' : 'Play game',
        backgroundColor: AppColors.hotPink,
        onPressed: !check.isValid || _starting ? null : _start,
      ),
    ];
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    final outcome = await ref
        .read(matchSessionProvider.notifier)
        .startMatch(roster: _roster(), settings: _settings());
    if (!mounted) {
      return;
    }
    switch (outcome) {
      case StartMatchReady():
        setState(() => _starting = false);
        unawaited(context.push('/match/play'));
      case StartMatchNeedsConfirmation():
        final replace = await _confirmReplace();
        if (!mounted) {
          return;
        }
        if (replace != true) {
          setState(() => _starting = false);
          return;
        }
        final confirmed = await ref
            .read(matchSessionProvider.notifier)
            .startMatch(
              roster: _roster(),
              settings: _settings(),
              replaceConfirmed: true,
            );
        if (!mounted) {
          return;
        }
        setState(() => _starting = false);
        if (confirmed is StartMatchReady) {
          unawaited(context.push('/match/play'));
          return;
        }
        setState(() {
          _error = confirmed is StartMatchRejected
              ? confirmed.reason
              : 'The match could not be started.';
        });
      case StartMatchRejected(:final reason):
        setState(() {
          _starting = false;
          _error = reason;
        });
    }
  }

  Future<bool?> _confirmReplace() {
    return showFDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (context, style, animation) {
        return FDialog(
          semanticsLabel: 'Replace the saved match',
          builder: (context, style) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Replace the saved match?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'An unfinished match is saved on this device. '
                    'Starting a new one replaces it.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GameButton(
                    key: const Key('confirm-replace-match'),
                    label: 'Replace match',
                    backgroundColor: AppColors.hotPink,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GameButton(
                    key: const Key('cancel-replace-match'),
                    label: 'Keep saved match',
                    backgroundColor: AppColors.yellow,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _chooseIcon(int index) async {
    final length = playerFaces.length;
    final current = _avatars[index] % length;
    final used = <int>{
      for (var other = 0; other < _avatars.length; other++)
        if (other != index) _avatars[other] % length,
    };
    final picked = await showPlayerIconPicker(
      context,
      selected: used.contains(current) ? null : current,
      used: used,
      color: playerColorFor(index),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _avatars[index] = picked);
  }

  void _setCount(int count, {bool notify = true}) {
    while (_names.length < count) {
      final number = _names.length + 1;
      _names.add(TextEditingController(text: 'Player $number'));
      _avatars.add(number - 1);
    }
    while (_names.length > count) {
      _names.removeLast().dispose();
      _avatars.removeLast();
    }
    final ids = _roster().map((player) => player.id).toSet();
    if (_selectedId != null && !ids.contains(_selectedId)) {
      _selectedId = ids.isEmpty ? null : ids.first;
    }
    if (notify) {
      setState(() {});
    }
  }

  List<Player> _roster() {
    return [
      for (var index = 0; index < _names.length; index++)
        Player(
          id: 'player-${index + 1}',
          name: normalizePlayerName(_names[index].text, index + 1),
          avatarIndex: _avatars[index],
        ),
    ];
  }

  MatchSettings _settings() {
    return MatchSettings(
      winRule: _rule,
      targetRoundWins: _target,
      selectedPlayerId: _rule == WinRule.selectedPlayerReachesTarget
          ? _selectedId
          : null,
      bottleCount: _bottles,
      timer: _timer,
      physicalEquipmentConfirmed: true,
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.fewerLabel,
    required this.moreLabel,
    required this.onFewer,
    required this.onMore,
  });

  final String label;
  final String fewerLabel;
  final String moreLabel;
  final VoidCallback? onFewer;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(label: fewerLabel, onPressed: onFewer),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        _StepButton(label: moreLabel, onPressed: onMore),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Text(
          onPressed == null
              ? '·'
              : label.startsWith('More') || label.startsWith('Higher')
              ? '+'
              : '−',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        color: AppColors.cream,
        constraints: const BoxConstraints(
          minWidth: AppTouch.minimum,
          minHeight: AppTouch.minimum,
        ),
      ),
    );
  }
}

class _PlayerIconButton extends StatelessWidget {
  const _PlayerIconButton({
    required this.index,
    required this.face,
    required this.onPressed,
  });

  final int index;
  final PlayerFace face;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Player ${index + 1} icon, ${face.label}',
      excludeSemantics: true,
      child: Material(
        key: Key('player-icon-$index'),
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: SizedBox(
            width: AppTouch.minimum,
            height: AppTouch.minimum,
            child: Icon(face.icon, color: playerColorFor(index)),
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.titleMedium?.copyWith(color: AppColors.yellow),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: theme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.ink : AppColors.cream;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected ? AppColors.yellow : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppTouch.minimum),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
