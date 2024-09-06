import 'package:attendance_app/view/ticketlistview.dart';
import 'package:attendance_app/view/ticketview.dart';
import 'package:flutter/material.dart';

import '../model/ticket.dart';

class TicketHistoryView extends StatelessWidget {
  const TicketHistoryView({super.key});

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
        "Ticket History",
        style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: TicketListView(onTicketPressed: (Ticket ticket) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TicketView(ticket: ticket)),
        );
      }),
    );
  }
}