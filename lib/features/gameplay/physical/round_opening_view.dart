import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../application/audio/button_press.dart';
import '../../../design_system/layout/game_viewport.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../domain/models/match_snapshot.dart';
import 'match_copy.dart';
import 'player_faces.dart';

/// Shown between turns so the phone can be handed to the player about to play.
class PassPhoneView extends StatelessWidget {
  const PassPhoneView({
    required this.snapshot,
    required this.onReady,
    required this.onPause,
    this.error,
    super.key,
  });

  final MatchSnapshot snapshot;
  final String? error;
  final VoidCallback onReady;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final current = currentPlayerName(snapshot);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: GameViewport.maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                _StageHeader(
                  label: roundOpeningLabel(snapshot.roundNumber),
                  score: roundOpeningScoreLine(snapshot),
                  onPause: onPause,
                ),
                const SizedBox(height: AppSpacing.lg),
                const _NewRoundAnnouncement(headline: 'PASS THE PHONE!'),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      children: [
                        _PassTurn(snapshot: snapshot),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Hand the phone to $current.',
                          textAlign: TextAlign.center,
                          style: AppTypography.stageNote,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'The board is shared between turns.',
                          textAlign: TextAlign.center,
                          style: AppTypography.stageNote,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (error != null) ...[
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.stageNote.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _BeginRoundButton(
                  label: "I'M READY",
                  buttonKey: const Key('player-ready'),
                  onPressed: onReady,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Party-game introduction shown before a round begins.
class RoundOpeningView extends StatelessWidget {
  const RoundOpeningView({
    required this.snapshot,
    required this.onBegin,
    required this.onBack,
    required this.onPause,
    this.error,
    super.key,
  });

  final MatchSnapshot snapshot;
  final String? error;
  final VoidCallback onBegin;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return _StagePanel(
      key: const Key('turn-order-preview'),
      snapshot: snapshot,
      error: error,
      onBegin: onBegin,
      onBack: onBack,
      onPause: onPause,
    );
  }
}

class _StagePanel extends StatelessWidget {
  const _StagePanel({
    required this.snapshot,
    required this.error,
    required this.onBegin,
    required this.onBack,
    required this.onPause,
    super.key,
  });

  final MatchSnapshot snapshot;
  final String? error;
  final VoidCallback onBegin;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final order = snapshot.settings.turnOrder;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: GameViewport.maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                _StageHeader(
                  label: roundOpeningLabel(snapshot.roundNumber),
                  score: roundOpeningScoreLine(snapshot),
                  onBack: onBack,
                  onPause: onPause,
                ),
                const SizedBox(height: AppSpacing.lg),
                _NewRoundAnnouncement(
                  headline: 'NEW ROUND!',
                  title: roundOpeningOrderTitle(order),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      children: [_PlayerOrder(snapshot: snapshot)],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  roundOpeningOrderNote(order),
                  textAlign: TextAlign.center,
                  style: AppTypography.stageNote,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (error != null) ...[
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.stageNote.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _BeginRoundButton(
                  label: 'BEGIN ROUND',
                  buttonKey: const Key('begin-round'),
                  onPressed: onBegin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageHeader extends StatelessWidget {
  const _StageHeader({
    required this.label,
    required this.score,
    required this.onPause,
    this.onBack,
  });

  final String label;
  final String score;
  final VoidCallback? onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (onBack == null)
              const SizedBox(width: AppTouch.minimum, height: AppTouch.minimum)
            else
              _HeaderIcon(
                tooltip: 'Back',
                icon: FLucideIcons.arrowLeft,
                onPressed: onBack!,
              ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _RoundPill(label: label),
                ),
              ),
            ),
            _HeaderIcon(
              tooltip: 'Pause',
              icon: FLucideIcons.pause,
              onPressed: onPause,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          score,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.stageScore,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 1,
          color: AppColors.creamMuted.withValues(alpha: 0.45),
        ),
      ],
    );
  }
}

class _HeaderIcon extends ConsumerWidget {
  const _HeaderIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return buttonTap(
      ref,
      onPressed: onPressed,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.cream,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: AppTouch.minimum,
          minHeight: AppTouch.minimum,
        ),
      ),
    );
  }
}

