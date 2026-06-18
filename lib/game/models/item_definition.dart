class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.attackPower = 0,
    this.studySkillId,
  });

  final String id;
  final String name;
  final String description;
  final int attackPower;
  final String? studySkillId;

  bool get canEquip => attackPower > 0;

  bool get canStudy => studySkillId != null;
}
