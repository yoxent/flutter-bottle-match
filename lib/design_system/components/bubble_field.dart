import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../tokens/colors.dart';

/// One drifting field for the whole app. It stays mounted across navigation.
class BubbleField extends StatefulWidget {
  const BubbleField({required this.reducedMotion, super.key});

  final bool reducedMotion;

  @override
  State<BubbleField> createState() => _BubbleFieldState();
}

class _Bubble {
  const _Bubble({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.diameter,
    required this.color,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double diameter;
  final Color color;
}

class _BubbleFieldState extends State<BubbleField>
    with SingleTickerProviderStateMixin {
  late final List<_Bubble> _bubbles = _bubblesFor(math.Random(7));
  Ticker? _ticker;
  var _elapsed = 0.0;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant BubbleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion) {
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _syncTicker() {
    if (widget.reducedMotion || _widgetTests) {
      _ticker?.stop();
      return;
    }
    _ticker ??= createTicker((elapsed) {
      setState(() => _elapsed = elapsed.inMicroseconds / 1000000);
    });
    if (!_ticker!.isActive) {
      _ticker!.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: AppColors.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            if (width <= 0 || height <= 0) {
              return const SizedBox.expand();
            }
            return Stack(
              children: [
                for (final bubble in _bubbles)
                  Positioned(
                    left:
                        _place(
                          bubble.x,
                          bubble.vx,
                          _elapsed,
                          1 + bubble.diameter,
                        ) *
                        width,
                    top:
                        _place(
                          bubble.y,
                          bubble.vy,
                          _elapsed,
                          1 + bubble.diameter * width / height,
                        ) *
                        height,
                    child: _Blob(
                      diameter: bubble.diameter * width,
                      color: bubble.color,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A repeating ticker never settles, so widget tests keep the circles still.
bool get _widgetTests {
  return WidgetsBinding.instance.runtimeType.toString().contains(
    'TestWidgetsFlutterBinding',
  );
}

List<_Bubble> _bubblesFor(math.Random random) {
  const specs = <(double, double, bool)>[
    (0.62, 0.28, false),
    (0.70, 0.34, true),
    (0.28, 0.16, false),
    (0.18, 0.24, false),
    (0.14, 0.30, true),
    (0.10, 0.20, false),
  ];
  return [
    for (final spec in specs)
      _Bubble(
        x: random.nextDouble(),
        y: random.nextDouble(),
        vx: _drift(random),
        vy: _drift(random),
        diameter: spec.$1,
        color: (spec.$3 ? AppColors.stageBlobDeep : AppColors.stageBlob)
            .withValues(alpha: spec.$2),
      ),
  ];
}

double _drift(math.Random random) {
  final speed = 0.02 + random.nextDouble() * 0.05;
  return random.nextBool() ? speed : -speed;
}

double _place(double origin, double velocity, double time, double span) {
  final value = (origin + velocity * time) % span;
  final wrapped = value < 0 ? value + span : value;
  return wrapped - (span - 1);
}

class _Blob extends StatelessWidget {
  const _Blob({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
