class Ticket {
  Ticket({
    required this.id, required this.name, this.checked = false,
  });

  String id, name;
  bool checked;
}