import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../application/audio/button_press.dart';
import '../../../application/controllers/match_session_controller.dart';
import '../../../design_system/components/buttons/game_button.dart';
import '../../../design_system/components/buttons/game_switch.dart';
import '../../../design_system/components/fact_card.dart';
import '../../../design_system/components/game_page.dart';
import '../../../design_system/components/segmented_tabs.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../domain/models/configuration.dart';
import '../../../domain/models/player.dart';
import '../../../domain/rules/match_constraints.dart';
import '../../../domain/rules/match_setup_check.dart';
import '../../../domain/rules/player_names.dart';
import '../board/bottle_count_picker.dart';
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
  const PhysicalCompanionScreen({this.initial, this.replaceMatchId, super.key});

  final SetupDraft? initial;

  /// Saved match New game is allowed to replace without asking again.
  final String? replaceMatchId;

  @override
  ConsumerState<PhysicalCompanionScreen> createState() =>
      _PhysicalCompanionScreenState();
}

class _PhysicalCompanionScreenState
    extends ConsumerState<PhysicalCompanionScreen> {
  final List<TextEditingController> _names = [];
  final List<int> _avatars = [];
  var _step = 0;
  var _panel = 0;
  var _rule = WinRule.firstToTarget;
  var _target = MatchConstraints.defaultTarget;
  var _bottles = MatchConstraints.defaultBottles;
  var _timer = TurnTimerDuration.off;
  var _turnOrder = TurnOrder.random;
  var _rejectPrevious = false;
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
    _turnOrder = initial.settings.turnOrder;
    _rejectPrevious = initial.settings.rejectPreviousCombinations;
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
        setState(() {
          _error = null;
          _step -= 1;
        });
      },
      child: GamePage(
        title: _step == 0 ? 'Setup' : 'Review',
        showBack: true,
        footer: _footer(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _step == 0 ? _setupStep() : _reviewStep(),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    final text = Theme.of(context).textTheme;
    final check = _step == 1
        ? MatchSetupCheck.evaluate(roster: _roster(), settings: _settings())
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_error != null) ...[
          Text(_error!, style: text.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
        ],
        ...switch (_step) {
          0 => [
            GameButton(
              key: const Key('continue-to-review'),
              label: 'Review match',
              backgroundColor: AppColors.yellow,
              onPressed: () => setState(() {
                _error = null;
                _step = 1;
              }),
            ),
          ],
          _ => [
            GameButton(
              key: const Key('start-match'),
              label: _starting ? 'Starting' : 'Play game',
              backgroundColor: AppColors.hotPink,
              onPressed: check?.isValid != true || _starting
                  ? null
                  : () => _start(),
            ),
            const SizedBox(height: AppSpacing.sm),
            GameButton(
              key: const Key('practice-turn'),
              label: 'Practice turn',
              backgroundColor: AppColors.cyan,
              foregroundColor: AppColors.ink,
              onPressed: check?.isValid != true || _starting
                  ? null
                  : () => _start(practice: true),
            ),
          ],
        },
      ],
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
      const SizedBox(height: AppSpacing.sm),
      GameButton(
        key: const Key('shuffle-players'),
        label: 'Shuffle players',
        backgroundColor: AppColors.cyan,
        onPressed: _names.length < 2 ? null : _shufflePlayers,
      ),
      const SizedBox(height: AppSpacing.md),
      for (var index = 0; index < _names.length; index++) ...[
        _PlayerNamePanel(
          index: index,
          color: playerColorFor(index),
          face: playerFaceFor(_avatars[index]),
          controller: _names[index],
          onIconPressed: () => _chooseIcon(index),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }

  List<Widget> _setupStep() {
    final roster = _roster();
    final names = visiblePlayerNames(roster);
    return [
      SegmentedTabs(
        tabs: const [
          SegmentedTab(label: 'Players', tabKey: Key('setup-tab-players')),
          SegmentedTab(label: 'Match', tabKey: Key('setup-tab-match')),
        ],
        selectedIndex: _panel,
        onSelected: (index) => setState(() => _panel = index),
      ),
      const SizedBox(height: AppSpacing.lg),
      ...switch (_panel) {
        0 => _playerStep(),
        _ => [
          ..._goalPanel(roster, names),
          const SizedBox(height: AppSpacing.lg),
          ..._bottlePanel(),
          const SizedBox(height: AppSpacing.lg),
          ..._turnPanel(),
        ],
      },
    ];
  }

  List<Widget> _goalPanel(List<Player> roster, List<String> names) {
    return [
      FSelect<WinRule>.rich(
        key: const Key('win-rule'),
        label: const Text('Win rule'),
        description: Text(
          _rule == WinRule.firstToTarget
              ? 'The first player to reach the target wins.'
              : 'Only the selected player can end the match.',
        ),
        format: _winRuleLabel,
        size: FTextFieldSizeVariant.lg,
        control: FSelectControl.lifted(
          value: _rule,
          onChange: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _rule = value;
              if (value == WinRule.selectedPlayerReachesTarget) {
                _selectedId ??= roster.first.id;
              }
            });
          },
        ),
        children: [
          const FSelectItem(
            key: Key('win-rule-any'),
            title: Text('First player to the target'),
            value: WinRule.firstToTarget,
          ),
          const FSelectItem(
            key: Key('win-rule-one'),
            title: Text('Selected player reaches the target'),
            value: WinRule.selectedPlayerReachesTarget,
          ),
        ],
      ),
      if (_rule == WinRule.selectedPlayerReachesTarget) ...[
        const SizedBox(height: AppSpacing.md),
        FSelect<String>.rich(
          key: const Key('selected-player'),
          label: const Text('Player'),
          description: const Text('Only this player ends the match.'),
          format: (id) {
            final index = roster.indexWhere((player) => player.id == id);
            return index < 0 ? '' : names[index];
          },
          size: FTextFieldSizeVariant.lg,
          control: FSelectControl.lifted(
            value: _selectedId,
            onChange: (value) {
              if (value == null) {
                return;
              }
              setState(() => _selectedId = value);
            },
          ),
          children: [
            for (var index = 0; index < roster.length; index++)
              FSelectItem(
                key: Key('selected-player-${roster[index].id}'),
                title: Text(names[index]),
                value: roster[index].id,
              ),
          ],
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
    ];
  }

  List<Widget> _bottlePanel() {
    return [
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
        'The difficulty label does not change scoring or the timer.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.sm),
      BottleCountPicker(count: _bottles),
      const SizedBox(height: AppSpacing.md),
      GameSwitch(
        value: _rejectPrevious,
        semanticsLabel: 'Reject previous combinations',
        label: const Text('Reject previous combinations'),
        description: const Text(
          'A combination that was already checked cannot be submitted again.',
        ),
        onChange: (enabled) => setState(() => _rejectPrevious = enabled),
      ),
    ];
  }

  List<Widget> _turnPanel() {
    return [
      FSelect<TurnOrder>.rich(
        key: const Key('turn-order'),
        label: const Text('Player order'),
        description: Text(turnOrderSummary(_turnOrder)),
        format: turnOrderName,
        size: FTextFieldSizeVariant.lg,
        control: FSelectControl.lifted(
          value: _turnOrder,
          onChange: (value) {
            if (value == null) {
              return;
            }
            setState(() => _turnOrder = value);
          },
        ),
        children: [
          for (final choice in TurnOrder.values)
            FSelectItem(
              key: Key('turn-order-${choice.name}'),
              title: Text(turnOrderName(choice)),
              subtitle: Text(turnOrderSummary(choice)),
              value: choice,
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      FSelect<TurnTimerDuration>.rich(
        key: const Key('turn-timer'),
        label: const Text('Turn timer'),
        format: timerSummary,
        size: FTextFieldSizeVariant.lg,
        control: FSelectControl.lifted(
          value: _timer,
          onChange: (value) {
            if (value == null) {
              return;
            }
            setState(() => _timer = value);
          },
        ),
        children: [
          for (final choice in TurnTimerDuration.values)
            FSelectItem(
              key: Key('timer-${choice.name}'),
              title: Text(timerSummary(choice)),
              value: choice,
            ),
        ],
      ),
    ];
  }

  List<Widget> _reviewStep() {
    final roster = _roster();
    final settings = _settings();
    final names = visiblePlayerNames(roster);
    final check = MatchSetupCheck.evaluate(roster: roster, settings: settings);
    return [
      FactCard(label: 'Win', value: winConditionSummary(roster, settings)),
      FactCard(label: 'Players', value: '${names.length}: ${names.join(', ')}'),
      FactCard(
        label: 'Bottles',
        value:
            '${settings.bottleCount} · ${bottleDifficultyLabel(settings.bottleCount)}',
      ),
      FactCard(label: 'Timer', value: timerSummary(settings.timer)),
      FactCard(label: 'Order', value: turnOrderName(settings.turnOrder)),
      FactCard(
        label: 'Repeats',
        value: settings.rejectPreviousCombinations ? 'Rejected' : 'Allowed',
      ),
      Text(
        'Everyone shares one hidden bottle order. Drag a bottle onto another, '
        'or tap two bottles, to swap them. Check arrangement shows how many '
        'are in the right position.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      if (!check.isValid) ...[
        const SizedBox(height: AppSpacing.md),
        Text(check.issues.first, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ];
  }

  Future<void> _start({bool practice = false}) async {
    setState(() {
      _starting = true;
      _error = null;
    });
    final outcome = await ref
        .read(matchSessionProvider.notifier)
        .startMatch(
          roster: _roster(),
          settings: _settings(),
          practice: practice,
        );
    if (!mounted) {
      return;
    }
    switch (outcome) {
      case StartMatchReady():
        setState(() => _starting = false);
        unawaited(context.push('/match/play'));
      case StartMatchNeedsConfirmation(:final existing):
        final authorized = existing.matchId == widget.replaceMatchId;
        if (!authorized) {
          final replace = await _confirmReplace();
          if (!mounted) {
            return;
          }
          if (replace != true) {
            setState(() => _starting = false);
            return;
          }
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

  void _shufflePlayers() {
    final order = [for (var index = 0; index < _names.length; index++) index];
    final random = Random();
    for (var index = order.length - 1; index > 0; index--) {
      final swapIndex = random.nextInt(index + 1);
      final current = order[index];
      order[index] = order[swapIndex];
      order[swapIndex] = current;
    }
    setState(() {
      final names = [for (final index in order) _names[index]];
      final avatars = [for (final index in order) _avatars[index]];
      _names
        ..clear()
        ..addAll(names);
      _avatars
        ..clear()
        ..addAll(avatars);
    });
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
      turnOrder: _turnOrder,
      rejectPreviousCombinations: _rejectPrevious,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
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
      ),
    );
  }
}

class _StepButton extends ConsumerWidget {
  const _StepButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return buttonTap(
      ref,
      onPressed: onPressed,
      child: Semantics(
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
      ),
    );
  }
}

class _PlayerNamePanel extends StatelessWidget {
  const _PlayerNamePanel({
    required this.index,
    required this.color,
    required this.face,
    required this.controller,
    required this.onIconPressed,
  });

  static const height = 62.0;

  final int index;
  final Color color;
  final PlayerFace face;
  final TextEditingController controller;
  final VoidCallback onIconPressed;

  @override
  Widget build(BuildContext context) {
    final onColor = _onPlayerColor(color);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: height),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: AppColors.cream.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              _PlayerBadge(
                child: Text(
                  '${index + 1}',
                  style: AppTypography.headline.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PlayerIconButton(
                index: index,
                face: face,
                color: color,
                onPressed: onIconPressed,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: MatchConstraints.maxNameLength,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: onColor,
                  style: AppTypography.emphasis.copyWith(color: onColor),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerBadge extends StatelessWidget {
  const _PlayerBadge({required this.child});

  static const size = 34.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: FittedBox(child: child),
        ),
      ),
    );
  }
}

class _PlayerIconButton extends ConsumerWidget {
  const _PlayerIconButton({
    required this.index,
    required this.face,
    required this.color,
    required this.onPressed,
  });

  final int index;
  final PlayerFace face;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return buttonTap(
      ref,
      onPressed: onPressed,
      child: Semantics(
        button: true,
        label: 'Player ${index + 1} icon, ${face.label}',
        excludeSemantics: true,
        child: Material(
          key: Key('player-icon-$index'),
          type: MaterialType.transparency,
          child: InkWell(
            enableFeedback: false,
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppTouch.minimum,
                minHeight: AppTouch.minimum,
              ),
              child: Center(
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cream,
                    border: Border.all(color: AppColors.ink, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.55),
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(face.icon, color: color, size: 26),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _onPlayerColor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? AppColors.cream
      : AppColors.ink;
}

String _winRuleLabel(WinRule rule) {
  return switch (rule) {
    WinRule.firstToTarget => 'First player to the target',
    WinRule.selectedPlayerReachesTarget => 'Selected player reaches the target',
  };
}
