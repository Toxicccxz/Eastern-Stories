import 'world_condition.dart';
import 'equipment_slot.dart';

class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.attackPower = 0,
    this.restoreHp = 0,
    this.restoreInnerPower = 0,
    this.studySkillId,
    this.studyMaxSkillLevel = 1,
    this.studyExperience = 0,
    this.conditions,
    this.buyPrice = 0,
    this.sellPrice = 0,
    this.equipmentSlot,
    this.defensePower = 0,
    this.maxHpBonus = 0,
    this.maxInnerPowerBonus = 0,
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
      studyMaxSkillLevel: json['studyMaxSkillLevel'] as int? ?? 1,
      studyExperience: json['studyExperience'] as int? ?? 0,
      conditions: worldConditionFromJson(json['conditions']),
      buyPrice: json['buyPrice'] as int? ?? 0,
      sellPrice: json['sellPrice'] as int? ?? 0,
      equipmentSlot: _equipmentSlot(json),
      defensePower: json['defensePower'] as int? ?? 0,
      maxHpBonus: json['maxHpBonus'] as int? ?? 0,
      maxInnerPowerBonus: json['maxInnerPowerBonus'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final String description;
  final int attackPower;
  final int restoreHp;
  final int restoreInnerPower;
  final String? studySkillId;
  final int studyMaxSkillLevel;
  final int studyExperience;
  final WorldCondition? conditions;
  final int buyPrice;
  final int sellPrice;
  final EquipmentSlot? equipmentSlot;
  final int defensePower;
  final int maxHpBonus;
  final int maxInnerPowerBonus;

  bool get canEquip => equipmentSlot != null;

  bool get canStudy => studySkillId != null;

  bool get canUse => restoreHp > 0 || restoreInnerPower > 0;
}

EquipmentSlot? _equipmentSlot(Map<String, Object?> json) {
  final slot = json['equipmentSlot'] as String?;
  if (slot != null) {
    return EquipmentSlot.values.byName(slot);
  }
  return (json['attackPower'] as int? ?? 0) > 0 ? EquipmentSlot.weapon : null;
}
