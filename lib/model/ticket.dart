class Ticket {
  Ticket({
    required this.id, required this.name, this.checked = false, required this.regular, this.hidden = false,
  });

  String id, name;
  bool checked, regular, hidden;

  Ticket copy() {
    return Ticket(id: id, name: name, checked: checked, regular: regular, hidden: hidden);
  }

  @override
  String toString() {
    return "{name: $name, regular: $regular, hidden: $hidden}";
  }
}