import 'package:attendance_app/view/ticketlistview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/ticket.dart';
import '../util/logger.dart';
import 'widgets/app_scaffold.dart';

class TicketSettingsView extends StatefulWidget {
  TicketSettingsView({super.key});
  final db = FirebaseFirestore.instance;

  @override
  State<TicketSettingsView> createState() => _TicketSettingsViewState();
}

class _TicketSettingsViewState extends State<TicketSettingsView> {
  late String newTicketName;
  late bool newRegular, newActive;

  Future<void> _createTicket(BuildContext context) async {
    newTicketName = "";
    newRegular = true;
    newActive = true;

    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: Row(
          children: [
            const Expanded(child: Text("Create ticket")),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
        content: StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (text) => newTicketName = text,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text("Regular"),
                subtitle: const Text("Counted as part of the regular roll"),
                value: newRegular,
                onChanged: (v) => setState(() => newRegular = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text("Active"),
                subtitle: const Text(
                    "Auto-added to new events when active"),
                value: newActive,
                onChanged: (v) => setState(() => newActive = v),
              ),
            ],
          );
        }),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Create"),
            ),
          ),
        ],
      ),
    );

    if (res == true) {
      final ticket = widget.db.collection("tickets").doc();
      await ticket.set({
        "name": newTicketName,
        "regular": newRegular,
        "active": newActive,
      });
      Logger.createTicket(Ticket(
          id: "",
          name: newTicketName,
          regular: newRegular,
          active: newActive));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manage tickets',
      padded: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createTicket(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: TicketListView(onTicketPressed: (Ticket ticket) {
        EditTicketHelper().editTicket(context, ticket);
      }),
    );
  }
}

class EditTicketHelper {
  final db = FirebaseFirestore.instance;

  void editTicket(BuildContext context, Ticket ticket) {
    final original = ticket.copy();

    showDialog<String>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          title: Row(
            children: [
              const Expanded(child: Text("Edit ticket")),
              if (kDebugMode)
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  onPressed: () => _confirmDelete(context),
                ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context, "cancel"),
              ),
            ],
          ),
          content: StatefulBuilder(builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: ticket.name),
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (text) => ticket.name = text,
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Regular"),
                  value: ticket.regular,
                  onChanged: (v) => setState(() => ticket.regular = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Active"),
                  value: ticket.active,
                  onChanged: (v) => setState(() => ticket.active = v),
                ),
              ],
            );
          }),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, "confirm"),
                child: const Text("Save"),
              ),
            ),
          ],
        );
      },
    ).then((res) {
      if (res == "confirm") {
        if (original.name != ticket.name ||
            original.regular != ticket.regular ||
            original.active != ticket.active) {
          db.collection("tickets").doc(ticket.id).set({
            "name": ticket.name,
            "regular": ticket.regular,
            "active": ticket.active,
          });
          Logger.editTicket(original, ticket);
        }
      } else if (res == "delete") {
        db.collection("tickets").doc(ticket.id).delete();
        final batch = db.batch();
        db.collection("events").get().then((res) {
          for (final event in res.docs) {
            batch.delete(event.reference.collection("attendees").doc(ticket.id));
          }
          batch.commit();
        });
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete ticket"),
        content: const Text("Are you sure you want to delete this ticket?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.pop(context, "delete");
    }
  }
}
