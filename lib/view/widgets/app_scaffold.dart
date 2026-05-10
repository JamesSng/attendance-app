import 'package:flutter/material.dart';

import '../../util/responsive.dart';

/// Shared scaffold used by every secondary screen.
///
/// Replaces the previous pattern of every screen building its own AppBar with
/// a leading `TextButton(Icon(arrow_back))` and `inversePrimary` background.
///
/// Also constrains body width on wide screens so reading lines and form
/// controls don't stretch across an entire desktop window.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showBack = true,
    this.padded = true,
    this.maxContentWidth = 720,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBack;
  final bool padded;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    // Secondary screens use a one-step-smaller title (M3 `headlineSmall`,
    // 24sp) than the home AppBar (`headlineMedium`, 28sp), keeping the
    // hierarchy on-spec without inventing custom sizes.
    final TextStyle? secondaryTitleStyle = theme.textTheme.headlineSmall
        ?.copyWith(color: theme.colorScheme.onSurface);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: (showBack && canPop)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : null,
        titleTextStyle: secondaryTitleStyle,
        title: subtitle == null
            ? Text(title)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: secondaryTitleStyle),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: ContentBounds(
          maxWidth: maxContentWidth,
          child: padded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: body,
                )
              : body,
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
