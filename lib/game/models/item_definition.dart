class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.attackPower = 0,
  });

  final String id;
  final String name;
  final String description;
  final int attackPower;

  bool get canEquip => attackPower > 0;
}
