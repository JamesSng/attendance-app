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
  AttendanceListView({super.key, required this.eventId, this.reviewMode = false});
  final String eventId;
  final bool reviewMode;
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
  int checkedNo = 0;
  Map<String, Ticket> idToTicket = {};
  List<Ticket> tickets = [], showTickets = [];

  String query = '';
  bool showRegular = true, showNonRegular = false;

  void onQueryChanged({String? newQuery, bool? newShowRegular, bool? newShowNonRegular}) {
    if (newQuery != null) query = newQuery;
    if (newShowRegular != null) showRegular = newShowRegular;
    if (newShowNonRegular != null) showNonRegular = newShowNonRegular;

    showTickets = tickets
      .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
      .where((t) => (showRegular && t.regular) || (showNonRegular && !t.regular))
      .toList();
    showTickets.sort((a, b) {
      if (a.hidden == b.hidden) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else {
        return a.hidden ? 1 : -1;
      }
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
            regular: false,
            checked: ticket.get('checked'))
        );
      }

      processData(newTickets, false, idToTicket, loadingMap);
    });

    // query for id to name
    widget.db.collection("tickets").snapshots().listen((res) {
      Map<String, Ticket> newMap = {};
      for (var ticket in res.docs) {
        newMap[ticket.id] = Ticket(
          id: ticket.id,
          name: ticket.get('name'),
          regular: ticket.get('regular'),
          hidden: ticket.get('hidden'),
        );
      }

      processData(tickets, loadingChecked, newMap, false);
    });
  }

  processData(List<Ticket> newTickets, bool newLoadingChecked, Map<String, Ticket> newIdToTicket, bool newLoadingMap) {
    int newChecked = 0;
    List<Ticket> filteredTickets = [];

    if (!newLoadingMap && !newLoadingChecked) {
      for (Ticket ticket in newTickets) {
        Ticket? newTicket = newIdToTicket[ticket.id];
        newTicket?.checked = ticket.checked;

        if (newTicket != null && (!newTicket.hidden || widget.reviewMode)) {
          filteredTickets.add(newTicket);
          if (newTicket.checked) {
            ++newChecked;
          }
        }
      }

      setState(() {
        tickets = filteredTickets;
        idToTicket = newIdToTicket;
        checkedNo = newChecked;
        loadingChecked = newLoadingChecked;
        loadingMap = newLoadingMap;
        onQueryChanged();
      });
    } else {
      setState(() {
        tickets = newTickets;
        idToTicket = newIdToTicket;
        loadingChecked = newLoadingChecked;
        loadingMap = newLoadingMap;
      });
    }
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
    return (loadingChecked && loadingMap) ? renderLoad() : ((loadingChecked || loadingMap) ? renderHalf() : renderData(context));
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

  Widget renderData(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        children: [
          Text(
            'Attendees ($checkedNo/${tickets.length})',
            style: Theme
            .of(context)
            .textTheme
            .headlineSmall,
          ),
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            child: Column(
              children: [
                TextField(
                  onChanged: (String? value) {
                    value ??= "";
                    setState(() {
                      onQueryChanged(newQuery: value);
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Search',
                  )
                ),
                Row(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width / 2 * 0.9,
                      ),
                      child: SizedBox(
                        width: 200,
                        child: CheckboxListTile(
                          title: const Text("Regular"),
                          value: showRegular,
                          onChanged: (bool? value) {
                            value ??= false;
                            setState(() {
                              onQueryChanged(newShowRegular: value);
                            });
                          }
                        )
                      )
                    ),
                    ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width / 2 * 0.9,
                        ),
                        child: SizedBox(
                            width: 200,
                            child: CheckboxListTile(
                                title: const Text("Non-regular"),
                                value: showNonRegular,
                                onChanged: (bool? value) {
                                  value ??= false;
                                  setState(() {
                                    onQueryChanged(newShowNonRegular: value);
                                  });
                                }
                            )
                        )
                    ),
                  ]
                )
              ],
            )
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
                        onChanged: widget.reviewMode ? null : (bool? value) {
                          updateChecked(index, value!);
                        },
                        value: showTickets[index].checked,
                      ),
                      title: showTickets[index].hidden ? Text(
                        "${showTickets[index].name} (hidden)",
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ) : Text(
                        showTickets[index].name,
                      ),
                      subtitle: Text(
                        showTickets[index].regular ? "Regular" : "Non-regular",
                      )
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