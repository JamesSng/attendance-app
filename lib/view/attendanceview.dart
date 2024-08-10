import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/event.dart';
import '../model/ticket.dart';

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          "${event.name} (${event.getDateString()})",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: AttendanceListView(eventId: event.id),
    );
  }
}

class AttendanceListView extends StatefulWidget {
  AttendanceListView({super.key, required this.eventId});
  final String eventId;
  final db = FirebaseFirestore.instance;

  @override
  State<AttendanceListView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceListView> {
  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  bool loadingChecked = true, loadingMap = true;
  Map<String, String> idToName = {};
  List<Ticket> tickets = [], showTickets = [];
  String prevQuery = '';

  void onQueryChanged(String query) {
    prevQuery = query;
    setState(() {
      showTickets = tickets
        .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
      showTickets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }

  loadData() {
    // query for the list of checked
    widget.db.collection("events").doc(widget.eventId).collection("attendees").snapshots().listen((res) {
      List<Ticket> newTickets = [];
      for (var ticket in res.docs) {
        newTickets.add(Ticket(
            id: ticket.id,
            name: '',
            checked: ticket.get('checked'))
        );
      }

      if (!loadingMap) {
        for (var ticket in newTickets) {
          ticket.name = idToName[ticket.id]!;
        }
      }

      setState(() {
        tickets = newTickets;
        loadingChecked = false;
        onQueryChanged(prevQuery);
      });
    });

    // query for id to name
    widget.db.collection("tickets").snapshots().listen((res) {
      Map<String, String> newMap = {};
      for (var ticket in res.docs) {
        newMap[ticket.id] = ticket.get('name');
      }

      List<Ticket> newTickets = tickets;

      if (!loadingChecked) {
        for (var ticket in newTickets) {
          ticket.name = newMap[ticket.id]!;
        }
      }

      setState(() {
        tickets = newTickets;
        idToName = newMap;
        loadingMap = false;
        onQueryChanged(prevQuery);
      });
    });
  }

  updateChecked(index, value) {
    widget.db.collection("events")
      .doc(widget.eventId)
      .collection("attendees")
      .doc(showTickets[index].id)
      .update({'checked': value});
  }

  @override
  Widget build(BuildContext context) {
    return (loadingChecked || loadingMap) ? renderLoad() : renderData();
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
            'Attendees',
            style: Theme
            .of(context)
            .textTheme
            .headlineSmall,
          ),
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            child: TextField(
              onChanged: onQueryChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search',
              )
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: showTickets.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  margin: const EdgeInsets.only(top: 5, bottom: 5),
                  child: Material(
                    child: ListTile(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      tileColor: Theme.of(context).colorScheme.primaryContainer,
                      leading: Checkbox(
                        onChanged: (bool? value) {
                          updateChecked(index, value!);
                        },
                        value: showTickets[index].checked,
                      ),
                      title: Text(
                        showTickets[index].name,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ]
      ),
    );
  }
}