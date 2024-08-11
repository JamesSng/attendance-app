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
  List<Event> events = [];

  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  loadData() {
    final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day
    );
    widget.db.collection("events")
    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
    .orderBy('date').snapshots().listen((res) {
      List<Event> newEvents = [];
      for (var event in res.docs) {
        newEvents.add(Event(
            id: event.id,
            name: event.get('name'),
            date: event.get('date').toDate()));
      }
      setState(() {
        events = newEvents;
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

  Widget renderData() {
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