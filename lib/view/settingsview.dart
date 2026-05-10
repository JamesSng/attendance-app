import 'package:attendance_app/util/theme_controller.dart';
import 'package:attendance_app/view/ticketsettingsview.dart';
import 'package:attendance_app/view/usersettingsview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'eventsettingsview.dart';
import 'logssettingsview.dart';
import 'widgets/app_list_tile.dart';
import 'widgets/status_widgets.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = role == "admin";

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ProfileCard(
          name: user?.displayName,
          email: user?.email ?? '',
          photoUrl: user?.photoURL,
          role: role,
        ),
        const AppSectionHeader('Appearance'),
        const _ThemeModeSelector(),
        if (isAdmin) ...[
          const AppSectionHeader('Manage'),
          AppListGroup(
            children: [
              AppGroupedRow(
                icon: Icons.event_outlined,
                title: 'Events',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventSettingsView()),
                ),
              ),
              AppGroupedRow(
                icon: Icons.confirmation_number_outlined,
                title: 'Tickets',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TicketSettingsView()),
                ),
              ),
              AppGroupedRow(
                icon: Icons.group_outlined,
                title: 'Users',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserSettingsView()),
                ),
              ),
              AppGroupedRow(
                icon: Icons.receipt_long_outlined,
                title: 'Activity logs',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogsSettingsView()),
                ),
              ),
            ],
          ),
        ],
        const AppSectionHeader('Account'),
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    if (!kIsWeb) GoogleSignIn.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goodbye!')),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.role,
  });

  final String? name;
  final String email;
  final String? photoUrl;
  final String role;

  String get _initials {
    final source = (name?.isNotEmpty == true ? name! : email).trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'[\s.@]+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  StatusPillTone get _roleTone => switch (role) {
        'admin' => StatusPillTone.accent,
        'usher' => StatusPillTone.accent,
        'auditor' => StatusPillTone.neutral,
        _ => StatusPillTone.warning,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: photoUrl == null
                ? Text(
                    _initials,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name?.isNotEmpty == true ? name! : email.split('@').first,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                StatusPill(
                  label: role.toUpperCase(),
                  tone: _roleTone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto_rounded),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_rounded),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_rounded),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) =>
              themeController.setMode(selection.first),
        );
      },
    );
  }
}