class _RoundPill extends StatelessWidget {
  const _RoundPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.stagePill,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.creamMuted, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(label, style: AppTypography.stageKicker),
      ),
    );
  }
}

class _NewRoundAnnouncement extends StatelessWidget {
  const _NewRoundAnnouncement({required this.headline, this.title});

  final String headline;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Sparkle(color: AppColors.stageYellow, size: 18),
              const SizedBox(width: AppSpacing.md),
              Text(headline, style: AppTypography.stageAnnouncement),
              const SizedBox(width: AppSpacing.md),
              const _Sparkle(color: AppColors.cyan, size: 14),
            ],
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: AppTypography.stageOrder,
          ),
        ],
      ],
    );
  }
}

class _PassTurn extends StatelessWidget {
  const _PassTurn({required this.snapshot});

  final MatchSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final index = snapshot.currentPlayerIndex;
    final orderIndex =
        index == null || index < 0 || index >= snapshot.roundOrder.length
        ? 0
        : index;
    final id = snapshot.roundOrder[orderIndex];
    final rosterIndex = snapshot.roster.indexWhere((player) => player.id == id);
    final player = rosterIndex < 0
        ? snapshot.roster.first
        : snapshot.roster[rosterIndex];
    final name = visibleName(snapshot.roster, id);
    final piece = playerColorFor(rosterIndex < 0 ? 0 : rosterIndex);
    final onPiece =
        ThemeData.estimateBrightnessForColor(piece) == Brightness.dark
        ? AppColors.cream
        : AppColors.ink;
    return Column(
      children: [
        Center(
          child: _PlayerAvatar(
            icon: playerFaceFor(player.avatarIndex).icon,
            color: piece,
            size: 72,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: piece,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: AppColors.cream.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Center(
                child: Text(
                  "${name.toUpperCase()}'S TURN",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.stageName.copyWith(color: onPiece),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerOrder extends StatelessWidget {
  const _PlayerOrder({required this.snapshot});

  final MatchSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < snapshot.roundOrder.length; index++)
          _PlayerCard(snapshot: snapshot, index: index),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.snapshot, required this.index});

  final MatchSnapshot snapshot;
  final int index;

  @override
  Widget build(BuildContext context) {
    final id = snapshot.roundOrder[index];
    final rosterIndex = snapshot.roster.indexWhere((player) => player.id == id);
    final player = rosterIndex < 0
        ? snapshot.roster.first
        : snapshot.roster[rosterIndex];
    final name = visibleName(snapshot.roster, id);
    final face = playerFaceFor(player.avatarIndex);
    final piece = playerColorFor(rosterIndex < 0 ? 0 : rosterIndex);
    final onPiece =
        ThemeData.estimateBrightnessForColor(piece) == Brightness.dark
        ? AppColors.cream
        : AppColors.ink;
    final place = index + 1;
    final last = index == snapshot.roundOrder.length - 1;
    return Semantics(
      label: '$place, $name',
      child: Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: piece,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: AppColors.cream.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  _SeatBadge(place: place),
                  const SizedBox(width: AppSpacing.sm),
                  _PlayerAvatar(icon: face.icon, color: piece),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.stageName.copyWith(color: onPiece),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({required this.place});

  final int place;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: FittedBox(child: Text('$place', style: AppTypography.stageSeat)),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({
    required this.icon,
    required this.color,
    this.size = 46,
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

class _BeginRoundButton extends ConsumerWidget {
  const _BeginRoundButton({
    required this.label,
    required this.buttonKey,
    required this.onPressed,
  });

  final String label;
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: DecoratedBox(
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
              key: buttonKey,
              style: FilledButton.styleFrom(
                elevation: 0,
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.stageYellow,
                foregroundColor: AppColors.stagePanelTop,
                shape: const StadiumBorder(),
                textStyle: AppTypography.stageButton,
              ),
              onPressed: onPressed,
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _SparklePainter(color),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.38;
    final path = Path();
    const points = 4;
    for (var index = 0; index < points * 2; index++) {
      final radius = index.isEven ? outer : inner;
      final angle = -math.pi / 2 + index * math.pi / points;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
