import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/audio/button_press.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

class SegmentedTab {
  const SegmentedTab({required this.label, required this.tabKey});

  final String label;
  final Key tabKey;
}

/// One group visible at a time. The selected segment uses the yellow token.
class SegmentedTabs extends ConsumerWidget {
  const SegmentedTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<SegmentedTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: Row(
          children: [
            for (var index = 0; index < tabs.length; index++)
              Expanded(
                child: buttonTap(
                  ref,
                  onPressed: () => onSelected(index),
                  child: _Segment(
                    tab: tabs[index],
                    selected: index == selectedIndex,
                    onPressed: () => onSelected(index),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.tab,
    required this.selected,
    required this.onPressed,
  });

  final SegmentedTab tab;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.ink : AppColors.cream;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: Material(
        key: tab.tabKey,
        color: selected ? AppColors.yellow : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          enableFeedback: false,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTouch.minimum),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Center(
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
