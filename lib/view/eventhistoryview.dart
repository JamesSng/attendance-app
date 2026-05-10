import 'package:flutter/material.dart';

import '../model/event.dart';
import 'attendanceview.dart';
import 'eventlistview.dart';
import 'widgets/app_scaffold.dart';

class EventHistoryView extends StatelessWidget {
  const EventHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Event history',
      padded: false,
      body: EventListView(onEventPressed: (Event event) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AttendanceView(event: event, reviewMode: true),
          ),
        );
      }),
    );
  }
}
