import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/event.dart';
import '../util/time_format.dart';
import 'attendanceview.dart';
import 'widgets/empty_state.dart';
import 'widgets/status_widgets.dart';

class EventsView extends StatefulWidget {
  EventsView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  bool loading = true;
  List<Event> ongoingEvents = [], upcomingEvents = [];

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    widget.db
        .collection("events")
        .where('endTime', isGreaterThanOrEqualTo: DateTime.now())
        .orderBy('startTime')
        .snapshots()
        .listen((res) {
      final ongoing = <Event>[];
      final upcoming = <Event>[];
      for (final doc in res.docs) {
        final e = Event(
          id: doc.id,
          name: doc.get('name'),
          startTime: doc.get('startTime').toDate(),
          endTime: doc.get('endTime').toDate(),
        );
        if (e.isOngoing()) {
          ongoing.add(e);
        } else {
          upcoming.add(e);
        }
      }
      setState(() {
        ongoingEvents = ongoing;
        upcomingEvents = upcoming;
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const _EventsLoading();
    if (ongoingEvents.isEmpty && upcomingEvents.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_rounded,
        title: 'No upcoming services',
        message: 'New events will appear here once they\'re scheduled.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _GreetingHeader(
          ongoingCount: ongoingEvents.length,
          upcomingCount: upcomingEvents.length,
        ),
        const SizedBox(height: 16),
        for (final event in ongoingEvents) ...[
          _OngoingHeroCard(event: event),
          const SizedBox(height: 12),
        ],
        if (upcomingEvents.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'COMING UP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          for (final event in upcomingEvents) ...[
            _UpcomingEventTile(event: event),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _EventsLoading extends StatelessWidget {
  const _EventsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        SkeletonBlock(height: 14, width: 140),
        SizedBox(height: 16),
        SkeletonBlock(height: 132, borderRadius: 14),
        SizedBox(height: 24),
        SkeletonBlock(height: 14, width: 100),
        SizedBox(height: 12),
        SkeletonBlock(height: 64, borderRadius: 12),
        SizedBox(height: 8),
        SkeletonBlock(height: 64, borderRadius: 12),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.ongoingCount, required this.upcomingCount});

  final int ongoingCount;
  final int upcomingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = ongoingCount > 0
        ? '$ongoingCount happening now'
        : upcomingCount == 1
            ? 'Next event below'
            : '$upcomingCount upcoming';
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatLongDayLabel(DateTime.now()).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: theme.textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

class _OngoingHeroCard extends StatelessWidget {
  const _OngoingHeroCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final total = event.endTime.difference(event.startTime).inSeconds;
    final elapsed = now.difference(event.startTime).inSeconds;
    final progress = total <= 0 ? 0.0 : (elapsed / total).clamp(0.0, 1.0);

    return Material(
      color: scheme.primary.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AttendanceView(event: event)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const LivePill(),
                  const Spacer(),
                  Text(
                    formatTimeRange(event.startTime, event.endTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatEventStatusLine(
                            startTime: event.startTime,
                            endTime: event.endTime,
                            now: now,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ProgressRing(
                    value: progress,
                    label: '${(progress * 100).round()}%',
                    subLabel: 'elapsed',
                    size: 64,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AttendanceView(event: event)),
                    );
                  },
                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                  label: const Text('Mark attendance'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingEventTile extends StatelessWidget {
  const _UpcomingEventTile({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AttendanceView(event: event)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              EventDateBlock(date: event.startTime, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatTimeRange(event.startTime, event.endTime)} · '
                      '${formatRelative(event.startTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
