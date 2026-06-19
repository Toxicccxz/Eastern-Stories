class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.damageReduction = 0,
  });

  factory SkillDefinition.fromJson(Map<String, Object?> json) {
    return SkillDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      damageReduction: json['damageReduction'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final String description;
  final int damageReduction;
}
