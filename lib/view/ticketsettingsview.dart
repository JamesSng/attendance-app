import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/ticket.dart';
import '../util/logger.dart';

class TicketSettingsView extends StatefulWidget {
  TicketSettingsView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<TicketSettingsView> createState() => _TicketSettingsViewState();
}

class _TicketSettingsViewState extends State<TicketSettingsView> {
  late String newTicketName;
  late bool newRegular, newHidden;

  void createTicket(BuildContext context) {
    newTicketName = "";
    newRegular = true;
    newHidden = false;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Ticket"),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                          children: [
                            TextField(
                              controller: TextEditingController(),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Name',
                              ),
                              onChanged: (text) {
                                newTicketName = text;
                              },
                            ),
                            CheckboxListTile(
                                title: const Text("Regular"),
                                value: newRegular,
                                onChanged: (value) {
                                  setState(() {
                                    newRegular = value!;
                                  });
                                }
                            ),
                            CheckboxListTile(
                                title: const Text("Hidden"),
                                value: newHidden,
                                onChanged: (value) {
                                  setState(() {
                                    newHidden = value!;
                                  });
                                }
                            )
                          ]
                      )
                  ),
                ]
            );
          }
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
        var ticket = widget.db.collection("tickets").doc();
        ticket.set({
          "name": newTicketName,
          "regular": newRegular,
          "hidden": newHidden,
        });
        Logger.createTicket(Ticket(
          id: "",
          name: newTicketName,
          regular: newRegular,
          hidden: newHidden)
        );

        final batch = widget.db.batch();
        widget.db.collection("events").get().then((res) {
          for (final event in res.docs) {
            final ref = event.reference.collection("attendees").doc(ticket.id);
            batch.set(ref, {"checked": false});
          }
          batch.commit();
        });
      }
    });
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
        "Manage Tickets",
        style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: TicketListView(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          createTicket(context);
        },
      ),
    );
  }
}

class TicketListView extends StatefulWidget {
  TicketListView({super.key});
  final db = FirebaseFirestore.instance;

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

  void editTicket(BuildContext context, Ticket ticket) {
    Ticket original = ticket.copy();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Ticket"),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      TextField(
                        controller: TextEditingController(text: ticket.name),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Name',
                        ),
                        onChanged: (text) {
                          ticket.name = text;
                        },
                      ),
                      CheckboxListTile(
                        title: const Text("Regular"),
                        value: ticket.regular,
                        onChanged: (value) {
                          setState(() {
                            ticket.regular = value!;
                          });
                        }
                      ),
                      CheckboxListTile(
                        title: const Text("Hidden"),
                        value: ticket.hidden,
                        onChanged: (value) {
                          setState(() {
                            ticket.hidden = value!;
                          });
                        }
                      )
                    ]
                  )
                ),
              ]
            );
          },
        ),
        actions: (kDebugMode) ? [
          TextButton(
            child: const Text("Delete"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                    title: const Text("Delete"),
                    content: Text(
                        "Are you sure you want to delete this ticket?",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                        )
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
                  Navigator.pop(context, "delete");
                }
              });
            },
          ),
          TextButton(
            child: const Text("Cancel"),
            onPressed: () { Navigator.pop(context, "cancel"); },
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () { Navigator.pop(context, "confirm"); },
          ),
        ] : [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () { Navigator.pop(context, "cancel"); },
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () { Navigator.pop(context, "confirm"); },
          ),
        ]
      ),
    ).then((res){
      if (res == "confirm") {
        widget.db.collection("tickets").doc(ticket.id).set({
          "name": ticket.name,
          "regular": ticket.regular,
          "hidden": ticket.hidden,
        });
        if (original.name != ticket.name || original.regular != ticket.regular || original.hidden != ticket.hidden) {
          Logger.editTicket(original, ticket);
        }
      } else if (res == "delete") {
        widget.db.collection("tickets").doc(ticket.id).delete();

        final batch = widget.db.batch();
        widget.db.collection("events").get().then((res) {
          for (final event in res.docs) {
            final ref = event.reference.collection("attendees").doc(ticket.id);
            batch.delete(ref);
          }
          batch.commit();
        });
      }
    });
  }

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
            Text(
              'Tickets',
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
                          editTicket(context, showTickets[index]);
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