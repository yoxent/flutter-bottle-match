import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../domain/models/match_snapshot.dart';
import '../../../domain/models/player.dart';
import 'match_copy.dart';
import 'player_faces.dart';

/// Round-win celebration: confetti, the winner, and the top scorers.
class RoundWinView extends StatelessWidget {
  const RoundWinView({
    required this.snapshot,
    required this.reducedMotion,
    this.note,
    this.champion = false,
    super.key,
  });

  final MatchSnapshot snapshot;
  final bool reducedMotion;
  final String? note;
  final bool champion;

  @override
  Widget build(BuildContext context) {
    final winnerId = champion
        ? championPlayerId(snapshot)
        : latestWinnerId(snapshot);
    final winner = _playerFor(snapshot, winnerId);
    final winnerName = visibleName(snapshot.roster, winnerId);
    final standings = champion ? const <String>[] : topScorerIds(snapshot);

    return Stack(
      key: const Key('round-win'),
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _BurstPainter())),
        Positioned.fill(
          child: _Confetti(
            seed: snapshot.roundNumber,
            reducedMotion: reducedMotion,
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          if (champion) ...[
                            Semantics(
                              label: 'Crown',
                              child: const SizedBox(
                                width: 84,
                                height: 56,
                                child: CustomPaint(painter: _CrownPainter()),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _StrokeLabel(
                              text: 'CHAMPION!',
                              style: AppTypography.display.copyWith(
                                fontSize: 56,
                                height: 1,
                              ),
                              stroke: AppColors.hotPink,
                              strokeWidth: 10,
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.yellow, AppColors.hotPink],
                              ),
                            ),
                          ] else ...[
                            _StrokeLabel(
                              text: 'Round ${snapshot.roundNumber}',
                              style: AppTypography.headline,
                              stroke: AppColors.electricBlue,
                              strokeWidth: 5,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const _StrokeLabel(
                              text: 'Winner!',
                              style: AppTypography.display,
                              stroke: AppColors.hotPink,
                              strokeWidth: 8,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.yellow, AppColors.hotPink],
                              ),
                            ),
                          ],
                        ],
                      ),
                      _WinnerPortrait(
                        player: winner,
                        name: winnerName,
                        role: champion ? 'champion' : 'winner',
                        color: playerColorFor(_rosterIndex(snapshot, winnerId)),
                      ),
                      if (champion)
                        _WinCondition(snapshot: snapshot)
                      else
                        _StandingsCard(
                          snapshot: snapshot,
                          ids: standings,
                          note: note,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WinnerPortrait extends StatelessWidget {
  const _WinnerPortrait({
    required this.player,
    required this.name,
    required this.role,
    required this.color,
  });

  final Player? player;
  final String name;
  final String role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final face = playerFaceFor(player?.avatarIndex ?? 0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustomPaint(
              size: Size(44, 96),
              painter: _LaurelPainter(flip: true),
            ),
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              label: '${face.label}, $name, $role',
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.hotPink.withValues(alpha: 0.65),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.45),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.yellow,
                      ),
                      child: SizedBox(
                        width: 104,
                        height: 104,
                        child: Icon(face.icon, size: 64, color: AppColors.ink),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const CustomPaint(
              size: Size(44, 96),
              painter: _LaurelPainter(flip: false),
            ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -12),
          child: _NameRibbon(name: name),
        ),
      ],
    );
  }
}

class _NameRibbon extends StatelessWidget {
  const _NameRibbon({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: CustomPaint(
          painter: const _RibbonPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: AppColors.cream),
            ),
          ),
        ),
      ),
    );
  }
}

class _StandingsCard extends StatelessWidget {
  const _StandingsCard({
    required this.snapshot,
    required this.ids,
    required this.note,
  });

  final MatchSnapshot snapshot;
  final List<String> ids;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          DecoratedBox(
            key: const Key('round-win-standings'),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  Text(
                    'Round wins',
                    style: AppTypography.label.copyWith(color: AppColors.cream),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      for (final id in ids)
                        Expanded(
                          child: _Standing(snapshot: snapshot, id: id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(note!, textAlign: TextAlign.center, style: AppTypography.body),
          ],
        ],
      ),
    );
  }
}

class _WinCondition extends StatelessWidget {
  const _WinCondition({required this.snapshot});

  final MatchSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        key: const Key('champion-condition'),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            winConditionSummary(snapshot.roster, snapshot.settings),
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: AppColors.cream),
          ),
        ),
      ),
    );
  }
}

class _Standing extends StatelessWidget {
  const _Standing({required this.snapshot, required this.id});

  final MatchSnapshot snapshot;
  final String id;

  @override
  Widget build(BuildContext context) {
    final player = _playerFor(snapshot, id);
    final face = playerFaceFor(player?.avatarIndex ?? 0);
    final color = playerColorFor(_rosterIndex(snapshot, id));
    final name = visibleName(snapshot.roster, id);
    final score = snapshot.scores[id] ?? 0;
    return Semantics(
      label: '$name, $score round wins',
      child: ExcludeSemantics(
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(face.icon, color: _iconOn(color), size: 28),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(color: AppColors.cream),
            ),
            Text(
              '$score',
              style: AppTypography.title.copyWith(color: AppColors.yellow),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrokeLabel extends StatelessWidget {
  const _StrokeLabel({
    required this.text,
    required this.style,
    required this.stroke,
    required this.strokeWidth,
    this.gradient,
  });

  final String text;
  final TextStyle style;
  final Color stroke;
  final double strokeWidth;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final fill = gradient == null
        ? Text(text, style: style.copyWith(color: AppColors.cream))
        : ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => gradient!.createShader(bounds),
            child: Text(text, style: style.copyWith(color: AppColors.cream)),
          );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            text,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth
                ..strokeJoin = StrokeJoin.round
                ..color = stroke,
            ),
          ),
          fill,
        ],
      ),
    );
  }
}

