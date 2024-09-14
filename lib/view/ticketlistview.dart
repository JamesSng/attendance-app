import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/ticket.dart';

class TicketListView extends StatefulWidget {
  TicketListView({super.key, required this.onTicketPressed});
  final db = FirebaseFirestore.instance;
  final Function(Ticket ticket) onTicketPressed;

  @override
  State<TicketListView> createState() => _TicketListViewState();
}

class _TicketListViewState extends State<TicketListView> {
  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  bool loading = true;
  List<Ticket> tickets = [], showTickets = [];
  String query = '';
  bool showRegular = true, showNonRegular = true, showActive = true, showInactive = false;

  void onQueryChanged({String? newQuery, bool? newShowRegular, bool? newShowNonRegular, bool? newShowActive, bool? newShowInactive}) {
    if (newQuery != null) query = newQuery;
    if (newShowRegular != null) showRegular = newShowRegular;
    if (newShowNonRegular != null) showNonRegular = newShowNonRegular;
    if (newShowActive != null) showActive = newShowActive;
    if (newShowInactive != null) showInactive = newShowInactive;
    showTickets = tickets
        .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
        .where((t) => (showRegular && t.regular) || (showNonRegular && !t.regular))
        .where((t) => (showActive && t.active) || (showInactive && !t.active))
        .toList();
    showTickets.sort((a, b) {
      if (a.active == b.active) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else {
        return a.active ? -1 : 1;
      }
    });
  }

  loadData() {
    widget.db.collection("tickets").snapshots().listen((res) {
      List<Ticket> newTickets = [];
      for (var ticket in res.docs) {
        newTickets.add(Ticket(
          id: ticket.id,
          name: ticket.get("name"),
          regular: ticket.get("regular"),
          active: ticket.get("active"),
          checked: false,
        ));
      }

      setState(() {
        tickets = newTickets;
        loading = false;
        onQueryChanged();
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
      margin: const EdgeInsets.all(10),
      child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: Column(
                  children: [
                    TextField(
                        onChanged: (query) {
                          setState(() {
                            onQueryChanged(newQuery: query);
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Search',
                        )
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width / 2 * 0.9,
                              ),
                              child: SizedBox(
                                  width: 200,
                                  child: CheckboxListTile(
                                      title: Text(
                                        "Regular",
                                        style: TextStyle(
                                          fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                                        )
                                      ),
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
                                      title: Text(
                                          "Others",
                                          style: TextStyle(
                                            fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                                          )
                                      ),
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
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width / 2 * 0.9,
                              ),
                              child: SizedBox(
                                  width: 200,
                                  child: CheckboxListTile(
                                      title: Text(
                                          "Active",
                                          style: TextStyle(
                                            fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                                          )
                                      ),
                                      value: showActive,
                                      onChanged: (bool? value) {
                                        value ??= false;
                                        setState(() {
                                          onQueryChanged(newShowActive: value);
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
                                      title: Text(
                                          "Inactive",
                                          style: TextStyle(
                                            fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                                          )
                                      ),
                                      value: showInactive,
                                      onChanged: (bool? value) {
                                        value ??= false;
                                        setState(() {
                                          onQueryChanged(newShowInactive: value);
                                        });
                                      }
                                  )
                              )
                          ),
                        ]
                    ),
                  ]
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
                          tileColor: Theme.of(context).colorScheme.secondaryContainer,
                          title: !showTickets[index].active ? Text(
                            "${showTickets[index].name} (inactive)",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                            ),
                          ) : Text(
                            showTickets[index].name,
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                            )
                          ),
                          subtitle: Text(
                            showTickets[index].regular ? "Regular" : "Others",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                            )
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            widget.onTicketPressed(showTickets[index]);
                          }
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