import 'package:flutter_bottle_match/domain/repositories/sound_output.dart';

class SilentSoundOutput implements SoundOutput {
  const SilentSoundOutput();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pauseLoop() async {}

  @override
  Future<void> playEffect(String asset, double volume) async {}

  @override
  Future<void> resumeLoop() async {}

  @override
  Future<void> setLoopVolume(double volume) async {}

  @override
  Future<void> startLoop(String asset, double volume) async {}
}
