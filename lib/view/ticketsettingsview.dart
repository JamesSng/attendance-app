import 'package:attendance_app/view/ticketlistview.dart';
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
                TextField(
                  controller: TextEditingController(text: newTicketName),
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
      body: TicketListView(onTicketPressed: (Ticket ticket) {
        EditTicketHelper().editTicket(context, ticket);
      }),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          createTicket(context);
        },
      ),
    );
  }
}

class EditTicketHelper {
  final db = FirebaseFirestore.instance;
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
        if (original.name != ticket.name || original.regular != ticket.regular || original.hidden != ticket.hidden) {
          db.collection("tickets").doc(ticket.id).set({
            "name": ticket.name,
            "regular": ticket.regular,
            "hidden": ticket.hidden,
          });
          Logger.editTicket(original, ticket);
        }
      } else if (res == "delete") {
        db.collection("tickets").doc(ticket.id).delete();

        final batch = db.batch();
        db.collection("events").get().then((res) {
          for (final event in res.docs) {
            final ref = event.reference.collection("attendees").doc(ticket.id);
            batch.delete(ref);
          }
          batch.commit();
        });
      }
    });
  }
}