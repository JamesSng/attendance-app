import 'package:flutter/material.dart';
import '../model/event.dart';
import 'attendanceview.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  @override
  Widget build(BuildContext context) {
    //TODO: get events from database
    List<Event> events = [
      Event(name: 'Sunday Service', date: DateTime(2024, 8, 17)),
      Event(name: 'Sunday Service', date: DateTime(2024, 8, 10)),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        children: [
          Text(
            'Upcoming Events',
            style: Theme
              .of(context)
              .textTheme
              .headlineSmall,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  margin: const EdgeInsets.only(top: 5, bottom: 5),
                  child: FilledButton(
                    onPressed: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AttendanceView(event: events[index])),
                      );
                    },
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(EdgeInsets.all(15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                events[index].name,
                                style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                                )
                              ),
                              Text(
                                events[index].getDateString(),
                                style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.labelLarge?.fontSize,
                                )
                              ),
                            ]
                          ),
                        ),
                        const Icon(Icons.arrow_forward),
                      ]
                    )
                  ),
                );
              },
            ),
          ),
        ],
      )
    );
  }
}