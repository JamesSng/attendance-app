import 'package:flutter/material.dart';

/// Horizontal chip filter bar — replaces the old CheckboxListTile blocks.
///
/// Each option carries a label and an optional count. Pass [selectedIds] to
/// represent the active set; [onToggle] is called with the option id when the
/// user taps it.
class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.options,
    required this.selectedIds,
    required this.onToggle,
    this.padding = EdgeInsets.zero,
  });

  final List<FilterChipOption<T>> options;
  final Set<T> selectedIds;
  final void Function(T id) onToggle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: padding,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            _Chip(
              label: option.label,
              count: option.count,
              selected: selectedIds.contains(option.id),
              onTap: () => onToggle(option.id),
              scheme: scheme,
              textTheme: theme.textTheme,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class FilterChipOption<T> {
  const FilterChipOption({required this.id, required this.label, this.count});
  final T id;
  final String label;
  final int? count;
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.scheme,
    required this.textTheme,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? scheme.primary : Colors.transparent;
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    final border = selected
        ? scheme.primary
        : scheme.outlineVariant.withValues(alpha: 0.7);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(color: fg),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: textTheme.labelMedium?.copyWith(
                    color: fg.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
