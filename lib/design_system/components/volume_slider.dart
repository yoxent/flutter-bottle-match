import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../application/audio/button_press.dart';
import '../../domain/models/app_settings.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// A labeled percent slider with a drag handle and step buttons.
class VolumeSlider extends ConsumerWidget {
  const VolumeSlider({
    required this.id,
    required this.label,
    required this.percent,
    required this.onChanged,
    super.key,
  });

  final String id;
  final String label;
  final int percent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepped = AppSettings.snapVolume(percent);
    final text = Theme.of(context).textTheme.titleMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text,
              ),
            ),
            Text('$stepped%', style: text),
          ],
        ),
        Row(
          children: [
            buttonTap(
              ref,
              onPressed: stepped <= 0
                  ? null
                  : () => _step(stepped - AppSettings.volumeStep),
              child: _StepButton(
                buttonKey: Key('$id-volume-decrease'),
                tooltip: 'Decrease $label volume',
                icon: FLucideIcons.minus,
                onPressed: stepped <= 0
                    ? null
                    : () => _step(stepped - AppSettings.volumeStep),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.yellow,
                  inactiveTrackColor: AppColors.creamMuted,
                  thumbColor: AppColors.ink,
                  overlayColor: AppColors.yellow.withValues(alpha: 0.24),
                  trackHeight: 8,
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                ),
                child: Slider(
                  key: Key('$id-volume-slider'),
                  value: stepped.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100 ~/ AppSettings.volumeStep,
                  semanticFormatterCallback: (value) => '${value.round()}%',
                  onChanged: (value) =>
                      onChanged(AppSettings.snapVolume(value.round())),
                ),
              ),
            ),
            buttonTap(
              ref,
              onPressed: stepped >= 100
                  ? null
                  : () => _step(stepped + AppSettings.volumeStep),
              child: _StepButton(
                buttonKey: Key('$id-volume-increase'),
                tooltip: 'Increase $label volume',
                icon: FLucideIcons.plus,
                onPressed: stepped >= 100
                    ? null
                    : () => _step(stepped + AppSettings.volumeStep),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _step(int next) {
    onChanged(AppSettings.snapVolume(next));
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.cream,
      disabledColor: AppColors.creamMuted,
      constraints: const BoxConstraints(
        minWidth: AppTouch.minimum,
        minHeight: AppTouch.minimum,
      ),
    );
  }
}
