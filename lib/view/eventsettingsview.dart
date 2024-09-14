import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/event.dart';
import '../util/logger.dart';
import 'eventlistview.dart';

class EventSettingsView extends StatefulWidget {
  EventSettingsView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<EventSettingsView> createState() => _EventSettingsViewState();
}

class _EventSettingsViewState extends State<EventSettingsView> {
  late String newEventName;
  late DateTime newEventDate;
  late TextEditingController dateController;

  String getDateString(DateTime date) {
    return DateFormat("dd/MM/yyyy").format(date);
  }

  void createEvent(BuildContext context) {
    newEventName = "";
    DateTime now = DateTime.now();
    newEventDate = DateTime(now.year, now.month, now.day);
    dateController = TextEditingController(text: getDateString(newEventDate));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Event"),
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
                  newEventName = text;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: TextField(
                readOnly: true,
                controller: dateController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Date',
                ),
                onTap: () {
                  _selectDate(context);
                },
              ),
            ),
          ]
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize
              )
            ),
            onPressed: () { Navigator.pop(context, false); },
          ),
          FilledButton(
            onPressed: () { Navigator.pop(context, true); },
            style: const ButtonStyle(
              elevation: WidgetStatePropertyAll(2),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
            ),
            child: Text(
              "Confirm",
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize
              )
            ),
          ),
        ]
      ),
    ).then((res){
      if (res) {
        var event = widget.db.collection("events").doc();
        event.set({
          "name": newEventName,
          "date": Timestamp.fromDate(newEventDate),
        });
        Logger.createEvent(Event(
          id: "",
          name: newEventName,
          date: newEventDate
        ));
        final batch = widget.db.batch();
        widget.db.collection("tickets").where("active", isEqualTo: true).get().then((res) {
          for (final ticket in res.docs) {
            final ref = event.collection("attendees").doc(ticket.id);
            batch.set(ref, {"checked": false});
          }
          batch.commit();
        });
      }
    });
  }

  _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: newEventDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (selectedDate != null) {
      newEventDate = selectedDate;
      dateController.text = getDateString(newEventDate);
    }
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
          "Manage Events",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          createEvent(context);
        },
      ),
      body: EventListView(onEventPressed: (Event event) {
        EditEventHelper().editEvent(context, event);
      }),
    );
  }
}

class EditEventHelper {
  final db = FirebaseFirestore.instance;
  late TextEditingController dateController;
  late Event curEvent;

  _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: curEvent.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (selectedDate != null) {
      curEvent.date = selectedDate;
      dateController.text = curEvent.getDateString();
    }
  }

  void editEvent(BuildContext context, Event event) {
    Widget confirmButton = FilledButton(
      style: const ButtonStyle(
        elevation: WidgetStatePropertyAll(2),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
      ),
      child: Text(
          "Confirm",
          style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize
          )
      ),
      onPressed: () { Navigator.pop(context, "confirm"); },
    );
    Widget cancelButton = TextButton(
      child: Text(
          "Cancel",
          style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize
          )
      ),
      onPressed: () { Navigator.pop(context, "cancel"); },
    );

    curEvent = event;
    Event original = curEvent.copy();
    dateController = TextEditingController(text: curEvent.getDateString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: const Text("Edit Event"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: TextEditingController(text: curEvent.name),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Name',
                    ),
                    onChanged: (text) {
                      curEvent.name = text;
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      readOnly: true,
                      controller: dateController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Date',
                      ),
                      onTap: () {
                        _selectDate(context);
                      },
                    )
                  ),
                ]
              );
            },
          ),
          actions: (kDebugMode) ? [
            TextButton(
              child: Text(
                  "Delete",
                  style: TextStyle(
                      fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize
                  )
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                      title: const Text("Delete"),
                      content: Text(
                          "Are you sure you want to delete this event?",
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                          )
                      ),
                      actions: [
                        TextButton(
                          child: Text(
                              "Cancel",
                              style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize
                              )
                          ),
                          onPressed: () { Navigator.pop(context, false); },
                        ),
                        FilledButton(
                          style: const ButtonStyle(
                            elevation: WidgetStatePropertyAll(2),
                            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                          ),
                          child: Text(
                              "Confirm",
                              style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize
                              )
                          ),
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
            cancelButton,
            confirmButton,
          ] : [
            cancelButton,
            confirmButton,
          ]
      ),
    ).then((res){
      if (res == "confirm") {
        if (original.name != curEvent.name || original.date != curEvent.date) {
          db.collection("events").doc(curEvent.id).set(
              {
                "name": curEvent.name,
                "date": Timestamp.fromDate(curEvent.date),
              }
          );
          Logger.editEvent(original, curEvent);
        }
      } else if (res == "delete") {
        final batch = db.batch();
        db.collection("events").doc(curEvent.id).collection("attendees").get().then((res) {
          for (final doc in res.docs) {
            batch.delete(doc.reference);
          }
          batch.commit();
        });
        db.collection("events").doc(curEvent.id).delete();
      }
    });
  }
}