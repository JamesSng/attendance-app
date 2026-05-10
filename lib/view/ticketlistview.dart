import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/ticket.dart';
import 'widgets/empty_state.dart';
import 'widgets/filter_chip_bar.dart';
import 'widgets/status_widgets.dart';

class TicketListView extends StatefulWidget {
  TicketListView({super.key, required this.onTicketPressed});
  final db = FirebaseFirestore.instance;
  final Function(Ticket ticket) onTicketPressed;

  @override
  State<TicketListView> createState() => _TicketListViewState();
}

enum _TicketGroupFilter { all, regulars, others }

enum _TicketStateFilter { active, inactive, both }

class _TicketListViewState extends State<TicketListView> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  bool loading = true;
  List<Ticket> tickets = [], showTickets = [];
  String query = '';
  _TicketGroupFilter group = _TicketGroupFilter.all;
  _TicketStateFilter state = _TicketStateFilter.active;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _onQueryChanged() {
    final q = query.toLowerCase();
    showTickets = tickets
        .where((t) => t.name.toLowerCase().contains(q))
        .where((t) => switch (group) {
              _TicketGroupFilter.all => true,
              _TicketGroupFilter.regulars => t.regular,
              _TicketGroupFilter.others => !t.regular,
            })
        .where((t) => switch (state) {
              _TicketStateFilter.both => true,
              _TicketStateFilter.active => t.active,
              _TicketStateFilter.inactive => !t.active,
            })
        .toList()
      ..sort((a, b) {
        if (a.active == b.active) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        return a.active ? -1 : 1;
      });
  }

  void _loadData() {
    widget.db.collection("tickets").snapshots().listen((res) {
      final newTickets = <Ticket>[
        for (final doc in res.docs)
          Ticket(
            id: doc.id,
            name: doc.get("name"),
            regular: doc.get("regular"),
            active: doc.get("active"),
            checked: false,
          ),
      ];
      setState(() {
        tickets = newTickets;
        loading = false;
        _onQueryChanged();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: SkeletonRows(count: 6),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final regulars = tickets.where((t) => t.regular).length;
    final others = tickets.length - regulars;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) {
              setState(() {
                query = v;
                _onQueryChanged();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search tickets',
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
          child: FilterChipBar<_TicketGroupFilter>(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            options: [
              FilterChipOption(
                  id: _TicketGroupFilter.all, label: 'All', count: tickets.length),
              FilterChipOption(
                  id: _TicketGroupFilter.regulars,
                  label: 'Regulars',
                  count: regulars),
              FilterChipOption(
                  id: _TicketGroupFilter.others, label: 'Others', count: others),
            ],
            selectedIds: {group},
            onToggle: (id) {
              setState(() {
                group = id;
                _onQueryChanged();
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: FilterChipBar<_TicketStateFilter>(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            options: const [
              FilterChipOption(
                  id: _TicketStateFilter.active, label: 'Active'),
              FilterChipOption(
                  id: _TicketStateFilter.inactive, label: 'Inactive'),
              FilterChipOption(
                  id: _TicketStateFilter.both, label: 'Both'),
            ],
            selectedIds: {state},
            onToggle: (id) {
              setState(() {
                state = id;
                _onQueryChanged();
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: showTickets.isEmpty
              ? const EmptyState(
                  icon: Icons.confirmation_number_outlined,
                  title: 'No tickets match',
                  message: 'Adjust the filters or clear your search.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: showTickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ticket = showTickets[index];
                    return _TicketRow(
                      ticket: ticket,
                      onTap: () => widget.onTicketPressed(ticket),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket, required this.onTap});
  final Ticket ticket;
  final VoidCallback onTap;

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
    final inactive = !ticket.active;
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontStyle:
                            inactive ? FontStyle.italic : FontStyle.normal,
                        color: inactive
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusPill(
                          label: ticket.regular ? 'Regular' : 'Other',
                          tone: ticket.regular
                              ? StatusPillTone.accent
                              : StatusPillTone.neutral,
                        ),
                        if (inactive) ...[
                          const SizedBox(width: 6),
                          const StatusPill(
                            label: 'Inactive',
                            tone: StatusPillTone.warning,
                          ),
                        ],
                      ],
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
