import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';

/// On/off setting. Off is red, on is yellow, and the handle stays inset.
class GameSwitch extends StatelessWidget {
  const GameSwitch({
    required this.value,
    required this.onChange,
    this.semanticsLabel,
    this.label,
    this.description,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChange;
  final String? semanticsLabel;
  final Widget? label;
  final Widget? description;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Semantics(
        toggled: value,
        enabled: onChange != null,
        label: label == null ? semanticsLabel : null,
        child: GestureDetector(
          onTap: onChange == null ? null : () => onChange!(!value),
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTouch.minimum),
            child: Row(
              children: [
                _Track(on: value),
                if (label != null || description != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (label != null)
                          DefaultTextStyle.merge(
                            style: text.titleMedium,
                            child: label!,
                          ),
                        if (description != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          DefaultTextStyle.merge(
                            style: text.bodyLarge?.copyWith(
                              color: AppColors.creamMuted,
                            ),
                            child: description!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.on});

  final bool on;

  static const _width = 56.0;
  static const _height = 32.0;

  @override
  Widget build(BuildContext context) {
    final handle = _height - AppSpacing.xxs * 2;
    return SizedBox(
      width: _width,
      height: _height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: on ? AppColors.yellow : AppColors.danger,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: handle),
            ),
          ),
        ),
      ),
    );
  }
}
