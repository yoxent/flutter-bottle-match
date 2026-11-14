import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../layout/game_viewport.dart';
import 'action_footer.dart';

class GamePage extends StatelessWidget {
  const GamePage({
    required this.body,
    this.title,
    this.showBack = false,
    this.onBack,
    this.actions = const [],
    this.footer,
    super.key,
  });

  final String? title;
  final Widget body;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.background),
          child: GameViewport(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBack || title != null || actions.isNotEmpty)
                  Row(
                    children: [
                      if (showBack)
                        IconButton(
                          tooltip: 'Back',
                          onPressed:
                              onBack ?? () => Navigator.maybePop(context),
                          icon: const Icon(FLucideIcons.arrowLeft),
                          color: AppColors.cream,
                          constraints: const BoxConstraints(
                            minWidth: AppTouch.minimum,
                            minHeight: AppTouch.minimum,
                          ),
                        ),
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        )
                      else
                        const Spacer(),
                      ...actions,
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: body),
                if (footer != null) ActionFooter(child: footer!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
