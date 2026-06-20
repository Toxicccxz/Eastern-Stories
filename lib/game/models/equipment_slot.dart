enum EquipmentSlot {
  weapon('武器'),
  head('头部'),
  body('身体'),
  feet('鞋履'),
  accessory('饰品');

  const EquipmentSlot(this.label);

  final String label;
}
