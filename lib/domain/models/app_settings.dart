/// Local presentation preferences. These are not match rules.
class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
    this.masterVolume = defaultVolume,
    this.bgmVolume = defaultVolume,
    this.sfxVolume = defaultVolume,
  });

  /// The GDD requires separate controls and does not specify defaults.
  /// Sound and haptics start on; reduced motion starts off.
  /// Each volume starts at 70% and moves in steps of 5.
  static const volumeStep = 5;
  static const defaultVolume = 70;

  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool reducedMotion;

  /// Percent from 0 to 100, in steps of [volumeStep].
  final int masterVolume;
  final int bgmVolume;
  final int sfxVolume;

  static int snapVolume(int value) {
    final clamped = value.clamp(0, 100);
    return (clamped / volumeStep).round() * volumeStep;
  }

  AppSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? reducedMotion,
    int? masterVolume,
    int? bgmVolume,
    int? sfxVolume,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      masterVolume: masterVolume ?? this.masterVolume,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        soundEnabled == other.soundEnabled &&
        hapticsEnabled == other.hapticsEnabled &&
        reducedMotion == other.reducedMotion &&
        masterVolume == other.masterVolume &&
        bgmVolume == other.bgmVolume &&
        sfxVolume == other.sfxVolume;
  }

  @override
  int get hashCode => Object.hash(
    soundEnabled,
    hapticsEnabled,
    reducedMotion,
    masterVolume,
    bgmVolume,
    sfxVolume,
  );
}
