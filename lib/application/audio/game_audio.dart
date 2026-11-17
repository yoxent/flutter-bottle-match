import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_settings.dart';
import '../controllers/settings_controller.dart';
import '../providers.dart';

const loopAsset = 'sounds/bgm/thinking_and_tinkering.wav';
const buttonClickAsset = 'sounds/sfx/button_click.wav';
const bottleMoveAsset = 'sounds/sfx/bottle_move.wav';

double musicGain(AppSettings settings) {
  if (!settings.soundEnabled) {
    return 0;
  }
  return settings.masterVolume * settings.bgmVolume / 10000;
}

double effectGain(AppSettings settings) {
  if (!settings.soundEnabled) {
    return 0;
  }
  return settings.masterVolume * settings.sfxVolume / 10000;
}

final gameAudioProvider = NotifierProvider<GameAudioController, bool>(
  GameAudioController.new,
);

class GameAudioController extends Notifier<bool> {
  var _foreground = true;
  var _started = false;
  var _paused = true;
  var _blocked = false;
  Future<void> _tail = Future<void>.value();
  Future<void> _effects = Future<void>.value();

  /// Completes after the playback already queued on this controller.
  Future<void> get idle async {
    await Future.wait([_tail, _effects]);
  }

  @override
  bool build() {
    final binding = WidgetsBinding.instance;
    final observer = _AppLifecycle((state) {
      unawaited(handleLifecycle(state));
    });
    binding.addObserver(observer);
    ref.onDispose(() => binding.removeObserver(observer));
    ref.listen(settingsControllerProvider, (previous, next) {
      unawaited(_run(_applyLatest));
    });
    unawaited(_run(_applyLatest));
    return true;
  }

  Future<void> handleLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _foreground = false;
    }
    return _run(_applyLatest);
  }

  Future<void> playButton() {
    return _runEffect(() => _effect(buttonClickAsset));
  }

  Future<void> playBottleMove() {
    return _runEffect(() => _effect(bottleMoveAsset));
  }

  Future<void> _run(Future<void> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.catchError((Object _) {});
    return result;
  }

  Future<void> _runEffect(Future<void> Function() action) {
    final result = _effects.then((_) => action());
    _effects = result.catchError((Object _) {});
    return result;
  }

  Future<void> _applyLatest() async {
    if (!ref.mounted) {
      return;
    }
    final settings = ref.read(settingsControllerProvider).value;
    if (settings == null) {
      return;
    }
    final output = ref.read(soundOutputProvider);
    final volume = musicGain(settings);
    final shouldPlay = _foreground && volume > 0;
    if (!shouldPlay) {
      if (_started && !_paused) {
        await output.pauseLoop();
        _paused = true;
      }
      return;
    }
    if (!_started) {
      try {
        await output.startLoop(loopAsset, volume);
        _started = true;
        _paused = false;
        _blocked = false;
      } catch (_) {
        _blocked = true;
      }
      return;
    }
    await output.setLoopVolume(volume);
    if (_paused) {
      try {
        await output.resumeLoop();
        _paused = false;
        _blocked = false;
      } catch (_) {
        _blocked = true;
      }
    }
  }

  Future<void> _effect(String asset) async {
    if (_blocked) {
      await _applyLatest();
    }
    if (!ref.mounted) {
      return;
    }
    final settings = ref.read(settingsControllerProvider).value;
    if (settings == null) {
      return;
    }
    final volume = effectGain(settings);
    if (volume == 0) {
      return;
    }
    try {
      await ref.read(soundOutputProvider).playEffect(asset, volume);
    } catch (_) {}
  }
}

class _AppLifecycle extends WidgetsBindingObserver {
  _AppLifecycle(this._onChange);

  final void Function(AppLifecycleState state) _onChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _onChange(state);
  }
}
