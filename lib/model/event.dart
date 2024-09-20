import 'package:intl/intl.dart';

class Event {
  Event({
    required this.id, required this.name, required this.startTime, required this.endTime,
  });

  String id, name;
  DateTime startTime, endTime;
  DateFormat dateFormat = DateFormat.yMd().add_Hm();

  String getStartTimeString() {
    return dateFormat.format(startTime);
  }

  String getEndTimeString() {
    return dateFormat.format(endTime);
  }

  String getTimeString() {
    return "${getStartTimeString()} to ${getEndTimeString()}";
  }

  @override
  String toString() {
    return "{name: $name, startTime: ${getStartTimeString()}, endTime: ${getEndTimeString()}";
  }

  Event copy(){
    return Event(id: id, name: name, startTime: startTime, endTime: endTime);
  }

  bool isOngoing() {
    return startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());
  }
}