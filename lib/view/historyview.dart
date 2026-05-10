import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/event.dart';
import 'attendanceview.dart';
import 'eventhistoryview.dart';
import 'tickethistoryview.dart';
import 'widgets/app_list_tile.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _loading = true;
  List<_TrendPoint> _trend = const [];

  @override
  void initState() {
    super.initState();
    _loadTrend();
  }

  Future<void> _loadTrend() async {
    final now = DateTime.now();
    final eventsRes = await _db
        .collection('events')
        .where('endTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('endTime', descending: true)
        .limit(12)
        .get();

    final futures = eventsRes.docs.reversed.map((doc) async {
      final start = (doc.get('startTime') as Timestamp).toDate();
      final agg = await doc.reference
          .collection('attendees')
          .where('checked', isEqualTo: true)
          .count()
          .get();
      return _TrendPoint(start: start, attendees: agg.count ?? 0);
    });
    final points = await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      _trend = points;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _TrendCard(trend: _trend, loading: _loading),
        const AppSectionHeader('Browse'),
        AppListTile.icon(
          icon: Icons.event_outlined,
          title: 'By event',
          subtitle: 'Pick an event, see who came',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventHistoryView()),
          ),
        ),
        const SizedBox(height: 8),
        AppListTile.icon(
          icon: Icons.person_outline_rounded,
          title: 'By person',
          subtitle: 'Pick a ticket, trace attendance',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TicketHistoryView()),
          ),
        ),
      ],
    );
  }
}

class _TrendPoint {
  const _TrendPoint({required this.start, required this.attendees});
  final DateTime start;
  final int attendees;
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend, required this.loading});

  final List<_TrendPoint> trend;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasData = trend.isNotEmpty;
    final avg = hasData
        ? (trend.map((p) => p.attendees).reduce((a, b) => a + b) / trend.length)
            .round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance trend',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            hasData
                ? 'Last ${trend.length} event${trend.length == 1 ? "" : "s"}'
                : 'Not enough events recorded yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const SizedBox(
              height: 132,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
            )
          else if (!hasData)
            SizedBox(
              height: 132,
              child: Center(
                child: Text(
                  'Once events finish, attendance trends appear here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$avg',
                      style: theme.textTheme.displaySmall?.copyWith(
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg check-in',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 96,
                    child: _TrendBars(trend: trend, average: avg.toDouble()),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.trend, required this.average});

  final List<_TrendPoint> trend;
  final double average;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = trend.fold<int>(0, (a, b) => b.attendees > a ? b.attendees : a);
    final safeMax = maxValue == 0 ? 1 : maxValue;
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const gap = 4.0;
      final barW = (w - gap * (trend.length - 1)) / trend.length;
      final avgY = h - (average / safeMax) * h;
      return Stack(
        children: [
          // Average reference line
          Positioned(
            left: 0,
            right: 0,
            top: avgY,
            child: CustomPaint(
              size: Size(w, 1),
              painter: _DashedLinePainter(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < trend.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                _Bar(
                  width: barW,
                  height: (trend[i].attendees / safeMax) * h,
                  highlight: i == trend.length - 1,
                ),
              ],
            ],
          ),
        ],
      );
    });
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.highlight});
  final double width;
  final double height;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height.clamp(2.0, double.infinity),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.primary
            : scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 3.0, gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

/// Helper used by sub-views that just need a navigation tile to an event row.
class EventNavTile extends StatelessWidget {
  const EventNavTile({super.key, required this.event, this.reviewMode = true});
  final Event event;
  final bool reviewMode;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: event.name,
      subtitle: event.getTimeString(),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AttendanceView(event: event, reviewMode: reviewMode),
        ),
      ),
    );
  }
}
