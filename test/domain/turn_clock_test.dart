import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/domain/models/turn_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2026, 11, 14, 6);

  test('the default timer is off and stays at zero', () {
    const clock = TurnClock();
    expect(clock.duration, TurnTimerDuration.off);
    expect(clock.remainingAt(start), Duration.zero);
    expect(clock.startAt(start).isRunning, isFalse);
  });

  test('remaining time is calculated from the stored start', () {
    final running = const TurnClock(
      duration: TurnTimerDuration.seconds30,
    ).startAt(start);
    final later = start.add(const Duration(seconds: 10));

    expect(running.remainingAt(later), const Duration(seconds: 20));

    final paused = running.pauseAt(later);
    expect(paused.isRunning, isFalse);
    expect(
      paused.remainingAt(later.add(const Duration(minutes: 5))),
      const Duration(seconds: 20),
    );

    final resumed = paused.resumeAt(later.add(const Duration(minutes: 5)));
    expect(
      resumed.remainingAt(later.add(const Duration(minutes: 5, seconds: 5))),
      const Duration(seconds: 15),
    );
  });

  test('an expired countdown clamps at zero', () {
    final running = const TurnClock(
      duration: TurnTimerDuration.seconds30,
    ).startAt(start);

    expect(
      running.remainingAt(start.add(const Duration(seconds: 45))),
      Duration.zero,
    );
  });
}
