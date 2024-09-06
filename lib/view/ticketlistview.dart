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
  bool showRegular = true, showNonRegular = true, showNonHidden = true, showHidden = false;

  void onQueryChanged({String? newQuery, bool? newShowRegular, bool? newShowNonRegular, bool? newShowNonHidden, bool? newShowHidden}) {
    if (newQuery != null) query = newQuery;
    if (newShowRegular != null) showRegular = newShowRegular;
    if (newShowNonRegular != null) showNonRegular = newShowNonRegular;
    if (newShowNonHidden != null) showNonHidden = newShowNonHidden;
    if (newShowHidden != null) showHidden = newShowHidden;
    showTickets = tickets
        .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
        .where((t) => (showRegular && t.regular) || (showNonRegular && !t.regular))
        .where((t) => (showNonHidden && !t.hidden) || (showHidden && t.hidden))
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
    widget.db.collection("tickets").snapshots().listen((res) {
      List<Ticket> newTickets = [];
      for (var ticket in res.docs) {
        newTickets.add(Ticket(
          id: ticket.id,
          name: ticket.get("name"),
          regular: ticket.get("regular"),
          hidden: ticket.get("hidden"),
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
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
                                      title: const Text("Others"),
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
                                      title: const Text("Non-hidden"),
                                      value: showNonHidden,
                                      onChanged: (bool? value) {
                                        value ??= false;
                                        setState(() {
                                          onQueryChanged(newShowNonHidden: value);
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
                                      title: const Text("Hidden"),
                                      value: showHidden,
                                      onChanged: (bool? value) {
                                        value ??= false;
                                        setState(() {
                                          onQueryChanged(newShowHidden: value);
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
                          title: showTickets[index].hidden ? Text(
                            "${showTickets[index].name} (hidden)",
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ) : Text(
                            showTickets[index].name,
                          ),
                          subtitle: Text(
                            showTickets[index].regular ? "Regular" : "Others",
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