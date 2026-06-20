import 'equipment_slot.dart';

enum SkillKind { basic, special }

enum SkillUsage {
  unarmed('拳脚'),
  sword('剑法'),
  blade('刀法'),
  stick('棍法'),
  staff('杖法'),
  throwing('暗器'),
  force('内功'),
  parry('招架'),
  dodge('轻功'),
  magic('法术'),
  spells('咒文'),
  move('行动'),
  array('阵法'),
  whip('鞭法');

  const SkillUsage(this.label);

  final String label;
}

enum SkillEffectType { damage, defend, heal }

class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.usages,
    this.moves = const [],
    this.damageReduction = 0,
    this.maxLevel = 50,
    this.practiceExperience = 20,
    this.minimumMaxInnerPower = 0,
    this.requiredSkillLevels = const {},
    this.requiredEquipmentSlot,
    this.attackMessages = const [],
  });

  factory SkillDefinition.fromJson(Map<String, Object?> json) {
    return SkillDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      kind: SkillKind.values.byName(json['kind'] as String),
      usages: [
        for (final usage in json['usages'] as List<Object?>)
          SkillUsage.values.byName(usage as String),
      ],
      moves: [
        for (final move in json['moves'] as List<Object?>? ?? const [])
          CombatMoveDefinition.fromJson(move as Map<String, Object?>),
      ],
      damageReduction: json['damageReduction'] as int? ?? 0,
      maxLevel: json['maxLevel'] as int? ?? 50,
      practiceExperience: json['practiceExperience'] as int? ?? 20,
      minimumMaxInnerPower: json['minimumMaxInnerPower'] as int? ?? 0,
      requiredSkillLevels:
          (json['requiredSkillLevels'] as Map<String, Object?>? ?? const {})
              .map((skillId, level) => MapEntry(skillId, level as int)),
      requiredEquipmentSlot:
          json['requiredEquipmentSlot'] == null
              ? null
              : EquipmentSlot.values.byName(
                json['requiredEquipmentSlot'] as String,
              ),
      attackMessages:
          (json['attackMessages'] as List<Object?>? ?? const []).cast<String>(),
    );
  }

  final String id;
  final String name;
  final String description;
  final SkillKind kind;
  final List<SkillUsage> usages;
  final List<CombatMoveDefinition> moves;
  final int damageReduction;
  final int maxLevel;
  final int practiceExperience;
  final int minimumMaxInnerPower;
  final Map<String, int> requiredSkillLevels;
  final EquipmentSlot? requiredEquipmentSlot;
  final List<String> attackMessages;

  bool get isBasic => kind == SkillKind.basic;

  bool supports(SkillUsage usage) => usages.contains(usage);

  int damageReductionAtLevel(int level) {
    return damageReduction + level ~/ 5;
  }
}

class CombatMoveOption {
  const CombatMoveOption({required this.skill, required this.move});

  final SkillDefinition skill;
  final CombatMoveDefinition move;
}

class CombatMoveDefinition {
  const CombatMoveDefinition({
    required this.id,
    required this.name,
    required this.effectType,
    this.innerPowerCost = 0,
    this.damageBonus = 0,
    this.defenseBonus = 0,
    this.healAmount = 0,
    this.minimumSkillLevel = 1,
    this.requiredEquipmentSlot,
    this.combatMessage,
  });

  factory CombatMoveDefinition.fromJson(Map<String, Object?> json) {
    return CombatMoveDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      effectType: SkillEffectType.values.byName(
        json['effectType'] as String? ?? SkillEffectType.damage.name,
      ),
      innerPowerCost: json['innerPowerCost'] as int? ?? 0,
      damageBonus: json['damageBonus'] as int? ?? 0,
      defenseBonus: json['defenseBonus'] as int? ?? 0,
      healAmount: json['healAmount'] as int? ?? 0,
      minimumSkillLevel: json['minimumSkillLevel'] as int? ?? 1,
      requiredEquipmentSlot:
          json['requiredEquipmentSlot'] == null
              ? null
              : EquipmentSlot.values.byName(
                json['requiredEquipmentSlot'] as String,
              ),
      combatMessage: json['combatMessage'] as String?,
    );
  }

  final String id;
  final String name;
  final SkillEffectType effectType;
  final int innerPowerCost;
  final int damageBonus;
  final int defenseBonus;
  final int healAmount;
  final int minimumSkillLevel;
  final EquipmentSlot? requiredEquipmentSlot;
  final String? combatMessage;

  int damageBonusAtLevel(int level) => damageBonus + level;

  int defenseBonusAtLevel(int level) => defenseBonus + level ~/ 3;

  int healAmountAtLevel(int level) => healAmount + level * 2;

  int innerPowerCostAtLevel(int level) {
    if (innerPowerCost == 0) {
      return 0;
    }
    return (innerPowerCost - level ~/ 10).clamp(1, innerPowerCost);
  }
}
