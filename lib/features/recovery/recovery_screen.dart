import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/controllers/match_session_controller.dart';
import '../../application/controllers/saved_match_controller.dart';
import '../../design_system/components/buttons/game_button.dart';
import '../../design_system/components/game_page.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../domain/models/configuration.dart';
import '../../domain/models/match_phase.dart';
import '../../domain/models/match_snapshot.dart';
import '../../domain/rules/player_names.dart';

class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedMatchProvider);
    return GamePage(
      title: 'Paused recovery',
      showBack: true,
      body: saved.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('$error'),
        data: (snapshot) {
          if (snapshot == null) {
            return const Text('There is no saved match to recover.');
          }
          return _RecoveryDetails(snapshot: snapshot);
        },
      ),
    );
  }
}

class _RecoveryDetails extends ConsumerStatefulWidget {
  const _RecoveryDetails({required this.snapshot});

  final MatchSnapshot snapshot;

  @override
  ConsumerState<_RecoveryDetails> createState() => _RecoveryDetailsState();
}

class _RecoveryDetailsState extends ConsumerState<_RecoveryDetails> {
  String? _error;

  MatchSnapshot get snapshot => widget.snapshot;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final names = visiblePlayerNames(snapshot.roster);
    final order = [
      for (final id in snapshot.roundOrder) _nameFor(snapshot, names, id),
    ];
    final scores = [
      for (var index = 0; index < snapshot.roster.length; index++)
        '${names[index]} ${snapshot.scores[snapshot.roster[index].id] ?? 0}',
    ];

    return ListView(
      children: [
        Text(_heading(snapshot.phase), style: text.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Resume continues from the saved phase. '
          'The saved order is not reshuffled.',
          style: text.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        GameButton(
          key: const Key('resume-saved-match'),
          label: snapshot.phase == MatchPhase.paused
              ? 'Resume match'
              : 'View match',
          backgroundColor: AppColors.yellow,
          onPressed: _open,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: text.bodyLarge),
        ],
        const SizedBox(height: AppSpacing.lg),
        _Fact(label: 'Mode', value: _modeLabel(snapshot.mode)),
        _Fact(label: 'Phase', value: _phaseLabel(snapshot)),
        _Fact(label: 'Round', value: '${snapshot.roundNumber}'),
        _Fact(label: 'Turn cycle', value: '${snapshot.turnCycle}'),
        _Fact(
          label: 'Order',
          value: order.isEmpty ? 'Not shuffled yet' : order.join(', '),
        ),
        _Fact(label: 'Scores', value: scores.join(' · ')),
        _Fact(
          label: 'Timer',
          value: snapshot.timer.duration == TurnTimerDuration.off
              ? 'Off'
              : _timerLabel(snapshot),
        ),
      ],
    );
  }

  Future<void> _open() async {
    if (snapshot.phase == MatchPhase.paused) {
      final error = await ref.read(matchSessionProvider.notifier).resume();
      if (!mounted) {
        return;
      }
      if (error != null) {
        setState(() => _error = error);
        return;
      }
    }
    if (mounted) {
      await context.push('/match/play');
    }
  }

  String _timerLabel(MatchSnapshot snapshot) {
    final remaining = snapshot.timer.remainingAt(snapshot.updatedAt);
    final seconds = remaining.inSeconds;
    final running = snapshot.timer.isRunning ? 'running' : 'paused';
    return '$seconds seconds left, $running';
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

String _heading(MatchPhase phase) {
  return switch (phase) {
    MatchPhase.championship => 'Completed championship',
    MatchPhase.unfinishedMatch => 'Unfinished match',
    MatchPhase.paused => 'Paused recovery',
    _ => 'Saved match',
  };
}

String _phaseLabel(MatchSnapshot snapshot) {
  if (snapshot.phase == MatchPhase.paused && snapshot.resumePhase != null) {
    return 'Paused. Resume returns to ${snapshot.resumePhase!.name}.';
  }
  return snapshot.phase.name;
}

String _modeLabel(GameMode mode) {
  return switch (mode) {
    GameMode.physicalCompanion => 'Physical save',
    GameMode.fullyDigital => 'Digital',
  };
}

String _nameFor(MatchSnapshot snapshot, List<String> names, String id) {
  final index = snapshot.roster.indexWhere((player) => player.id == id);
  if (index < 0) {
    return id;
  }
  return names[index];
}
