import 'package:attendance_app/view/ticketsettingsview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'eventsettingsview.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.admin});

  final bool admin;

  Widget renderButton(BuildContext context, String text, Widget page) {
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 5),
      child: FilledButton(
        onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        style: const ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.all(15)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward),
          ]
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      return SizedBox.expand(
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: admin ? Column(
              children: [
                renderButton(context, "Manage Events", EventSettingsView()),
                renderButton(context, "Manage Tickets", TicketSettingsView()),
                const Divider(
                  height: 20,
                  thickness: 1,
                  color: Colors.black,
                ),
                FilledButton(
                  onPressed: () { logout(context); },
                  style: const ButtonStyle(
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                  ),
                  child: const Text("Logout"),
                ),
              ]
          ) : Column(
              children: [
                FilledButton(
                  onPressed: () { logout(context); },
                  style: const ButtonStyle(
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                  ),
                  child: const Text("Logout"),
                ),
              ]
          ),
        ),
      );
  }

  void logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    if (!kIsWeb) GoogleSignIn().signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Goodbye!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}