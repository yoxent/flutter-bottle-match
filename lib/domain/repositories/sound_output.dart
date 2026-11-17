/// Playback port. Gains are linear, from 0 to 1.
abstract interface class SoundOutput {
  Future<void> startLoop(String asset, double volume);

  Future<void> setLoopVolume(double volume);

  Future<void> pauseLoop();

  Future<void> resumeLoop();

  Future<void> playEffect(String asset, double volume);

  Future<void> dispose();
}
