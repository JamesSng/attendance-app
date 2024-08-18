class Ticket {
  Ticket({
    required this.id, required this.name, this.checked = false, required this.regular, this.hidden = false,
  });

  String id, name;
  bool checked, regular, hidden;
}