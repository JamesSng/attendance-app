import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/event.dart';
import '../util/logger.dart';
import 'eventlistview.dart';
import 'widgets/app_scaffold.dart';

class EventSettingsView extends StatefulWidget {
  EventSettingsView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<EventSettingsView> createState() => _EventSettingsViewState();
}

class _EventSettingsViewState extends State<EventSettingsView> {
  Future<void> _createEvent(BuildContext context) async {
    final initial = _defaultNewEventRange();

    final draft = await showDialog<_EventDraft>(
      context: context,
      builder: (context) => _EventEditorDialog(
        title: 'Create event',
        confirmLabel: 'Create',
        initial: _EventDraft(
          name: '',
          start: initial.$1,
          end: initial.$2,
        ),
      ),
    );

    if (draft == null) return;

    final eventDoc = widget.db.collection('events').doc();
    await eventDoc.set({
      'name': draft.name,
      'startTime': Timestamp.fromDate(draft.start),
      'endTime': Timestamp.fromDate(draft.end),
    });
    Logger.createEvent(Event(
      id: '',
      name: draft.name,
      startTime: draft.start,
      endTime: draft.end,
    ));
    final batch = widget.db.batch();
    final tickets = await widget.db
        .collection('tickets')
        .where('active', isEqualTo: true)
        .get();
    for (final ticket in tickets.docs) {
      batch.set(
        eventDoc.collection('attendees').doc(ticket.id),
        {'checked': false},
      );
    }
    await batch.commit();
  }

  /// Returns (start, end) defaults for a new event:
  /// start = next round half-hour, end = start + 1 hour.
  (DateTime, DateTime) _defaultNewEventRange() {
    final now = DateTime.now();
    final delta = now.minute < 30 ? 30 - now.minute : 60 - now.minute;
    final start = DateTime(now.year, now.month, now.day, now.hour, now.minute)
        .add(Duration(minutes: delta));
    return (start, start.add(const Duration(hours: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manage events',
      padded: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createEvent(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: EventListView(onEventPressed: (Event event) {
        EditEventHelper().editEvent(context, event);
      }),
    );
  }
}

class EditEventHelper {
  final db = FirebaseFirestore.instance;

  Future<void> editEvent(BuildContext context, Event event) async {
    final original = event.copy();
    final result = await showDialog<_EventEditorResult>(
      context: context,
      builder: (context) => _EventEditorDialog(
        title: 'Edit event',
        confirmLabel: 'Save',
        showDelete: kDebugMode,
        initial: _EventDraft(
          name: event.name,
          start: event.startTime,
          end: event.endTime,
        ),
      ),
    );

    if (result == null) return;
    switch (result.action) {
      case _EventEditorAction.save:
        final draft = result.draft!;
        final changed = original.name != draft.name ||
            original.startTime != draft.start ||
            original.endTime != draft.end;
        if (!changed) return;
        await db.collection('events').doc(event.id).set({
          'name': draft.name,
          'startTime': Timestamp.fromDate(draft.start),
          'endTime': Timestamp.fromDate(draft.end),
        });
        Logger.editEvent(
          original,
          Event(
            id: event.id,
            name: draft.name,
            startTime: draft.start,
            endTime: draft.end,
          ),
        );
      case _EventEditorAction.delete:
        final attendees = await db
            .collection('events')
            .doc(event.id)
            .collection('attendees')
            .get();
        final batch = db.batch();
        for (final doc in attendees.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        await db.collection('events').doc(event.id).delete();
    }
  }
}

class _EventDraft {
  _EventDraft({required this.name, required this.start, required this.end});
  String name;
  DateTime start;
  DateTime end;
}

enum _EventEditorAction { save, delete }

class _EventEditorResult {
  _EventEditorResult.save(_EventDraft this.draft) : action = _EventEditorAction.save;
  _EventEditorResult.delete()
      : draft = null,
        action = _EventEditorAction.delete;
  final _EventEditorAction action;
  final _EventDraft? draft;
}

/// Compact create / edit dialog.
///
/// Layout:
///   - Single Name field
///   - One Date row (tap to pick a calendar date)
///   - One Time row split into Starts | Ends (each opens a `TimePicker`)
///
/// Behaviours:
///   - Picking a date moves both start and end onto that date, preserving the
///     time-of-day on each.
///   - Picking a start time keeps the gap between start and end constant
///     (so editing start auto-shifts end).
///   - Picking an end time before start auto-bumps it to start + 30 min.
class _EventEditorDialog extends StatefulWidget {
  const _EventEditorDialog({
    required this.title,
    required this.confirmLabel,
    required this.initial,
    this.showDelete = false,
  });

  final String title;
  final String confirmLabel;
  final _EventDraft initial;
  final bool showDelete;

  @override
  State<_EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<_EventEditorDialog> {
  late final TextEditingController _nameCtrl;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial.name);
    _start = widget.initial.start;
    _end = widget.initial.end;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() {
      _start = DateTime(
        picked.year, picked.month, picked.day, _start.hour, _start.minute);
      _end = DateTime(
        picked.year, picked.month, picked.day, _end.hour, _end.minute);
      // If end-of-day rolled before start due to overnight events, push end +1d.
      if (!_end.isAfter(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (picked == null) return;
    setState(() {
      final duration = _end.difference(_start);
      _start = DateTime(_start.year, _start.month, _start.day,
          picked.hour, picked.minute);
      _end = _start.add(duration.isNegative ? const Duration(hours: 1) : duration);
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (picked == null) return;
    setState(() {
      var newEnd = DateTime(
          _end.year, _end.month, _end.day, picked.hour, picked.minute);
      // If user picks an earlier wall-clock time than the start, assume same day:
      // bump forward to at least start + 30min (helps for sub-hour events).
      if (!newEnd.isAfter(_start)) {
        newEnd = _start.add(const Duration(minutes: 30));
      }
      _end = newEnd;
    });
  }

  Future<void> _onDeletePressed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, _EventEditorResult.delete());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          Expanded(child: Text(widget.title)),
          if (widget.showDelete)
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              onPressed: _onDeletePressed,
            ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: widget.initial.name.isEmpty,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          _EditorRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: DateFormat('EEE, d MMM y').format(_start),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EditorRow(
                  icon: Icons.schedule_rounded,
                  label: 'Starts',
                  value: _formatTime(context, _start),
                  onTap: _pickStartTime,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EditorRow(
                  icon: Icons.schedule_rounded,
                  label: 'Ends',
                  value: _formatTime(context, _end),
                  onTap: _pickEndTime,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                _EventEditorResult.save(_EventDraft(
                  name: _nameCtrl.text.trim(),
                  start: _start,
                  end: _end,
                )),
              );
            },
            child: Text(widget.confirmLabel),
          ),
        ),
      ],
    );
  }
}

String _formatTime(BuildContext context, DateTime dt) =>
    TimeOfDay.fromDateTime(dt).format(context);

/// Tappable label/value row used in the event editor for date and times.
class _EditorRow extends StatelessWidget {
  const _EditorRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
