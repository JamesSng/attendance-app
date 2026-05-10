import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../model/event.dart';
import '../util/time_format.dart';
import 'widgets/empty_state.dart';
import 'widgets/status_widgets.dart';

class EventListView extends StatefulWidget {
  EventListView({super.key, required this.onEventPressed});
  final db = FirebaseFirestore.instance;
  final void Function(Event event) onEventPressed;

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  late DateTime selectedMonth;
  bool init = false;
  bool loading = true;
  List<Event> events = [];

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  void _loadData() {
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    widget.db
        .collection("events")
        .where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(selectedMonth),
            isLessThan: Timestamp.fromDate(nextMonth))
        .orderBy('startTime')
        .snapshots()
        .listen((res) {
      final newEvents = <Event>[
        for (final doc in res.docs)
          Event(
            id: doc.id,
            name: doc.get('name'),
            startTime: doc.get('startTime').toDate(),
            endTime: doc.get('endTime').toDate(),
          ),
      ];
      setState(() {
        events = newEvents;
        loading = false;
      });
    });
  }

  void _changeMonth(DateTime next) {
    setState(() {
      selectedMonth = DateTime(next.year, next.month);
      loading = true;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (!init) {
      init = true;
      final now = DateTime.now();
      selectedMonth = DateTime(now.year, now.month);
      _loadData();
    }

    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(DateTime(
                    selectedMonth.year, selectedMonth.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous month',
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => _selectMonth(context),
                  child: Text(
                    DateFormat("MMMM yyyy").format(selectedMonth),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(DateTime(
                    selectedMonth.year, selectedMonth.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next month',
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SkeletonRows(count: 5),
                )
              : events.isEmpty
                  ? const EmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'No events this month',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _EventRow(
                          event: events[index],
                          onTap: () => widget.onEventPressed(events[index]),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final newMonth = await showMonthPicker(
      context: context,
      initialDate: selectedMonth,
    );
    if (newMonth != null && selectedMonth != newMonth) {
      _changeMonth(newMonth);
    }
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onTap});
  final Event event;
  final VoidCallback onTap;

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
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
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
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
