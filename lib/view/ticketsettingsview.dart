import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/ticket.dart';

class TicketSettingsView extends StatefulWidget {
  TicketSettingsView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<TicketSettingsView> createState() => _TicketSettingsViewState();
}

class _TicketSettingsViewState extends State<TicketSettingsView> {
  late String newTicketName;

  void createTicket(BuildContext context) {
    newTicketName = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: const Text("Create Ticket"),
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
                      newTicketName = text;
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
        var ticket = widget.db.collection("tickets").doc();
        ticket.set({
          "name": newTicketName,
        });
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
  String prevQuery = '';

  void editTicket(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: const Text("Edit Ticket"),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: TextEditingController(text: ticket.name),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Name',
                    ),
                    onChanged: (text) {
                      ticket.name = text;
                    },
                  ),
                ),
              ]
          ),
          actions: [
            TextButton(
              child: const Text("Delete"),
              onPressed: () { Navigator.pop(context, "delete"); },
            ),
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
        widget.db.collection("tickets").doc(ticket.id).set({"name": ticket.name});
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
    widget.db.collection("tickets").snapshots().listen((res) {
      List<Ticket> newTickets = [];
      for (var ticket in res.docs) {
        newTickets.add(Ticket(
            id: ticket.id,
            name: ticket.get("name"),
            checked: false,
        ));
      }

      setState(() {
        tickets = newTickets;
        loading = false;
        onQueryChanged(prevQuery);
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
                        tileColor: Theme.of(context).colorScheme.secondaryContainer,
                        title: Text(
                          showTickets[index].name,
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