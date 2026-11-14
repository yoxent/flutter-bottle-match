import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../tokens/colors.dart';
import '../tokens/gradients.dart';
import '../tokens/spacing.dart';
import '../layout/game_viewport.dart';

class GamePage extends StatelessWidget {
  const GamePage({
    required this.title,
    required this.body,
    this.showBack = false,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget body;
  final bool showBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.background),
          child: GameViewport(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (showBack)
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => context.pop(),
                        icon: const Icon(FLucideIcons.arrowLeft),
                        color: AppColors.cream,
                        constraints: const BoxConstraints(
                          minWidth: AppTouch.minimum,
                          minHeight: AppTouch.minimum,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    ...actions,
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
