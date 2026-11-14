import 'configuration.dart';
import '../serialization/json_object.dart';

/// Timer state that can be saved and resumed without a background countdown.
///
/// Remaining time is stored directly. While the clock is running, [runningSince]
/// marks when that remaining value started counting. Callers pass the current
/// time in; this type never reads a global clock.
class TurnClock {
  const TurnClock({
    this.duration = TurnTimerDuration.off,
    this.remaining = Duration.zero,
    this.runningSince,
  });

  final TurnTimerDuration duration;
  final Duration remaining;
  final DateTime? runningSince;

  bool get isRunning => runningSince != null;

  Duration remainingAt(DateTime now) {
    if (duration == TurnTimerDuration.off) {
      return Duration.zero;
    }
    final started = runningSince;
    if (started == null) {
      return remaining;
    }
    final left = remaining - now.difference(started);
    if (left.isNegative) {
      return Duration.zero;
    }
    return left;
  }

  /// Freezes the clock at [now]. A second pause does not move the remainder.
  TurnClock pauseAt(DateTime now) {
    if (!isRunning) {
      return this;
    }
    return TurnClock(
      duration: duration,
      remaining: remainingAt(now),
      runningSince: null,
    );
  }

  /// Continues from the frozen remainder. Does nothing when the timer is off
  /// or already running.
  TurnClock resumeAt(DateTime now) {
    if (duration == TurnTimerDuration.off || isRunning) {
      return this;
    }
    return TurnClock(
      duration: duration,
      remaining: remaining,
      runningSince: now,
    );
  }

  /// Starts a fresh countdown from the configured limit.
  TurnClock startAt(DateTime now) {
    final limit = duration.limit;
    if (limit == null) {
      return const TurnClock();
    }
    return TurnClock(duration: duration, remaining: limit, runningSince: now);
  }

  Map<String, Object?> toJson() => {
    'duration': duration.name,
    'remainingMs': remaining.inMilliseconds,
    'runningSince': runningSince?.toUtc().toIso8601String(),
  };

  factory TurnClock.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    final started = object.optionalString('runningSince');
    return TurnClock(
      duration: enumByName(
        TurnTimerDuration.values,
        object.string('duration'),
        'duration',
      ),
      remaining: Duration(milliseconds: object.integer('remainingMs')),
      runningSince: started == null ? null : DateTime.parse(started).toUtc(),
    );
  }
}
