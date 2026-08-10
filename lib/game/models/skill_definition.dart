import 'equipment_slot.dart';
import 'innate_attributes.dart';

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
  whip('鞭法'),
  knowledge('学识');

  const SkillUsage(this.label);

  final String label;
}

enum SkillEffectType {
  damage,
  defend,
  heal,
  summon,
  escape,
  resourceDamage,
  selfStatus,
}

enum CombatResource { hp, energy, spirit, mana }

enum FailureRollSource { skillLevel, maxMana }

enum OpposedRollType { spellPowerVsCombatExperience }

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
    this.requiredHigherSkillIds = const [],
    this.combinedAttributeRequirement,
    this.requiredEquipmentSlot,
    this.practiceRequiredWeaponUsage,
    this.attackMessages = const [],
    this.practiceHpCost = 0,
    this.practiceInnerPowerCost = 0,
    this.requiredFamilyId,
    this.canPractice = true,
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
      requiredHigherSkillIds:
          (json['requiredHigherSkillIds'] as List<Object?>? ?? const [])
              .cast<String>(),
      combinedAttributeRequirement:
          json['combinedAttributeRequirement'] == null
              ? null
              : CombinedAttributeRequirement.fromJson(
                json['combinedAttributeRequirement'] as Map<String, Object?>,
              ),
      requiredEquipmentSlot:
          json['requiredEquipmentSlot'] == null
              ? null
              : EquipmentSlot.values.byName(
                json['requiredEquipmentSlot'] as String,
              ),
      practiceRequiredWeaponUsage:
          json['practiceRequiredWeaponUsage'] == null
              ? null
              : SkillUsage.values.byName(
                json['practiceRequiredWeaponUsage'] as String,
              ),
      attackMessages:
          (json['attackMessages'] as List<Object?>? ?? const []).cast<String>(),
      practiceHpCost: json['practiceHpCost'] as int? ?? 0,
      practiceInnerPowerCost: json['practiceInnerPowerCost'] as int? ?? 0,
      requiredFamilyId: json['requiredFamilyId'] as String?,
      canPractice: json['canPractice'] as bool? ?? true,
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
  final List<String> requiredHigherSkillIds;
  final CombinedAttributeRequirement? combinedAttributeRequirement;
  final EquipmentSlot? requiredEquipmentSlot;
  final SkillUsage? practiceRequiredWeaponUsage;
  final List<String> attackMessages;
  final int practiceHpCost;
  final int practiceInnerPowerCost;
  final String? requiredFamilyId;
  final bool canPractice;

  bool get isBasic => kind == SkillKind.basic;

  bool supports(SkillUsage usage) => usages.contains(usage);

  int damageReductionAtLevel(int level) {
    return damageReduction + level ~/ 5;
  }
}

class CombinedAttributeRequirement {
  const CombinedAttributeRequirement({
    required this.attribute,
    required this.minimum,
    required this.maxInnerPowerDivisor,
  });

  factory CombinedAttributeRequirement.fromJson(Map<String, Object?> json) {
    return CombinedAttributeRequirement(
      attribute: InnateAttribute.values.firstWhere(
        (attribute) => attribute.jsonKey == json['attribute'],
      ),
      minimum: json['minimum'] as int,
      maxInnerPowerDivisor: json['maxInnerPowerDivisor'] as int,
    );
  }

  final InnateAttribute attribute;
  final int minimum;
  final int maxInnerPowerDivisor;
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
    this.manaCost = 0,
    this.spiritCost = 0,
    this.damageBonus = 0,
    this.defenseBonus = 0,
    this.healAmount = 0,
    this.minimumSkillLevel = 1,
    this.requiredEquipmentSlot,
    this.combatMessage,
    this.statusEffectId,
    this.statusEffect,
    this.summon,
    this.summons = const [],
    this.escapeRoomId,
    this.castingSkillId,
    this.failureRollSource = FailureRollSource.skillLevel,
    this.failureRollBelow = 0,
    this.failureMessage,
    this.opposedRoll,
    this.targetResource = CombatResource.hp,
    this.resourceDamageDivisor = 20,
    this.restoresPlayerResource,
    this.usableOutsideCombat = false,
    this.durationSkillId,
    this.activeFailureMessage,
  });

  factory CombatMoveDefinition.fromJson(Map<String, Object?> json) {
    return CombatMoveDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      effectType: SkillEffectType.values.byName(
        json['effectType'] as String? ?? SkillEffectType.damage.name,
      ),
      innerPowerCost: json['innerPowerCost'] as int? ?? 0,
      manaCost: json['manaCost'] as int? ?? 0,
      spiritCost: json['spiritCost'] as int? ?? 0,
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
      statusEffectId: json['statusEffectId'] as String?,
      statusEffect:
          json['statusEffect'] == null
              ? null
              : StatusEffectDefinition.fromJson(
                json['statusEffect'] as Map<String, Object?>,
              ),
      summon:
          json['summon'] == null
              ? null
              : CombatSummonDefinition.fromJson(
                json['summon'] as Map<String, Object?>,
              ),
      summons: [
        for (final summon in json['summons'] as List<Object?>? ?? const [])
          CombatSummonDefinition.fromJson(summon as Map<String, Object?>),
      ],
      escapeRoomId: json['escapeRoomId'] as String?,
      castingSkillId: json['castingSkillId'] as String?,
      failureRollSource: FailureRollSource.values.byName(
        json['failureRollSource'] as String? ??
            FailureRollSource.skillLevel.name,
      ),
      failureRollBelow: json['failureRollBelow'] as int? ?? 0,
      failureMessage: json['failureMessage'] as String?,
      opposedRoll:
          json['opposedRoll'] == null
              ? null
              : CombatOpposedRollDefinition.fromJson(
                json['opposedRoll'] as Map<String, Object?>,
              ),
      targetResource: CombatResource.values.byName(
        json['targetResource'] as String? ?? CombatResource.hp.name,
      ),
      resourceDamageDivisor: json['resourceDamageDivisor'] as int? ?? 20,
      restoresPlayerResource:
          json['restoresPlayerResource'] == null
              ? null
              : CombatResource.values.byName(
                json['restoresPlayerResource'] as String,
              ),
      usableOutsideCombat: json['usableOutsideCombat'] as bool? ?? false,
      durationSkillId: json['durationSkillId'] as String?,
      activeFailureMessage: json['activeFailureMessage'] as String?,
    );
  }

  final String id;
  final String name;
  final SkillEffectType effectType;
  final int innerPowerCost;
  final int manaCost;
  final int spiritCost;
  final int damageBonus;
  final int defenseBonus;
  final int healAmount;
  final int minimumSkillLevel;
  final EquipmentSlot? requiredEquipmentSlot;
  final String? combatMessage;
  final String? statusEffectId;
  final StatusEffectDefinition? statusEffect;
  final CombatSummonDefinition? summon;
  final List<CombatSummonDefinition> summons;
  final String? escapeRoomId;
  final String? castingSkillId;
  final FailureRollSource failureRollSource;
  final int failureRollBelow;
  final String? failureMessage;
  final CombatOpposedRollDefinition? opposedRoll;
  final CombatResource targetResource;
  final int resourceDamageDivisor;
  final CombatResource? restoresPlayerResource;
  final bool usableOutsideCombat;
  final String? durationSkillId;
  final String? activeFailureMessage;

  bool get hasFailureRoll => failureRollBelow > 0;

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

