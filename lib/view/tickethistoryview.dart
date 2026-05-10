import 'package:attendance_app/view/ticketlistview.dart';
import 'package:attendance_app/view/ticketview.dart';
import 'package:flutter/material.dart';

import '../model/ticket.dart';
import 'widgets/app_scaffold.dart';

class TicketHistoryView extends StatelessWidget {
  const TicketHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ticket history',
      padded: false,
      body: TicketListView(onTicketPressed: (Ticket ticket) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TicketView(ticket: ticket)),
        );
      }),
    );
  }
}
