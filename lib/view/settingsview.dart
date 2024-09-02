import 'package:attendance_app/view/ticketsettingsview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'eventsettingsview.dart';
import 'logssettingsview.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.role});

  final String role;

  Widget renderButton(BuildContext context, String text, Icon icon, Widget page) {
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
            Container(
              padding: const EdgeInsets.only(right: 5),
              child: icon,
            ),
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
    final Widget logoutWidget = Column(
      children: [
        Text(
          "Signed in as ${FirebaseAuth.instance.currentUser?.email} ($role)",
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        FilledButton(
          onPressed: () { logout(context); },
          style: const ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
          ),
          child: const Text("Logout"),
        ),
      ]
    );

    return SizedBox.expand(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: role == "admin" ? Column(
            children: [
              renderButton(context, "Manage Events", const Icon(Icons.event), EventSettingsView()),
              renderButton(context, "Manage Tickets", const Icon(Icons.confirmation_num_outlined), TicketSettingsView()),
              renderButton(context, "View Logs", const Icon(Icons.description_outlined), const LogsSettingsView()),
              const Divider(
                height: 20,
                thickness: 1,
                color: Colors.black,
              ),
              logoutWidget
            ]
        ) : logoutWidget
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