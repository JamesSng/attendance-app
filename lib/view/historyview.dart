import 'package:attendance_app/view/tickethistoryview.dart';
import 'package:flutter/material.dart';

import 'eventhistoryview.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

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
      return SizedBox.expand(
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
              children: [
                renderButton(context, "Event History", const Icon(Icons.event), const EventHistoryView()),
                renderButton(context, "Ticket History", const Icon(Icons.confirmation_num_outlined), const TicketHistoryView()),
              ]
          )
        ),
      );
  }
}