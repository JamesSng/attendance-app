import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/event.dart';
import '../util/logger.dart';
import 'editeventview.dart';

class EventSettingsView extends StatefulWidget {
  EventSettingsView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<EventSettingsView> createState() => _EventSettingsViewState();
}

class _EventSettingsViewState extends State<EventSettingsView> {
  late String newEventName;
  late DateTime newEventDate;
  late TextEditingController dateController;

  String getDateString(DateTime date) {
    return DateFormat("dd/MM/yyyy").format(date);
  }

  void createEvent(BuildContext context) {
    newEventName = "";
    DateTime now = DateTime.now();
    newEventDate = DateTime(now.year, now.month, now.day);
    dateController = TextEditingController(text: getDateString(newEventDate));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Event"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: TextEditingController(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
                onChanged: (text) {
                  newEventName = text;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: TextField(
                readOnly: true,
                controller: dateController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Date',
                ),
                onTap: () {
                  _selectDate(context);
                },
              ),
            ),
          ]
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () { Navigator.pop(context, false); },
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () { Navigator.pop(context, true); },
          ),
        ]
      ),
    ).then((res){
      if (res) {
        var event = widget.db.collection("events").doc();
        event.set({
          "name": newEventName,
          "date": Timestamp.fromDate(newEventDate),
        });
        Logger.createEvent(Event(
          id: "",
          name: newEventName,
          date: newEventDate
        ));
        final batch = widget.db.batch();
        widget.db.collection("tickets").get().then((res) {
          for (final ticket in res.docs) {
            final ref = event.collection("attendees").doc(ticket.id);
            batch.set(ref, {"checked": false});
          }
          batch.commit();
        });
      }
    });
  }

  _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: newEventDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (selectedDate != null) {
      newEventDate = selectedDate;
      dateController.text = getDateString(newEventDate);
    }
  }

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
          "Manage Events",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          createEvent(context);
        },
      ),
      body: EventListView(),
    );
  }
}

class EventListView extends StatefulWidget {
  EventListView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  bool loading = true;
  List<Event> events = [];

  loadData() {
    widget.db.collection("events").orderBy('date', descending: true).snapshots().listen((res) {
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
                        MaterialPageRoute(builder: (context) => EditEventView(event: events[index])),
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