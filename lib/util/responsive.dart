import 'package:flutter/material.dart';

/// Material 3 window-size-class breakpoints (in logical pixels).
///
/// Aligned with the official guidance:
///   compact  : phones (portrait) — width < 600
///   medium   : foldables / small tablets — 600..839
///   expanded : tablets / small windows — 840..1199
///   large    : desktop / large windows — >= 1200
class Breakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
}

enum WindowSizeClass { compact, medium, expanded, large }

extension WindowSizeClassX on WindowSizeClass {
  bool get isCompact => this == WindowSizeClass.compact;

  /// True for medium / expanded / large — i.e. anywhere we'd prefer a side
  /// rail over a bottom navigation bar.
  bool get isWide => this != WindowSizeClass.compact;
}

WindowSizeClass windowSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < Breakpoints.compact) return WindowSizeClass.compact;
  if (width < Breakpoints.medium) return WindowSizeClass.medium;
  if (width < Breakpoints.expanded) return WindowSizeClass.expanded;
  return WindowSizeClass.large;
}

/// Centred max-width container — keeps line lengths readable on tablets and
/// desktop without forcing pages to be left-anchored.
///
/// Defaults to `720` which fits the M3 "medium content" guidance for primary
/// reading surfaces.
class ContentBounds extends StatelessWidget {
  const ContentBounds({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
