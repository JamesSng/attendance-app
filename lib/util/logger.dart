import 'package:attendance_app/model/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/ticket.dart';

class Logger {
  static final db = FirebaseFirestore.instance;
  static String name = "", email = "";

  static init() {
    FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        if (user == null) {
          name = "";
          email = "";
        } else {
          name = user.displayName ?? "";
          email = user.email ?? "";
        }
      }
    );
  }

  static String getDisplayName() {
    if (name == "") {
      if (email == "") {
        return "Anonymous";
      } else {
        return email;
      }
    } else {
      if (email == "") {
        return name;
      } else {
        return "$name ($email)";
      }
    }
  }

  static void createTicket(Ticket t) {
    String log =
      "${getDisplayName()} "
      "created a ticket "
      "${t.toString()}";
    db.collection("logs").doc().set(
      {
        "log": log,
        "time": Timestamp.now(),
      }
    );
  }

  static void editTicket(Ticket o, Ticket t) {
    String log =
      "${getDisplayName()} "
      "updated a ticket from "
      "${o.toString()} to ${t.toString()}";
    db.collection("logs").doc().set(
      {
        "log": log,
        "time": Timestamp.now(),
      }
    );
  }

  static void createEvent(Event e) {
    String log =
      "${getDisplayName()} "
      "created an event "
      "${e.toString()}";
    db.collection("logs").doc().set(
      {
        "log": log,
        "time": Timestamp.now(),
      }
    );
  }

  static void editEvent(Event o, Event e) {
    String log =
      "${getDisplayName()} "
      "updated an event from "
      "${o.toString()} to ${e.toString()}";
    db.collection("logs").doc().set(
      {
        "log": log,
        "time": Timestamp.now(),
      }
    );
  }
}