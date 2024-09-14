import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/user.dart';
import '../util/logger.dart';

class UserSettingsView extends StatelessWidget {
  const UserSettingsView({super.key});

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
        "Manage Users",
        style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: UserListView(),
    );
  }
}

class UserListView extends StatefulWidget {
  UserListView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  bool loading = true;
  List<User> users = [], showUsers = [];
  String query = '';

  void onQueryChanged({String? newQuery}) {
    if (newQuery != null) query = newQuery;
    showUsers = users.where((t) => (
      t.email.toLowerCase().contains(query.toLowerCase()) ||
      t.role.toLowerCase().contains(query.toLowerCase())
    )).toList();
    showUsers.sort((a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()));
  }

  loadData() {
    widget.db.collection("users").snapshots().listen((res) {
      if (!mounted) return;
      List<User> newUsers = [];
      for (var user in res.docs) {
        newUsers.add(User(
          id: user.id,
          email: user.get("email"),
          role: user.get("role"),
        ));
      }

      setState(() {
        users = newUsers;
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
    List<String> adminEntries = ["admin"];
    List<String> regularEntries = ["usher", "auditor", "disabled"];
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: TextField(
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
            ),
            Expanded(
              child: ListView.builder(
                itemCount: showUsers.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    margin: const EdgeInsets.only(top: 5, bottom: 5),
                    child: Material(
                      child: ListTile(
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        tileColor: Theme.of(context).colorScheme.secondaryContainer,
                        title: Text(
                          showUsers[index].email,
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                          )
                        ),
                        contentPadding: const EdgeInsets.all(15),
                        trailing: DropdownMenu<String>(
                          initialSelection: showUsers[index].role,
                          controller: TextEditingController(text: showUsers[index].role),
                          label: const Text("Role"),
                          enabled: showUsers[index].role != "admin",
                          onSelected: (String? newRole) {
                            if (newRole != null && newRole != showUsers[index].role) {
                              widget.db.collection("users").doc(
                                  showUsers[index].id).update({
                                "role": newRole
                              });
                              Logger.changeRole(showUsers[index].role, newRole, showUsers[index].email);
                              setState((){
                                showUsers[index].role = newRole;
                              });
                            }
                          },
                          dropdownMenuEntries: (showUsers[index].role == "admin" ? adminEntries : regularEntries)
                            .map<DropdownMenuEntry<String>>((String s) {
                              return DropdownMenuEntry<String>(
                                value: s,
                                label: s
                              );
                          }).toList(),
                        ),
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