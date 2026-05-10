import 'package:attendance_app/model/log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'widgets/app_scaffold.dart';
import 'widgets/empty_state.dart';

class LogsSettingsView extends StatelessWidget {
  const LogsSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Activity logs',
      padded: false,
      body: LogListView(),
    );
  }
}

class LogListView extends StatefulWidget {
  LogListView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<LogListView> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  List<Log> logs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    widget.db
        .collection("logs")
        .orderBy('time', descending: true)
        .snapshots()
        .listen((res) {
      final newLogs = <Log>[
        for (final doc in res.docs)
          Log(log: doc.get("log"), time: doc.get("time").toDate()),
      ];
      setState(() {
        logs = newLogs;
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: SkeletonRows(count: 8, height: 56),
      );
    }
    if (logs.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No activity yet',
        message: 'Changes you make will be recorded here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _LogRow(log: logs[index]),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log});
  final Log log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.log,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            log.getTimeString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