class CombatOpposedRollDefinition {
  const CombatOpposedRollDefinition({
    required this.type,
    required this.skillId,
    required this.failureMessage,
  });

  factory CombatOpposedRollDefinition.fromJson(Map<String, Object?> json) {
    return CombatOpposedRollDefinition(
      type: OpposedRollType.values.byName(json['type'] as String),
      skillId: json['skillId'] as String,
      failureMessage: json['failureMessage'] as String,
    );
  }

  final OpposedRollType type;
  final String skillId;
  final String failureMessage;
}

class CombatSummonDefinition {
  const CombatSummonDefinition({
    required this.name,
    required this.attack,
    required this.maxHp,
    required this.defense,
    required this.summonMessage,
    required this.attackMessage,
    required this.defeatMessage,
    required this.leaveMessage,
    this.durationRounds = 0,
    this.selectionWeight = 1,
    this.nameVariants = const [],
  });

  factory CombatSummonDefinition.fromJson(Map<String, Object?> json) {
    return CombatSummonDefinition(
      name: json['name'] as String,
      attack: json['attack'] as int,
      maxHp: json['maxHp'] as int,
      defense: json['defense'] as int,
      summonMessage: json['summonMessage'] as String,
      attackMessage: json['attackMessage'] as String,
      defeatMessage: json['defeatMessage'] as String,
      leaveMessage: json['leaveMessage'] as String,
      durationRounds: json['durationRounds'] as int? ?? 0,
      selectionWeight: json['selectionWeight'] as int? ?? 1,
      nameVariants:
          (json['nameVariants'] as List<Object?>? ?? const []).cast<String>(),
    );
  }

  final String name;
  final int attack;
  final int maxHp;
  final int defense;
  final String summonMessage;
  final String attackMessage;
  final String defeatMessage;
  final String leaveMessage;
  final int durationRounds;
  final int selectionWeight;
  final List<String> nameVariants;
}

class StatusEffectDefinition {
  const StatusEffectDefinition({
    required this.id,
    required this.name,
    required this.duration,
    this.damagePerRound = 0,
    this.spiritDamagePerRound = 0,
    this.innerPowerDamagePerRound = 0,
    this.hpRecoveryPerRound = 0,
    this.attackPenalty = 0,
    this.defensePenalty = 0,
    this.blocksAction = false,
    this.grantsAstralVision = false,
    this.applicationMessage,
    this.tickMessage,
    this.expireMessage,
  });

  factory StatusEffectDefinition.fromJson(Map<String, Object?> json) {
    return StatusEffectDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      duration: json['duration'] as int,
      damagePerRound: json['damagePerRound'] as int? ?? 0,
      spiritDamagePerRound: json['spiritDamagePerRound'] as int? ?? 0,
      innerPowerDamagePerRound: json['innerPowerDamagePerRound'] as int? ?? 0,
      hpRecoveryPerRound: json['hpRecoveryPerRound'] as int? ?? 0,
      attackPenalty: json['attackPenalty'] as int? ?? 0,
      defensePenalty: json['defensePenalty'] as int? ?? 0,
      blocksAction: json['blocksAction'] as bool? ?? false,
      grantsAstralVision: json['grantsAstralVision'] as bool? ?? false,
      applicationMessage: json['applicationMessage'] as String?,
      tickMessage: json['tickMessage'] as String?,
      expireMessage: json['expireMessage'] as String?,
    );
  }

  final String id;
  final String name;
  final int duration;
  final int damagePerRound;
  final int spiritDamagePerRound;
  final int innerPowerDamagePerRound;
  final int hpRecoveryPerRound;
  final int attackPenalty;
  final int defensePenalty;
  final bool blocksAction;
  final bool grantsAstralVision;
  final String? applicationMessage;
  final String? tickMessage;
  final String? expireMessage;
}
