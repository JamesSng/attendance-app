import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated pill that signals an event is currently running.
class LivePill extends StatefulWidget {
  const LivePill({super.key, this.label = 'LIVE'});

  final String label;

  @override
  State<LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: scheme.onPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Coloured pill used for role / status labels.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = StatusPillTone.neutral,
  });

  final String label;
  final IconData? icon;
  final StatusPillTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (tone) {
      StatusPillTone.neutral => (
          scheme.surfaceContainerHighest.withValues(alpha: 0.8),
          scheme.onSurfaceVariant
        ),
      StatusPillTone.accent => (
          scheme.primary.withValues(alpha: 0.14),
          scheme.primary,
        ),
      StatusPillTone.warning => (
          scheme.tertiary.withValues(alpha: 0.16),
          scheme.tertiary,
        ),
      StatusPillTone.danger => (
          scheme.error.withValues(alpha: 0.14),
          scheme.error,
        ),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon == null ? 10 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                ),
          ),
        ],
      ),
    );
  }
}

enum StatusPillTone { neutral, accent, warning, danger }

/// Circular "X / Y" progress indicator used on the live event hero card.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.label,
    this.subLabel,
    this.size = 64,
    this.strokeWidth = 6,
  });

  final double value; // 0..1
  final String label;
  final String? subLabel;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CustomPaint(
              painter: _RingPainter(
                value: value.clamp(0.0, 1.0),
                track: scheme.surfaceContainerHighest,
                fill: scheme.primary,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium,
              ),
              if (subLabel != null)
                Text(
                  subLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.track,
    required this.fill,
    required this.strokeWidth,
  });

  final double value;
  final Color track;
  final Color fill;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = track
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = fill
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centre, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value ||
      old.track != track ||
      old.fill != fill ||
      old.strokeWidth != strokeWidth;
}

/// Square date-block used as the leading of an event row (SUN \n 12).
class EventDateBlock extends StatelessWidget {
  const EventDateBlock({
    super.key,
    required this.date,
    this.size = 44,
    this.highlight = false,
  });

  final DateTime date;
  final double size;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = highlight
        ? scheme.primary.withValues(alpha: 0.14)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.7);
    final dayColour = highlight ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _shortDay(date),
            style: theme.textTheme.labelSmall?.copyWith(
              color: dayColour,
            ),
          ),
          Text(
            '${date.day}',
            style: theme.textTheme.titleMedium?.copyWith(
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDay(DateTime d) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[d.weekday - 1];
  }
}
