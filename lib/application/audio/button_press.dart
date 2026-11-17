import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_audio.dart';

/// Plays the click when the pointer goes down. [child] still runs [onPressed]
/// on release. A null [onPressed] stays silent.
Widget buttonTap(
  WidgetRef ref, {
  required VoidCallback? onPressed,
  required Widget child,
}) {
  return Listener(
    behavior: HitTestBehavior.deferToChild,
    onPointerDown: onPressed == null
        ? null
        : (event) {
            final mouse =
                event.kind == PointerDeviceKind.mouse &&
                (event.buttons & kPrimaryButton) == 0;
            if (mouse) {
              return;
            }
            unawaited(ref.read(gameAudioProvider.notifier).playButton());
          },
    child: child,
  );
}
