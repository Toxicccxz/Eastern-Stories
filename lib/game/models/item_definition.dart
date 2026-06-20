import 'world_condition.dart';

class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.attackPower = 0,
    this.restoreHp = 0,
    this.restoreInnerPower = 0,
    this.studySkillId,
    this.conditions,
  });

  factory ItemDefinition.fromJson(Map<String, Object?> json) {
    return ItemDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      attackPower: json['attackPower'] as int? ?? 0,
      restoreHp: json['restoreHp'] as int? ?? 0,
      restoreInnerPower: json['restoreInnerPower'] as int? ?? 0,
      studySkillId: json['studySkillId'] as String?,
      conditions: worldConditionFromJson(json['conditions']),
    );
  }

  final String id;
  final String name;
  final String description;
  final int attackPower;
  final int restoreHp;
  final int restoreInnerPower;
  final String? studySkillId;
  final WorldCondition? conditions;

  bool get canEquip => attackPower > 0;

  bool get canStudy => studySkillId != null;

  bool get canUse => restoreHp > 0 || restoreInnerPower > 0;
}
