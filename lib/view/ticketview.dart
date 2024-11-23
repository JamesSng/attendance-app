import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/event.dart';
import '../model/ticket.dart';

class TicketView extends StatelessWidget {
  TicketView({super.key, required this.ticket});
  final db = FirebaseFirestore.instance;
  final Ticket ticket;

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
        ticket.name,
        style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: TicketEventView(ticket: ticket),
    );
  }
}

class TicketEventView extends StatefulWidget {
  TicketEventView({super.key, required this.ticket});
  final db = FirebaseFirestore.instance;
  final Ticket ticket;

  final DateFormat dateFormat = DateFormat("dd/MM/yyyy");

  String getDateString(DateTime date) {
    return dateFormat.format(date);
  }

  String getDateRangeString(DateTimeRange range) {
    return "${getDateString(range.start)} to ${getDateString(range.end)}";
  }

  @override
  State<TicketEventView> createState() => _TicketEventViewState();
}

class _TicketEventViewState extends State<TicketEventView> {
  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  bool init = false, loading = true;
  int loadCount = 0;
  List<Event> events = [];
  List<bool?> checked = [];
  late DateTimeRange dateTimeRange;
  late TextEditingController dateRangeController;

  _selectDateRange(BuildContext context) async {
    DateTimeRange? newRange = await showDateRangePicker(
      context: context,
      initialDateRange: dateTimeRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );

    if (newRange != null && newRange != dateTimeRange) {
      setState(() {
        loading = true;
        dateTimeRange = newRange;
      });
    }
  }

  loadData() {
    widget.db.collection("events")
    .where("startTime", isGreaterThanOrEqualTo: Timestamp.fromDate(dateTimeRange.start), isLessThanOrEqualTo: Timestamp.fromDate(dateTimeRange.end))
    .orderBy("startTime", descending: true)
    .get().then((res) {
      List<Event> newEvents = [];
      checked = List.generate(res.docs.length, (a) => false);
      loadCount = 0;

      for (int i = 0; i < res.docs.length; ++i) {
        var event = res.docs[i];
        newEvents.add(Event(
          id: event.id,
          name: event.get("name"),
          startTime: event.get('startTime').toDate(),
          endTime: event.get('endTime').toDate()
        ));
        event.reference.collection("attendees").doc(widget.ticket.id).get().then((res) {
          setState(() {
            if (res.exists) {
              checked[i] = res.get("checked");
            } else {
              checked[i] = null;
            }
            loadCount = loadCount + 1;

            if (loadCount == events.length) {
              List<Event> newEvents = [];
              List<bool> newChecked = [];

              for (int i = 0; i < events.length; ++i) {
                if (checked[i] != null) {
                  newEvents.add(events[i]);
                  newChecked.add(checked[i]!);
                }
              }

              events = newEvents;
              checked = newChecked;
              loadCount = events.length;
            }
          });
        });
      }

      setState(() {
        events = newEvents;
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!init) {
      init = true;
      DateTime now = DateTime.now();
      DateTime lowDate = DateTime(now.year, now.month - 1, now.day); // this works!
      DateTime highDate = DateTime(now.year, now.month, now.day);
      dateTimeRange = DateTimeRange(start: lowDate, end: highDate);
    }

    dateRangeController = TextEditingController(text: widget.getDateRangeString(dateTimeRange));

    return loading ? renderLoad() : (loadCount != events.length ? renderHalf() : renderData());
  }

  Widget renderLoad() {
    loadData();
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget renderHalf() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget renderData() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Text(
                "Showing Attendance",
                style: Theme.of(context).textTheme.headlineSmall
            ),
          ),
          TextField(
            readOnly: true,
            controller: dateRangeController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Range',
            ),
            onTap: () {
              _selectDateRange(context);
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  margin: const EdgeInsets.only(top: 5, bottom: 5),
                  child: Material(
                    child: ListTile(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      tileColor: Theme.of(context).colorScheme.secondaryContainer,
                      title: Text(
                        events[index].name,
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                        )
                      ),
                      subtitle: Text(
                        events[index].getTimeString(),
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                        )
                      ),
                      leading: Checkbox(value: checked[index], onChanged: (v) {}),
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