import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/event.dart';
import 'attendanceview.dart';

class EventsView extends StatefulWidget {
  EventsView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  bool loading = true;
  List<Event> ongoingEvents = [], upcomingEvents = [];

  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  loadData() {
    widget.db.collection("events")
    .where('endTime', isGreaterThanOrEqualTo: DateTime.now())
    .orderBy('startTime').snapshots().listen((res) {
      List<Event> newOngoingEvents = [], newUpcomingEvents = [];
      for (var event in res.docs) {
        Event e = Event(
          id: event.id,
          name: event.get('name'),
          startTime: event.get('startTime').toDate(),
          endTime: event.get('endTime').toDate()
        );
        if (e.isOngoing()) {
          newOngoingEvents.add(e);
        } else {
          newUpcomingEvents.add(e);
        }
      }
      setState(() {
        ongoingEvents = newOngoingEvents;
        upcomingEvents = newUpcomingEvents;
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return loading ? renderLoad() : renderData();
  }

  Widget renderLoad() {
    loadData();
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget getEventList(List<Event> events) {
    return ListView.builder(
      shrinkWrap: true,
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
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
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
                          fontWeight: FontWeight.bold,
                        )
                      ),
                      Text(
                        events[index].getTimeString(),
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
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
    );
  }

  Widget renderData() {
    Widget upcomingEventsLabel = Text(
        'Upcoming Events',
        style: TextStyle(
          fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
        )
    );
    Widget ongoingEventsLabel = Text(
        'Ongoing Events',
        style: TextStyle(
          fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
        )
    );
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          children: ongoingEvents.isNotEmpty ? (
            upcomingEvents.isNotEmpty ? (
              [
                ongoingEventsLabel,
                getEventList(ongoingEvents),
                upcomingEventsLabel,
                Expanded(child: getEventList(upcomingEvents)),
              ]
            ) : (
              [
                ongoingEventsLabel,
                getEventList(ongoingEvents),
              ]
            )
          ) : (
            upcomingEvents.isNotEmpty ? (
              [
                upcomingEventsLabel,
                Expanded(child: getEventList(upcomingEvents)),
              ]
            ) : (
              [Text(
                  'No Upcoming Events',
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                  )
              )]
            )
          ),
        )
      )
    );
  }
}