class _Confetti extends StatefulWidget {
  const _Confetti({required this.seed, required this.reducedMotion});

  final int seed;
  final bool reducedMotion;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Speck> _specks;

  @override
  void initState() {
    super.initState();
    _specks = _specksFor(widget.seed);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.reducedMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _Confetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion) {
      _controller.value = 1;
    } else if (oldWidget.reducedMotion) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              specks: _specks,
              progress: _controller.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _Speck {
  const _Speck({
    required this.x,
    required this.y,
    required this.size,
    required this.turn,
    required this.color,
    required this.delay,
    required this.wide,
  });

  final double x;
  final double y;
  final double size;
  final double turn;
  final Color color;
  final double delay;
  final bool wide;
}

List<_Speck> _specksFor(int seed) {
  final random = math.Random(seed);
  const colors = <Color>[
    AppColors.yellow,
    AppColors.hotPink,
    AppColors.cyan,
    AppColors.lime,
    AppColors.cream,
    AppColors.electricBlue,
  ];
  return [
    for (var index = 0; index < 26; index++)
      _Speck(
        x: 0.06 + random.nextDouble() * 0.88,
        y: 0.04 + random.nextDouble() * 0.4,
        size: 6 + random.nextDouble() * 8,
        turn: random.nextDouble() * math.pi,
        color: colors[random.nextInt(colors.length)],
        delay: random.nextDouble() * 0.3,
        wide: random.nextBool(),
      ),
  ];
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.specks, required this.progress});

  final List<_Speck> specks;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const hold = 0.68;
    final fade = progress <= hold
        ? 1.0
        : ((1 - progress) / (1 - hold)).clamp(0.0, 1.0);
    if (fade == 0) {
      return;
    }
    final motion = (progress / hold).clamp(0.0, 1.0);
    for (final speck in specks) {
      final span = (1 - speck.delay).clamp(0.01, 1.0);
      final raw = ((motion - speck.delay) / span).clamp(0.0, 1.0);
      final t = Curves.easeOut.transform(raw);
      canvas.save();
      canvas.translate(
        speck.x * size.width,
        _lerp(-28, speck.y * size.height, t),
      );
      canvas.rotate(speck.turn + (1 - t) * 1.4);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: speck.wide ? speck.size * 1.7 : speck.size * 0.65,
        height: speck.size,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = speck.color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.36);
    final radius = size.longestSide;
    const rays = 16;
    for (var index = 0; index < rays; index++) {
      final paint = Paint()
        ..color = (index.isEven ? AppColors.yellow : AppColors.hotPink)
            .withValues(alpha: 0.14);
      final start = index * 2 * math.pi / rays;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(
            Rect.fromCircle(center: center, radius: radius),
            start,
            math.pi / rays,
            false,
          )
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.62)
      ..lineTo(size.width * 0.2, size.height * 0.22)
      ..lineTo(size.width * 0.36, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.06)
      ..lineTo(size.width * 0.64, size.height * 0.5)
      ..lineTo(size.width * 0.8, size.height * 0.22)
      ..lineTo(size.width * 0.96, size.height * 0.62)
      ..lineTo(size.width * 0.88, size.height * 0.94)
      ..lineTo(size.width * 0.12, size.height * 0.94)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.yellow);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.hotPink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    final jewel = Paint()..color = AppColors.cyan;
    for (final x in [0.24, 0.5, 0.76]) {
      canvas.drawCircle(Offset(size.width * x, size.height * 0.74), 4, jewel);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LaurelPainter extends CustomPainter {
  const _LaurelPainter({required this.flip});

  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (flip) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final stem = Paint()
      ..color = AppColors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final leaf = Paint()..color = AppColors.yellow;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.96)
      ..quadraticBezierTo(
        size.width * 0.98,
        size.height * 0.55,
        size.width * 0.28,
        size.height * 0.04,
      );
    canvas.drawPath(path, stem);
    final metric = path.computeMetrics().first;
    for (var index = 0; index < 6; index++) {
      final tangent = metric.getTangentForOffset(
        metric.length * (index + 1) / 7,
      );
      if (tangent == null) {
        continue;
      }
      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(tangent.angle);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(7, 0), width: 12, height: 6),
        leaf,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LaurelPainter oldDelegate) {
    return oldDelegate.flip != flip;
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 2.0;
    final path = Path()
      ..moveTo(inset + 16, inset)
      ..lineTo(size.width - inset - 16, inset)
      ..lineTo(size.width - inset, size.height / 2)
      ..lineTo(size.width - inset - 16, size.height - inset)
      ..lineTo(inset + 16, size.height - inset)
      ..lineTo(inset, size.height / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.electricBlue);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Player? _playerFor(MatchSnapshot snapshot, String? id) {
  for (final player in snapshot.roster) {
    if (player.id == id) {
      return player;
    }
  }
  return null;
}

int _rosterIndex(MatchSnapshot snapshot, String? id) {
  final index = snapshot.roster.indexWhere((player) => player.id == id);
  return index < 0 ? 0 : index;
}

Color _iconOn(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? AppColors.cream
      : AppColors.ink;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
