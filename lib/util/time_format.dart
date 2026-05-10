import 'package:intl/intl.dart';

/// Formats a [DateTime] relative to [now] for human-friendly UI strings.
String formatRelative(DateTime target, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = target.difference(reference);
  final future = !diff.isNegative;
  final abs = diff.abs();

  String inOrAgo(String value) => future ? 'in $value' : '$value ago';

  if (abs.inMinutes < 1) return future ? 'in moments' : 'just now';
  if (abs.inMinutes < 60) {
    final m = abs.inMinutes;
    return inOrAgo('${m}m');
  }
  if (abs.inHours < 24) {
    final h = abs.inHours;
    final m = abs.inMinutes - h * 60;
    return inOrAgo(m == 0 ? '${h}h' : '${h}h ${m}m');
  }
  if (abs.inDays < 14) {
    return inOrAgo('${abs.inDays}d');
  }
  if (abs.inDays < 60) {
    final w = (abs.inDays / 7).floor();
    return inOrAgo('${w}w');
  }
  return DateFormat.MMMd().format(target);
}

/// "09:00 — 11:00" style time-of-day range.
String formatTimeRange(DateTime start, DateTime end) {
  final f = DateFormat.Hm();
  return '${f.format(start)} — ${f.format(end)}';
}

/// "Sat, 9 May" style date label.
String formatDayLabel(DateTime d) => DateFormat('EEE, d MMM').format(d);

/// "Saturday, May 9" style long date label.
String formatLongDayLabel(DateTime d) =>
    DateFormat('EEEE, MMMM d').format(d);

/// "ends in 1h 20m" / "starts in 3d" / "ended 2h ago" copy.
String formatEventStatusLine({
  required DateTime startTime,
  required DateTime endTime,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  if (reference.isBefore(startTime)) {
    return 'starts ${formatRelative(startTime, now: reference)}';
  }
  if (reference.isAfter(endTime)) {
    return 'ended ${formatRelative(endTime, now: reference)}';
  }
  return 'ends ${formatRelative(endTime, now: reference)}';
}
