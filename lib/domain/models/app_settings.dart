/// Local presentation preferences. These are not match rules.
class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
  });

  /// The GDD requires separate controls and does not specify defaults.
  /// Sound and haptics start on; reduced motion starts off.
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool reducedMotion;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? reducedMotion,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
    );
  }
}
