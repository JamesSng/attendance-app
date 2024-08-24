import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/event.dart';
import '../util/logger.dart';
import 'attendanceview.dart';

class EditEventView extends StatefulWidget {
  EditEventView({super.key, required this.event}) {
    original.name = event.name;
    original.date = event.date;
  }
  final Event event, original = Event(id: "", name: "", date: DateTime.now());
  final db = FirebaseFirestore.instance;

  @override
  State<EditEventView> createState() {
    return _EditEventViewState();
  }
}

class _EditEventViewState extends State<EditEventView> {
  TextEditingController dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    dateController =  TextEditingController(text: widget.event.getDateString());
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () {
            widget.db.collection("events").doc(widget.event.id).set(
              {
                "name": widget.event.name,
                "date": Timestamp.fromDate(widget.event.date),
              }
            );
            if (widget.original.name != widget.event.name || widget.original.date != widget.event.date) {
              Logger.editEvent(widget.original, widget.event);
            }
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        ),
        actions: (kDebugMode) ? [
          TextButton(
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
                  final batch = widget.db.batch();
                  widget.db.collection("events").doc(widget.event.id).collection("attendees").get().then((res) {
                    for (final doc in res.docs) {
                      batch.delete(doc.reference);
                    }
                    batch.commit();
                  });
                  widget.db.collection("events").doc(widget.event.id).delete();
                  Navigator.pop(context);
                }
              });
            },
            child: const Icon(Icons.delete),
          ),
        ] : [],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          "Editing Event",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Text(
              'Edit Details',
              style: Theme
                .of(context)
                .textTheme
                .headlineSmall,
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: TextEditingController(text: widget.event.name),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
                onChanged: (text) {
                  widget.event.name = text;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 10, bottom: 10, right: 10),
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
            const Divider(
              height: 5,
              thickness: 1,
              color: Colors.black,
            ),
            Expanded(
              child: AttendanceListView(eventId: widget.event.id, reviewMode: true),
            ),
          ]
        ),
      ),
    );
  }

  _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: widget.event.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (selectedDate != null) {
      widget.event.date = selectedDate;
      dateController.text = widget.event.getDateString();
    }
  }
}