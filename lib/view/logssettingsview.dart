import 'package:attendance_app/model/log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LogsSettingsView extends StatelessWidget {
  const LogsSettingsView({super.key});

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
          "View Logs",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: LogListView(),
    );
  }
}

class LogListView extends StatefulWidget {
  LogListView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<LogListView> {
  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  List<Log> logs = [];
  bool loading = true;

  loadData() {
    widget.db.collection("logs").orderBy('time', descending: true).snapshots().listen((res) {
      List<Log> newLogs = [];
      for (var log in res.docs) {
        newLogs.add(Log(
          log: log.get("log"),
          time: log.get("time").toDate()
        ));
      }
      setState(() {
        logs = newLogs;
        loading = false;
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
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  margin: const EdgeInsets.only(top: 5, bottom: 5),
                  child: ListTile(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    tileColor: Theme.of(context).colorScheme.primaryContainer,
                    title: Text(logs[index].log),
                    subtitle: Text(logs[index].getTimeString())
                  ),
                );
              },
            ),
          ),
        ],
      )
    );
  }
}