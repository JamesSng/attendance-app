class Ticket {
  Ticket({
    required this.id, required this.name, this.checked = false, required this.regular, this.active = true,
  });

  String id, name;
  bool checked, regular, active;

  Ticket copy() {
    return Ticket(id: id, name: name, checked: checked, regular: regular, active: active);
  }

  @override
  String toString() {
    return "{name: $name, regular: $regular, active: $active}";
  }
}