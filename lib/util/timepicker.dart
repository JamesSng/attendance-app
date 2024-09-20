import 'package:flutter/material.dart';

Future<DateTime> selectTime(BuildContext context, DateTime original) async {
  DateTime firstDate = DateTime.now().subtract(const Duration(days: 365 * 5));
  DateTime lastDate = DateTime.now().add(const Duration(days: 365 * 5));

  final DateTime? selectedDate = await showDatePicker(
    context: context,
    initialDate: original,
    firstDate: firstDate,
    lastDate: lastDate,
  );

  if (selectedDate == null) return original;
  if (!context.mounted) return original;

  final TimeOfDay? selectedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(original),
    builder: (BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      );
    },
  );

  return selectedTime == null ? original : DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    selectedTime.hour,
    selectedTime.minute,
  );
}