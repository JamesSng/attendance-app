import 'package:flutter/material.dart';

import '../model/event.dart';
import '../model/ticket.dart';

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key, required this.eventId});

  final String eventId;

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
          eventId,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: AttendanceListView(eventId: eventId),
    );
  }
}

class AttendanceListView extends StatefulWidget {
  const AttendanceListView({super.key, required this.eventId});

  final String eventId;

  @override
  State<AttendanceListView> createState() => _AttendanceViewState();
}

// TODO: get tickets from widget.event;
List<Ticket> tickets = [
  Ticket(name: 'James', checked: true),
  Ticket(name: 'Josh', checked: false),
  Ticket(name: 'Jean', checked: false),
  Ticket(name: 'Mandy', checked: true),
];

class _AttendanceViewState extends State<AttendanceListView> {
  List<Ticket> showTickets = tickets;

  void onQueryChanged(String query) {
    setState(() {
      showTickets = tickets
        .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  child: ListTile(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    tileColor: Theme.of(context).colorScheme.primaryContainer,
                    leading: Checkbox(
                      onChanged: (bool? value) {
                        setState(() {
                          showTickets[index].checked = value!;
                        });
                      },
                      value: showTickets[index].checked,
                    ),
                    title: Text(
                      showTickets[index].name,
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