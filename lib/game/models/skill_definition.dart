import 'equipment_slot.dart';

enum SkillType { passive, active }

enum SkillEffectType { damage, defend, heal }

class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.type = SkillType.passive,
    this.effectType = SkillEffectType.damage,
    this.damageReduction = 0,
    this.moveName,
    this.innerPowerCost = 0,
    this.damageBonus = 0,
    this.defenseBonus = 0,
    this.healAmount = 0,
    this.requiredEquipmentSlot,
    this.combatMessage,
  });

  factory SkillDefinition.fromJson(Map<String, Object?> json) {
    return SkillDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: SkillType.values.byName(
        json['type'] as String? ?? SkillType.passive.name,
      ),
      effectType: SkillEffectType.values.byName(
        json['effectType'] as String? ?? SkillEffectType.damage.name,
      ),
      damageReduction: json['damageReduction'] as int? ?? 0,
      moveName: json['moveName'] as String?,
      innerPowerCost: json['innerPowerCost'] as int? ?? 0,
      damageBonus: json['damageBonus'] as int? ?? 0,
      defenseBonus: json['defenseBonus'] as int? ?? 0,
      healAmount: json['healAmount'] as int? ?? 0,
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
  final String description;
  final SkillType type;
  final SkillEffectType effectType;
  final int damageReduction;
  final String? moveName;
  final int innerPowerCost;
  final int damageBonus;
  final int defenseBonus;
  final int healAmount;
  final EquipmentSlot? requiredEquipmentSlot;
  final String? combatMessage;

  bool get isActive => type == SkillType.active;
}
