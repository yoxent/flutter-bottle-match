import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../design_system/components/buttons/game_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import 'player_faces.dart';

/// Opens the icon panel. A tap outside returns null and keeps the current icon.
Future<int?> showPlayerIconPicker(
  BuildContext context, {
  required int? selected,
  required Set<int> used,
  required Color color,
}) {
  return showFDialog<int>(
    context: context,
    builder: (context, style, animation) {
      return _PlayerIconPanel(selected: selected, used: used, color: color);
    },
  );
}

class _PlayerIconPanel extends StatefulWidget {
  const _PlayerIconPanel({
    required this.selected,
    required this.used,
    required this.color,
  });

  final int? selected;
  final Set<int> used;
  final Color color;

  @override
  State<_PlayerIconPanel> createState() => _PlayerIconPanelState();
}

class _PlayerIconPanelState extends State<_PlayerIconPanel> {
  late int? _selected = widget.selected;
  late int _category = playerIconCategoryIndexFor(widget.selected);
  final ScrollController _icons = ScrollController();

  @override
  void dispose() {
    _icons.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final category = playerIconCategories[_category];
    final offset = _categoryOffset(_category);
    final body = media.size.height - media.padding.vertical;
    final dialogWidth = _dialogWidth(media.size.width);
    final inner = dialogWidth - AppSpacing.lg * 2;
    final widthCell =
        (inner - _scrollbarGutter - _gap * (_columns - 1)) / _columns;
    final cell = _cellThatFits(widthCell, body);
    final panelHeight = _panelHeight(cell);
    final topSpace = body > panelHeight ? (body - panelHeight) / 2 : 0.0;
    final gridWidth = _columns * cell + (_columns - 1) * _gap;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
          ),
        ),
        Positioned(
          top: media.padding.top + topSpace,
          left: 40,
          right: 40,
          height: panelHeight,
          child: FDialog(
            style: .delta(insetPadding: .value(EdgeInsets.zero)),
            semanticsLabel: 'Choose an icon',
            builder: (context, style) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: gridWidth + _scrollbarGutter,
                    child: _iconColumn(category, offset, cell, gridWidth),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCategory(int index) {
    if (_icons.hasClients) _icons.jumpTo(0);
    setState(() => _category = index);
  }

  Widget _iconColumn(
    PlayerIconCategory category,
    int offset,
    double cell,
    double gridWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryStrip(
          cell: cell,
          width: gridWidth,
          category: _category,
          color: widget.color,
          onSelect: _showCategory,
        ),
        const SizedBox(height: _dividerGap),
        SizedBox(
          width: gridWidth,
          child: DecoratedBox(
            key: const Key('icon-category-bar'),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.cream.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
            ),
            child: const SizedBox(height: 1),
          ),
        ),
        const SizedBox(height: _dividerGap),
        SizedBox(
          width: gridWidth + _scrollbarGutter,
          height: _gridHeight(cell),
          child: Scrollbar(
            controller: _icons,
            thumbVisibility: true,
            child: GridView.builder(
              key: Key('icon-grid-$_category'),
              controller: _icons,
              primary: false,
              padding: const EdgeInsets.only(right: _scrollbarGutter),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columns,
                crossAxisSpacing: _gap,
                mainAxisSpacing: _gap,
                mainAxisExtent: cell,
              ),
              itemCount: category.faces.length,
              itemBuilder: (context, localIndex) {
                final index = offset + localIndex;
                final face = category.faces[localIndex];
                final taken = widget.used.contains(index);
                final selected = _selected == index;
                return Semantics(
                  button: true,
                  enabled: !taken,
                  selected: selected,
                  label: taken ? '${face.label}, in use' : face.label,
                  excludeSemantics: true,
                  child: Material(
                    color: selected ? AppColors.yellow : AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: InkWell(
                      key: Key('icon-choice-$index'),
                      onTap: taken
                          ? null
                          : () => setState(() => _selected = index),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: CustomPaint(
                        key: taken ? Key('icon-unavailable-$index') : null,
                        foregroundPainter: taken
                            ? const _UnavailableSlashPainter()
                            : null,
                        child: Center(
                          child: Icon(
                            face.icon,
                            color: taken
                                ? AppColors.creamMuted
                                : selected
                                ? AppColors.ink
                                : widget.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: gridWidth,
          child: GameButton(
            key: const Key('apply-player-icon'),
            label: 'Apply',
            backgroundColor: AppColors.hotPink,
            onPressed: _selected == null
                ? null
                : () => Navigator.of(context).pop(_selected),
          ),
        ),
      ],
    );
  }
}

const _applyButtonHeight = 56.0;

const _columns = 5;

const _visibleIconRows = 3;

const _gap = AppSpacing.xs;

const _dividerGap = AppSpacing.sm;

const _scrollbarGutter = AppSpacing.sm;

const _categoryHintSize = 16.0;

const _categoryHintGap = AppSpacing.xs;

double _gridHeight(double cell) =>
    _visibleIconRows * cell + (_visibleIconRows - 1) * _gap;

double _panelHeight(double cell) =>
    AppSpacing.lg * 2 +
    AppTouch.minimum +
    _dividerGap +
    1 +
    _dividerGap +
    _gridHeight(cell) +
    AppSpacing.md +
    _applyButtonHeight;

double _dialogWidth(double screenWidth) {
  final stretched = screenWidth - 80;
  if (stretched < 280) return stretched;
  if (stretched > 560) return 560;
  return stretched;
}

double _cellThatFits(double widthCell, double bodyHeight) {
  if (widthCell < 1) return 1;
  if (_panelHeight(widthCell) <= bodyHeight) return widthCell;
  final available = bodyHeight - _panelHeight(0);
  if (available <= 0) return 1;
  final fitted = available / _visibleIconRows;
  return fitted < widthCell ? fitted : widthCell;
}

int _categoryOffset(int category) {
  var offset = 0;
  for (var index = 0; index < category; index++) {
    offset += playerIconCategories[index].faces.length;
  }
  return offset;
}

class _CategoryStrip extends StatefulWidget {
  const _CategoryStrip({
    required this.cell,
    required this.width,
    required this.category,
    required this.color,
    required this.onSelect,
  });

  final double cell;
  final double width;
  final int category;
  final Color color;
  final ValueChanged<int> onSelect;

  @override
  State<_CategoryStrip> createState() => _CategoryStripState();
}

class _CategoryStripState extends State<_CategoryStrip> {
  final ScrollController _scroll = ScrollController();
  bool _moreLeft = false;
  bool _moreRight = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void didUpdateWidget(covariant _CategoryStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cell != widget.cell || oldWidget.width != widget.width) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    final moreLeft = position.pixels > 0.5;
    final moreRight = position.maxScrollExtent - position.pixels > 0.5;
    if (moreLeft == _moreLeft && moreRight == _moreRight) return;
    setState(() {
      _moreLeft = moreLeft;
      _moreRight = moreRight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTouch.minimum,
      width: widget.width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView.separated(
            key: const Key('icon-category-scroll'),
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            primary: false,
            padding: EdgeInsets.zero,
            itemCount: playerIconCategories.length,
            separatorBuilder: (context, index) => const SizedBox(width: _gap),
            itemBuilder: (context, index) {
              final item = playerIconCategories[index];
              final active = index == widget.category;
              return Semantics(
                button: true,
                selected: active,
                label: item.label,
                excludeSemantics: true,
                child: Material(
                  color: active ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: InkWell(
                    key: Key('icon-category-${item.label}'),
                    onTap: () => widget.onSelect(index),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: SizedBox(
                      width: widget.cell,
                      height: AppTouch.minimum,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            color: active ? widget.color : AppColors.creamMuted,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Container(
                            width: 16,
                            height: 3,
                            decoration: BoxDecoration(
                              color: active ? widget.color : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_moreLeft)
            const Positioned(
              left: -(_categoryHintGap + _categoryHintSize),
              top: 0,
              bottom: 0,
              width: _categoryHintSize,
              child: _CategoryScrollHint(
                key: Key('icon-category-more-left'),
                icon: FLucideIcons.chevronLeft,
              ),
            ),
          if (_moreRight)
            const Positioned(
              right: -(_categoryHintGap + _categoryHintSize),
              top: 0,
              bottom: 0,
              width: _categoryHintSize,
              child: _CategoryScrollHint(
                key: Key('icon-category-more-right'),
                icon: FLucideIcons.chevronRight,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryScrollHint extends StatelessWidget {
  const _CategoryScrollHint({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Center(
          child: Icon(
            icon,
            size: _categoryHintSize,
            color: AppColors.creamMuted,
          ),
        ),
      ),
    );
  }
}

class _UnavailableSlashPainter extends CustomPainter {
  const _UnavailableSlashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.shortestSide * 0.16;
    final slash = Paint()
      ..color = AppColors.danger
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      slash,
    );
  }

  @override
  bool shouldRepaint(covariant _UnavailableSlashPainter oldDelegate) => false;
}
