import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/audio/button_press.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../domain/models/match_snapshot.dart';
import 'player_faces.dart';

/// Modal over the board after a check that is not the hidden order.
///
/// The scrim covers the whole screen. [onNext] reveals the pass-the-phone page.
class GuessFeedbackView extends StatelessWidget {
  const GuessFeedbackView({
    required this.snapshot,
    required this.onNext,
    super.key,
  });

  final MatchSnapshot snapshot;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final guesser = _guesser(snapshot);
    final board = snapshot.board!;
    final correct = board.guesses.last.correct;
    final total = board.target.length;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: AppColors.ink.withValues(alpha: 0.25)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: _ResultCard(
                  icon: guesser.icon,
                  color: guesser.color,
                  correct: correct,
                  total: total,
                  onNext: onNext,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

({IconData icon, Color color}) _guesser(MatchSnapshot snapshot) {
  final length = snapshot.roundOrder.length;
  final next = snapshot.currentPlayerIndex ?? 0;
  final index = length == 0 ? 0 : (next - 1 + length) % length;
  final id = length == 0
      ? snapshot.roster.first.id
      : snapshot.roundOrder[index];
  final rosterIndex = snapshot.roster.indexWhere((player) => player.id == id);
  final player = rosterIndex < 0
      ? snapshot.roster.first
      : snapshot.roster[rosterIndex];
  return (
    icon: playerFaceFor(player.avatarIndex).icon,
    color: playerColorFor(rosterIndex < 0 ? 0 : rosterIndex),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.color,
    required this.correct,
    required this.total,
    required this.onNext,
  });

  final IconData icon;
  final Color color;
  final int correct;
  final int total;
  final VoidCallback onNext;

  static const _avatar = 84.0;

  @override
  Widget build(BuildContext context) {
    final count = correct == 1
        ? 'bottle is in the correct position'
        : 'bottles are in the correct position';
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _avatar / 2),
          child: SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.stagePill,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  _avatar / 2 + AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NICE TRY!',
                      textAlign: TextAlign.center,
                      style: AppTypography.stageAnnouncement.copyWith(
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$correct / $total',
                      textAlign: TextAlign.center,
                      style: AppTypography.display.copyWith(
                        color: AppColors.stageYellow,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      count,
                      textAlign: TextAlign.center,
                      style: AppTypography.emphasis,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _NextPlayerButton(onPressed: onNext),
                  ],
                ),
              ),
            ),
          ),
        ),
        _GuesserMark(icon: icon, color: color, size: _avatar),
      ],
    );
  }
}

class _GuesserMark extends StatelessWidget {
  const _GuesserMark({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
      child: Icon(icon, color: color, size: size * 26 / 46),
    );
  }
}

class _NextPlayerButton extends ConsumerWidget {
  const _NextPlayerButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: const [
          BoxShadow(
            color: PieceColors.tangerine,
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: buttonTap(
        ref,
        onPressed: onPressed,
        child: FilledButton(
          key: const Key('next-player-feedback'),
          style: FilledButton.styleFrom(
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            backgroundColor: AppColors.stageYellow,
            foregroundColor: AppColors.stagePanelTop,
            shape: const StadiumBorder(),
            textStyle: AppTypography.stageButton,
          ),
          onPressed: onPressed,
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('NEXT PLAYER'),
          ),
        ),
      ),
    );
  }
}
