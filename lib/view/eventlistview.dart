import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

import '../model/event.dart';

class EventListView extends StatefulWidget {
  EventListView({super.key, required this.onEventPressed});
  final db = FirebaseFirestore.instance;
  final void Function(Event event) onEventPressed;

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  late DateTime selectedMonth;
  bool init = false;

  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  bool loading = true;
  List<Event> events = [];

  loadData() {
    DateTime nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    widget.db.collection("events")
    .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedMonth), isLessThan: Timestamp.fromDate(nextMonth))
    .orderBy('startTime').snapshots().listen((res) {
      print(selectedMonth);
      List<Event> newEvents = [];
      for (var event in res.docs) {
        newEvents.add(Event(
          id: event.id,
          name: event.get('name'),
          startTime: event.get('startTime').toDate(),
          endTime: event.get('endTime').toDate()
        ));
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
      selectedMonth = DateTime(now.year, now.month);
    }
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
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                      loading = true;
                    });
                  },
                  child: const Icon(Icons.keyboard_arrow_left),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _selectMonth(context);
                    },
                    child: Text(
                      getMonthString(selectedMonth),
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                      )
                    )
                  )
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                      loading = true;
                    });
                  },
                  child: const Icon(Icons.keyboard_arrow_right),
                )
              ]
            ),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    margin: const EdgeInsets.only(top: 5, bottom: 5),
                    child: FilledButton(
                        onPressed: () {
                          widget.onEventPressed(events[index]);
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
                                            fontWeight: FontWeight.bold
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
              ),
            ),
          ],
        )
    );
  }

  String getMonthString(DateTime selectedMonth) {
    DateFormat dateFormat = DateFormat("MMMM yyyy");
    return dateFormat.format(selectedMonth);
  }

  _selectMonth(BuildContext context) async {
    DateTime? newMonth = await showMonthYearPicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (newMonth != null && selectedMonth != newMonth) {
      setState(() {
        selectedMonth = newMonth;
        loading = true;
      });
    }
  }
}