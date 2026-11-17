import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../domain/repositories/sound_output.dart';

class AudioplayersSoundOutput implements SoundOutput {
  AudioplayersSoundOutput._(this._loop) {
    _loopState = _loop.onPlayerStateChanged.listen(_onLoopState);
  }

  /// Effects must not take audio focus, or the platform pauses the loop.
  static final AudioContext _mix = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  final AudioPlayer _loop;
  final Map<String, AudioPlayer> _effects = {};
  late final StreamSubscription<PlayerState> _loopState;
  String? _loopAsset;
  var _loopVolume = 1.0;
  var _loopShouldPlay = false;
  var _restoringLoop = false;

  final Map<String, Future<AudioPlayer>> _preparing = {};

  static Future<AudioplayersSoundOutput> open({
    List<String> effects = const [],
  }) async {
    await AudioPlayer.global.setAudioContext(_mix);
    final loop = AudioPlayer();
    await loop.setAudioContext(_mix);
    await loop.setReleaseMode(ReleaseMode.loop);
    final output = AudioplayersSoundOutput._(loop);
    await Future.wait(effects.map(output._effectPlayer));
    return output;
  }

  @override
  Future<void> startLoop(String asset, double volume) async {
    _loopAsset = asset;
    _loopVolume = volume;
    _loopShouldPlay = true;
    await _loop.play(_source(asset), volume: volume);
  }

  @override
  Future<void> setLoopVolume(double volume) {
    _loopVolume = volume;
    return _loop.setVolume(volume);
  }

  @override
  Future<void> pauseLoop() async {
    _loopShouldPlay = false;
    await _loop.pause();
  }

  @override
  Future<void> resumeLoop() async {
    _loopShouldPlay = true;
    await _loop.resume();
  }

  @override
  Future<void> playEffect(String asset, double volume) async {
    final player = await _effectPlayer(asset);
    await player.setVolume(volume);
    if (player.state != PlayerState.stopped) {
      await player.stop();
    }
    await player.resume();
    unawaited(_restoreLoop());
  }

  @override
  Future<void> dispose() async {
    _loopShouldPlay = false;
    await _loopState.cancel();
    await _loop.dispose();
    for (final player in _effects.values) {
      await player.dispose();
    }
  }

  Future<AudioPlayer> _effectPlayer(String asset) {
    return _preparing.putIfAbsent(asset, () async {
      final player = AudioPlayer();
      await player.setAudioContext(_mix);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(_source(asset));
      _effects[asset] = player;
      return player;
    });
  }

  void _onLoopState(PlayerState state) {
    if (state == PlayerState.paused || state == PlayerState.stopped) {
      unawaited(_restoreLoop());
    }
  }

  Future<void> _restoreLoop() async {
    if (!_loopShouldPlay || _restoringLoop) {
      return;
    }
    final state = _loop.state;
    if (state != PlayerState.paused && state != PlayerState.stopped) {
      return;
    }
    _restoringLoop = true;
    try {
      if (state == PlayerState.paused) {
        await _loop.resume();
        return;
      }
      final asset = _loopAsset;
      if (asset == null) {
        return;
      }
      await _loop.play(_source(asset), volume: _loopVolume);
    } catch (_) {
    } finally {
      _restoringLoop = false;
    }
  }

  AssetSource _source(String asset) {
    return AssetSource(asset, mimeType: 'audio/wav');
  }
}
