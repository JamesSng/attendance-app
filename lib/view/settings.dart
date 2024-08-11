import 'package:attendance_app/view/ticketsettingsview.dart';
import 'package:flutter/material.dart';

import 'eventsettingsview.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

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
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        children: [
          renderButton(context, "Manage Events", EventSettingsView()),
          renderButton(context, "Manage Tickets", TicketSettingsView()),
        ]
      ),
    );
  }
}