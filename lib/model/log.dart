import 'package:intl/intl.dart';

class Log {
  Log({required this.log, required this.time});

  String log;
  DateTime time;

  DateFormat dateFormat = DateFormat("dd/MM/yyyy HH:mm:ss");

  String getTimeString() {
    return dateFormat.format(time);
  }
}