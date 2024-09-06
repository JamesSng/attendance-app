import 'package:flutter/material.dart';

import '../model/event.dart';
import 'attendanceview.dart';
import 'eventlistview.dart';

class EventHistoryView extends StatelessWidget {
  const EventHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          "Event History",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: EventListView(onEventPressed: (Event event) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AttendanceView(event: event, reviewMode: true)),
        );
      }),
    );
  }
}