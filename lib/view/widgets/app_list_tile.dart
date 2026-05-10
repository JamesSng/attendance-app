import 'package:flutter/material.dart';

/// Hairline-bordered list tile that replaces the saturated FilledButton rows
/// across the app. Promotes one item per screen by reserving the accent fill
/// for true primary actions only.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.tone = AppListTileTone.surface,
    this.dense = false,
  });

  /// Build a row with a small icon-tile leading element.
  factory AppListTile.icon({
    Key? key,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool dense = false,
  }) =>
      _IconAppListTile(
        key: key,
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        dense: dense,
      );

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final AppListTileTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = switch (tone) {
      AppListTileTone.surface => scheme.surface,
      AppListTileTone.subtle => scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      AppListTileTone.accent => scheme.primary.withValues(alpha: 0.10),
    };
    final border = switch (tone) {
      AppListTileTone.surface => scheme.outlineVariant.withValues(alpha: 0.5),
      AppListTileTone.subtle => Colors.transparent,
      AppListTileTone.accent => scheme.primary.withValues(alpha: 0.35),
    };

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: dense ? 10 : 14,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum AppListTileTone { surface, subtle, accent }

class _IconAppListTile extends AppListTile {
  const _IconAppListTile({
    super.key,
    required this.icon,
    required super.title,
    super.subtitle,
    super.onTap,
    super.dense,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppListTile(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      dense: dense,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: scheme.primary),
      ),
    );
  }
}

/// Section header label (e.g. "MANAGE", "PREFERENCES").
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Card grouping multiple list rows together (e.g. the Manage block on
/// Settings).
class AppListGroup extends StatelessWidget {
  const AppListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divided = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        divided.add(Padding(
          padding: const EdgeInsets.only(left: 62),
          child: Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ));
      }
      divided.add(children[i]);
    }
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: divided),
    );
  }
}

/// Plain row designed to live inside an [AppListGroup] (no border of its own).
class AppGroupedRow extends StatelessWidget {
  const AppGroupedRow({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
