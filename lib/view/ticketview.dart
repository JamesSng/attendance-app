import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/event.dart';
import '../model/ticket.dart';
import '../util/time_format.dart';
import 'widgets/app_scaffold.dart';
import 'widgets/empty_state.dart';
import 'widgets/status_widgets.dart';

class TicketView extends StatelessWidget {
  TicketView({super.key, required this.ticket});
  final db = FirebaseFirestore.instance;
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: ticket.name,
      subtitle: ticket.regular ? 'Regular ticket' : 'Other ticket',
      padded: false,
      body: TicketEventView(ticket: ticket),
    );
  }
}

class TicketEventView extends StatefulWidget {
  TicketEventView({super.key, required this.ticket});
  final db = FirebaseFirestore.instance;
  final Ticket ticket;

  @override
  State<TicketEventView> createState() => _TicketEventViewState();
}

class _TicketEventViewState extends State<TicketEventView> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  bool init = false, loading = true;
  int loadCount = 0;
  List<Event> events = [];
  List<bool?> checked = [];
  late DateTimeRange dateTimeRange;
  late TextEditingController dateRangeController;

  Future<void> _selectDateRange(BuildContext context) async {
    final newRange = await showDateRangePicker(
      context: context,
      initialDateRange: dateTimeRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );

    if (newRange != null && newRange != dateTimeRange) {
      setState(() {
        loading = true;
        dateTimeRange = newRange;
      });
      _loadData();
    }
  }

  void _loadData() {
    widget.db
        .collection("events")
        .where("startTime",
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateTimeRange.start),
            isLessThanOrEqualTo: Timestamp.fromDate(dateTimeRange.end))
        .orderBy("startTime", descending: true)
        .get()
        .then((res) {
      final newEvents = <Event>[
        for (final doc in res.docs)
          Event(
            id: doc.id,
            name: doc.get("name"),
            startTime: doc.get('startTime').toDate(),
            endTime: doc.get('endTime').toDate(),
          ),
      ];
      checked = List.generate(res.docs.length, (_) => false);
      loadCount = 0;

      for (var i = 0; i < res.docs.length; ++i) {
        final event = res.docs[i];
        event.reference
            .collection("attendees")
            .doc(widget.ticket.id)
            .get()
            .then((res) {
          setState(() {
            checked[i] = res.exists ? res.get("checked") : null;
            loadCount = loadCount + 1;
            if (loadCount == events.length) {
              final filteredEvents = <Event>[];
              final filteredChecked = <bool>[];
              for (var i = 0; i < events.length; ++i) {
                if (checked[i] != null) {
                  filteredEvents.add(events[i]);
                  filteredChecked.add(checked[i]!);
                }
              }
              events = filteredEvents;
              checked = filteredChecked;
              loadCount = events.length;
            }
          });
        });
      }

      setState(() {
        events = newEvents;
        loading = false;
      });
    });
  }

  String _rangeText(DateTimeRange r) {
    final f = DateFormat('d MMM yyyy');
    return '${f.format(r.start)} – ${f.format(r.end)}';
  }

  @override
  Widget build(BuildContext context) {
    if (!init) {
      init = true;
      final now = DateTime.now();
      dateTimeRange = DateTimeRange(
        start: DateTime(now.year, now.month - 1, now.day),
        end: DateTime(now.year, now.month, now.day),
      );
      _loadData();
    }
    dateRangeController = TextEditingController(text: _rangeText(dateTimeRange));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          TextField(
            readOnly: true,
            controller: dateRangeController,
            decoration: const InputDecoration(
              labelText: 'Range',
              prefixIcon: Icon(Icons.calendar_today_rounded),
            ),
            onTap: () => _selectDateRange(context),
          ),
          const SizedBox(height: 12),
          if (loading || loadCount != events.length)
            const Expanded(child: SkeletonRows(count: 6))
          else if (events.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No attendance in range',
                message: 'Try a wider date range to see history.',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final wasPresent = checked[index] == true;
                  return _AttendanceRow(
                    event: event,
                    present: wasPresent,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.event, required this.present});
  final Event event;
  final bool present;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          EventDateBlock(date: event.startTime, size: 48, highlight: present),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  formatTimeRange(event.startTime, event.endTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(
            label: present ? 'Present' : 'Absent',
            icon: present ? Icons.check_rounded : Icons.close_rounded,
            tone: present ? StatusPillTone.accent : StatusPillTone.neutral,
          ),
        ],
      ),
    );
  }
}
