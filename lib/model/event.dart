import 'package:intl/intl.dart';

class Event {
  Event({
    required this.id, required this.name, required this.date,
  });

  String id, name;
  DateTime date;
  DateFormat dateFormat = DateFormat("dd/MM/yyyy");

  String getDateString() {
    return dateFormat.format(date);
  }
}