import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/event.dart';
import '../model/ticket.dart';
import '../util/time_format.dart';
import 'widgets/app_scaffold.dart';
import 'widgets/empty_state.dart';
import 'widgets/filter_chip_bar.dart';
import 'widgets/status_widgets.dart';

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key, required this.event, this.reviewMode = false});

  final Event event;
  final bool reviewMode;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: event.name,
      subtitle: '${formatDayLabel(event.startTime)} · '
          '${formatTimeRange(event.startTime, event.endTime)}',
      padded: false,
      body: AttendanceListView(
        eventId: event.id,
        event: event,
        reviewMode: reviewMode,
      ),
    );
  }
}

class AttendanceListView extends StatefulWidget {
  AttendanceListView({
    super.key,
    required this.eventId,
    required this.event,
    this.reviewMode = false,
  });

  final String eventId;
  final Event event;
  final bool reviewMode;
  final db = FirebaseFirestore.instance;

  @override
  State<AttendanceListView> createState() => _AttendanceViewState();
}

enum _AttendanceFilter { all, regulars, others, unchecked }

class _AttendanceViewState extends State<AttendanceListView> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  bool loadingChecked = true, loadingMap = true;
  int checkedNo = 0;
  Map<String, Ticket> idToTicket = {};
  List<Ticket> tickets = [], showTickets = [];

  String query = '';
  _AttendanceFilter filter = _AttendanceFilter.all;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _onQueryChanged() {
    showTickets = tickets
        .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
        .where((t) => switch (filter) {
              _AttendanceFilter.all => true,
              _AttendanceFilter.regulars => t.regular,
              _AttendanceFilter.others => !t.regular,
              _AttendanceFilter.unchecked => !t.checked,
            })
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _loadData() {
    widget.db
        .collection("events")
        .doc(widget.eventId)
        .collection("attendees")
        .snapshots()
        .listen((res) {
      final newTickets = <Ticket>[
        for (final ticket in res.docs)
          Ticket(
              id: ticket.id,
              name: '',
              regular: false,
              checked: ticket.get('checked')),
      ];
      _processData(newTickets, false, idToTicket, loadingMap);
    });

    widget.db.collection("tickets").snapshots().listen((res) {
      final newMap = <String, Ticket>{
        for (final ticket in res.docs)
          ticket.id: Ticket(
            id: ticket.id,
            name: ticket.get('name'),
            regular: ticket.get('regular'),
            active: ticket.get('active'),
          ),
      };
      _processData(tickets, loadingChecked, newMap, false);
    });
  }

  void _processData(
    List<Ticket> newTickets,
    bool newLoadingChecked,
    Map<String, Ticket> newIdToTicket,
    bool newLoadingMap,
  ) {
    if (!newLoadingMap && !newLoadingChecked) {
      var newChecked = 0;
      final filtered = <Ticket>[];
      for (final ticket in newTickets) {
        final mapped = newIdToTicket[ticket.id];
        if (mapped != null) {
          mapped.checked = ticket.checked;
          filtered.add(mapped);
          if (mapped.checked) newChecked++;
        }
      }
      setState(() {
        tickets = filtered;
        idToTicket = newIdToTicket;
        checkedNo = newChecked;
        loadingChecked = newLoadingChecked;
        loadingMap = newLoadingMap;
        _onQueryChanged();
      });
    } else {
      setState(() {
        tickets = newTickets;
        idToTicket = newIdToTicket;
        loadingChecked = newLoadingChecked;
        loadingMap = newLoadingMap;
      });
    }
  }

  void _updateChecked(int index, bool value) {
    widget.db
        .collection("events")
        .doc(widget.eventId)
        .collection("attendees")
        .doc(showTickets[index].id)
        .update({'checked': value});
  }

  @override
  Widget build(BuildContext context) {
    if (loadingChecked || loadingMap) return const _AttendanceSkeleton();
    return _renderData(context);
  }

  Widget _renderData(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final regulars = tickets.where((t) => t.regular).length;
    final others = tickets.length - regulars;
    final unchecked = tickets.where((t) => !t.checked).length;
    final total = tickets.length;
    final progress = total == 0 ? 0.0 : checkedNo / total;
    final isOngoing = widget.event.isOngoing();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$checkedNo',
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '/ $total checked in',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isOngoing) const LivePill(),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: total == 0 ? null : progress,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                total == 0
                    ? 'No active tickets yet'
                    : formatEventStatusLine(
                        startTime: widget.event.startTime,
                        endTime: widget.event.endTime,
                      ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            onChanged: (v) {
              setState(() {
                query = v;
                _onQueryChanged();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search attendees',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(color: scheme.primary, width: 1.4),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: FilterChipBar<_AttendanceFilter>(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            options: [
              FilterChipOption(
                  id: _AttendanceFilter.all, label: 'All', count: total),
              FilterChipOption(
                  id: _AttendanceFilter.regulars,
                  label: 'Regulars',
                  count: regulars),
              FilterChipOption(
                  id: _AttendanceFilter.others, label: 'Others', count: others),
              FilterChipOption(
                  id: _AttendanceFilter.unchecked,
                  label: 'Unchecked',
                  count: unchecked),
            ],
            selectedIds: {filter},
            onToggle: (id) {
              setState(() {
                filter = id;
                _onQueryChanged();
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: showTickets.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches',
                  message: 'Try a different filter or clear the search.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: showTickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ticket = showTickets[index];
                    return _AttendeeRow(
                      ticket: ticket,
                      readonly: widget.reviewMode,
                      onChanged: (value) => _updateChecked(index, value),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({
    required this.ticket,
    required this.onChanged,
    required this.readonly,
  });

  final Ticket ticket;
  final ValueChanged<bool> onChanged;
  final bool readonly;

  String get _initials {
    final parts = ticket.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = ticket.checked;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.06)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: readonly ? null : () => onChanged(!selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.name,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    StatusPill(
                      label: ticket.regular ? 'Regular' : 'Other',
                      tone: ticket.regular
                          ? StatusPillTone.accent
                          : StatusPillTone.neutral,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CheckBadge(
                checked: selected,
                disabled: readonly,
                onTap: readonly ? null : () => onChanged(!selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({
    required this.checked,
    required this.disabled,
    required this.onTap,
  });

  final bool checked;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 28.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked
              ? (disabled
                  ? scheme.primary.withValues(alpha: 0.5)
                  : scheme.primary)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: checked
                ? Colors.transparent
                : scheme.outlineVariant.withValues(alpha: 0.8),
            width: 1.4,
          ),
        ),
        alignment: Alignment.center,
        child: checked
            ? Icon(
                Icons.check_rounded,
                size: 18,
                color: scheme.onPrimary,
              )
            : null,
      ),
    );
  }
}

class _AttendanceSkeleton extends StatelessWidget {
  const _AttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: const [
        SkeletonBlock(height: 28, width: 160),
        SizedBox(height: 12),
        SkeletonBlock(height: 6, borderRadius: 999),
        SizedBox(height: 14),
        SkeletonBlock(height: 40, borderRadius: 999),
        SizedBox(height: 12),
        SkeletonBlock(height: 32, width: 240, borderRadius: 999),
        SizedBox(height: 16),
        SkeletonBlock(height: 60, borderRadius: 14),
        SizedBox(height: 8),
        SkeletonBlock(height: 60, borderRadius: 14),
        SizedBox(height: 8),
        SkeletonBlock(height: 60, borderRadius: 14),
        SizedBox(height: 8),
        SkeletonBlock(height: 60, borderRadius: 14),
      ],
    );
  }
}
