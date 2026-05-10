import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/user.dart';
import '../util/logger.dart';
import 'widgets/app_scaffold.dart';
import 'widgets/empty_state.dart';
import 'widgets/status_widgets.dart';

class UserSettingsView extends StatelessWidget {
  const UserSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manage users',
      padded: false,
      body: UserListView(),
    );
  }
}

class UserListView extends StatefulWidget {
  UserListView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  bool loading = true;
  List<User> users = [], showUsers = [];
  String query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _onQueryChanged() {
    final q = query.toLowerCase();
    showUsers = users
        .where((u) => u.email.toLowerCase().contains(q) ||
            u.role.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()));
  }

  void _loadData() {
    widget.db.collection("users").snapshots().listen((res) {
      final newUsers = <User>[
        for (final doc in res.docs)
          User(
            id: doc.id,
            email: doc.get("email"),
            role: doc.get("role"),
          ),
      ];
      setState(() {
        users = newUsers;
        loading = false;
        _onQueryChanged();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              hintText: 'Search by email or role',
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
        Expanded(
          child: loading
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SkeletonRows(count: 6),
                )
              : showUsers.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'No users match',
                      message: 'Try a different search term.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: showUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _UserRow(user: showUsers[index], onChange: _changeRole),
                    ),
        ),
      ],
    );
  }

  void _changeRole(User user, String newRole) {
    if (newRole == user.role) return;
    widget.db
        .collection("users")
        .doc(user.id)
        .update({"role": newRole}).then((_) {
      Logger.changeRole(user.role, newRole, user.email);
      setState(() => user.role = newRole);
    });
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onChange});
  final User user;
  final void Function(User user, String newRole) onChange;

  static const _adminEntries = ["admin"];
  static const _regularEntries = ["usher", "auditor", "disabled"];

  StatusPillTone _toneFor(String role) => switch (role) {
        'admin' => StatusPillTone.accent,
        'usher' => StatusPillTone.accent,
        'auditor' => StatusPillTone.neutral,
        _ => StatusPillTone.warning,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = user.role == 'admin' ? _adminEntries : _regularEntries;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                StatusPill(
                  label: user.role.toUpperCase(),
                  tone: _toneFor(user.role),
                ),
              ],
            ),
          ),
          if (user.role != 'admin')
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: scheme.onSurfaceVariant),
              tooltip: 'Change role',
              onSelected: (value) => onChange(user, value),
              itemBuilder: (context) => [
                for (final role in entries)
                  PopupMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        Icon(
                          role == user.role
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Text(role[0].toUpperCase() + role.substring(1)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
