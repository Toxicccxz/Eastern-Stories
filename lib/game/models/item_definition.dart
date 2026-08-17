import 'world_condition.dart';
import 'equipment_slot.dart';
import 'innate_attributes.dart';
import 'skill_definition.dart';
import 'room_definition.dart';

class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.attackPower = 0,
    this.restoreHp = 0,
    this.restoreInnerPower = 0,
    this.appliesStatusEffectId,
    this.reducesStatusEffectId,
    this.statusEffectReduction = 0,
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
    this.attributeBonuses = const {},
    this.skillBonuses = const {},
    this.weaponSkillUsage,
    this.dissolvesCorpse = false,
    this.roomUse,
    this.studyRequiredCombatExperience = 0,
    this.studySpiritCost = 10,
    this.studyDifficulty = 15,
    this.combinations = const [],
  });

  factory ItemDefinition.fromJson(Map<String, Object?> json) {
    return ItemDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      attackPower: json['attackPower'] as int? ?? 0,
      restoreHp: json['restoreHp'] as int? ?? 0,
      restoreInnerPower: json['restoreInnerPower'] as int? ?? 0,
      appliesStatusEffectId: json['appliesStatusEffectId'] as String?,
      reducesStatusEffectId: json['reducesStatusEffectId'] as String?,
      statusEffectReduction: json['statusEffectReduction'] as int? ?? 0,
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
      attributeBonuses:
          (json['attributeBonuses'] as Map<String, Object?>? ?? const {}).map(
            (attribute, value) => MapEntry(
              InnateAttribute.values.firstWhere(
                (candidate) => candidate.jsonKey == attribute,
              ),
              value as int,
            ),
          ),
      skillBonuses: (json['skillBonuses'] as Map<String, Object?>? ?? const {})
          .map((skillId, value) => MapEntry(skillId, value as int)),
      weaponSkillUsage:
          json['weaponSkillUsage'] == null
              ? null
              : SkillUsage.values.byName(json['weaponSkillUsage'] as String),
      dissolvesCorpse: json['dissolvesCorpse'] as bool? ?? false,
      roomUse:
          json['roomUse'] == null
              ? null
              : ItemRoomUseDefinition.fromJson(
                json['roomUse'] as Map<String, Object?>,
              ),
      studyRequiredCombatExperience:
          json['studyRequiredCombatExperience'] as int? ?? 0,
      studySpiritCost: json['studySpiritCost'] as int? ?? 10,
      studyDifficulty: json['studyDifficulty'] as int? ?? 15,
      combinations: [
        for (final combination
            in json['combinations'] as List<Object?>? ?? const [])
          ItemCombinationDefinition.fromJson(
            combination as Map<String, Object?>,
          ),
      ],
    );
  }

  final String id;
  final String name;
  final String description;
  final int attackPower;
  final int restoreHp;
  final int restoreInnerPower;
  final String? appliesStatusEffectId;
  final String? reducesStatusEffectId;
  final int statusEffectReduction;
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
  final Map<InnateAttribute, int> attributeBonuses;
  final Map<String, int> skillBonuses;
  final SkillUsage? weaponSkillUsage;
  final bool dissolvesCorpse;
  final ItemRoomUseDefinition? roomUse;
  final int studyRequiredCombatExperience;
  final int studySpiritCost;
  final int studyDifficulty;
  final List<ItemCombinationDefinition> combinations;

  bool get canEquip => equipmentSlot != null;

  bool get canStudy => studySkillId != null;

  bool get canUse =>
      restoreHp > 0 ||
      restoreInnerPower > 0 ||
      appliesStatusEffectId != null ||
      reducesStatusEffectId != null ||
      roomUse != null;
}

class ItemRoomUseDefinition {
  const ItemRoomUseDefinition({
    required this.roomId,
    required this.label,
    required this.response,
    this.unblocksExits = const [],
  });

  factory ItemRoomUseDefinition.fromJson(Map<String, Object?> json) {
    return ItemRoomUseDefinition(
      roomId: json['roomId'] as String,
      label: json['label'] as String,
      response: json['response'] as String,
      unblocksExits: [
        for (final value in json['unblocksExits'] as List<Object?>? ?? const [])
          RoomExitReference.fromJson(value as Map<String, Object?>),
      ],
    );
  }

  final String roomId;
  final String label;
  final String response;
  final List<RoomExitReference> unblocksExits;
}

class ItemCombinationDefinition {
  const ItemCombinationDefinition({
    required this.targetItemId,
    required this.label,
    required this.response,
    required this.resultItemIds,
    this.consumesSource = true,
    this.consumesTarget = true,
  });

  factory ItemCombinationDefinition.fromJson(Map<String, Object?> json) {
    return ItemCombinationDefinition(
      targetItemId: json['targetItemId'] as String,
      label: json['label'] as String,
      response: json['response'] as String,
      resultItemIds: (json['resultItemIds'] as List<Object?>).cast<String>(),
      consumesSource: json['consumesSource'] as bool? ?? true,
      consumesTarget: json['consumesTarget'] as bool? ?? true,
    );
  }

  final String targetItemId;
  final String label;
  final String response;
  final List<String> resultItemIds;
  final bool consumesSource;
  final bool consumesTarget;
}

EquipmentSlot? _equipmentSlot(Map<String, Object?> json) {
  final slot = json['equipmentSlot'] as String?;
  if (slot != null) {
    return EquipmentSlot.values.byName(slot);
  }
  return (json['attackPower'] as int? ?? 0) > 0 ? EquipmentSlot.weapon : null;
}
