import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/event.dart';
import '../util/logger.dart';
import '../util/timepicker.dart';
import 'eventlistview.dart';

class EventSettingsView extends StatefulWidget {
  EventSettingsView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<EventSettingsView> createState() => _EventSettingsViewState();
}

class _EventSettingsViewState extends State<EventSettingsView> {
  late String newEventName;
  late DateTime newEventStartTime, newEventEndTime;
  late TextEditingController startTimeController, endTimeController;

  String getTimeString(DateTime date) {
    return DateFormat.yMd().add_Hm().format(date);
  }

  void createEvent(BuildContext context) {
    newEventName = "";
    newEventStartTime = newEventEndTime = DateTime.now();
    startTimeController = TextEditingController(text: getTimeString(newEventStartTime));
    endTimeController = TextEditingController(text: getTimeString(newEventEndTime));
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
                controller: startTimeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Start Time',
                ),
                onTap: () {
                  _selectStartTime(context);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
              child: TextField(
                readOnly: true,
                controller: endTimeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'End Time',
                ),
                onTap: () {
                  _selectEndTime(context);
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
          "startTime": Timestamp.fromDate(newEventStartTime),
          "endTime": Timestamp.fromDate(newEventEndTime),
        });
        Logger.createEvent(Event(
          id: "",
          name: newEventName,
          startTime: newEventStartTime,
          endTime: newEventEndTime,
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

  _selectStartTime(BuildContext context) async {
    newEventStartTime = await selectTime(context, newEventStartTime);
    startTimeController.text = getTimeString(newEventStartTime);
  }

  _selectEndTime(BuildContext context) async {
    newEventEndTime = await selectTime(context, newEventEndTime);
    endTimeController.text = getTimeString(newEventEndTime);
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
  late TextEditingController startTimeController, endTimeController;
  late Event curEvent;

  _selectStartTime(BuildContext context) async {
    curEvent.startTime = await selectTime(context, curEvent.startTime);
    startTimeController.text = curEvent.getStartTimeString();
  }

  _selectEndTime(BuildContext context) async {
    curEvent.endTime = await selectTime(context, curEvent.endTime);
    endTimeController.text = curEvent.getEndTimeString();
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
    startTimeController = TextEditingController(text: curEvent.getStartTimeString());
    endTimeController = TextEditingController(text: curEvent.getEndTimeString());
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
                      controller: startTimeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Start Time',
                      ),
                      onTap: () {
                        _selectStartTime(context);
                      },
                    )
                  ),
                  Container(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextField(
                        readOnly: true,
                        controller: endTimeController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'End Time',
                        ),
                        onTap: () {
                          _selectEndTime(context);
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
        if (original.name != curEvent.name || original.startTime != curEvent.startTime || original.endTime != curEvent.endTime) {
          db.collection("events").doc(curEvent.id).set(
              {
                "name": curEvent.name,
                "startTime": Timestamp.fromDate(curEvent.startTime),
                "endTime": Timestamp.fromDate(curEvent.endTime),
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