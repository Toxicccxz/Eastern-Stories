class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.damageReduction = 0,
  });

  final String id;
  final String name;
  final String description;
  final int damageReduction;
}
