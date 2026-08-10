import 'game_state.dart';
import 'quest_definition.dart';
import 'skill_definition.dart';
import 'world_condition.dart';

class NpcDefinition {
  const NpcDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.greeting,
    this.dialogueOptions = const [],
    this.giveItemOptions = const [],
    this.greetingVariants = const [],
    this.combat,
    this.conditions,
    this.shop,
    this.intelligence = 10,
    this.teachingSkills = const [],
    this.familyId,
    this.familyGeneration,
    this.canAcceptApprentices = false,
    this.apprenticeTitle = '弟子',
    this.apprenticeshipConditions,
    this.apprenticeshipFailureMessage,
    this.patrol,
    this.ambient,
    this.entryReactions = const [],
    this.initialStateValues = const {},
    this.followEndMessage,
    this.followEndStateValues = const {},
    this.isGhost = false,
  });

  factory NpcDefinition.fromJson(Map<String, Object?> json) {
    return NpcDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      greeting: json['greeting'] as String,
      dialogueOptions: [
        for (final option
            in json['dialogueOptions'] as List<Object?>? ?? const [])
          DialogueOption.fromJson(option as Map<String, Object?>),
      ],
      giveItemOptions: [
        for (final option
            in json['giveItemOptions'] as List<Object?>? ?? const [])
          GiveItemOption.fromJson(option as Map<String, Object?>),
      ],
      greetingVariants: [
        for (final variant
            in json['greetingVariants'] as List<Object?>? ?? const [])
          GreetingVariant.fromJson(variant as Map<String, Object?>),
      ],
      combat:
          json['combat'] == null
              ? null
              : CombatDefinition.fromJson(
                json['combat'] as Map<String, Object?>,
              ),
      conditions: worldConditionFromJson(json['conditions']),
      shop:
          json['shop'] == null
              ? null
              : ShopDefinition.fromJson(json['shop'] as Map<String, Object?>),
      intelligence: json['intelligence'] as int? ?? 10,
      teachingSkills: [
        for (final teaching
            in json['teachingSkills'] as List<Object?>? ?? const [])
          TeachingSkillDefinition.fromJson(teaching as Map<String, Object?>),
      ],
      familyId: json['familyId'] as String?,
      familyGeneration: json['familyGeneration'] as int?,
      canAcceptApprentices: json['canAcceptApprentices'] as bool? ?? false,
      apprenticeTitle: json['apprenticeTitle'] as String? ?? '弟子',
      apprenticeshipConditions: worldConditionFromJson(
        json['apprenticeshipConditions'],
      ),
      apprenticeshipFailureMessage:
          json['apprenticeshipFailureMessage'] as String?,
      patrol:
          json['patrol'] == null
              ? null
              : NpcPatrolDefinition.fromJson(
                json['patrol'] as Map<String, Object?>,
              ),
      ambient:
          json['ambient'] == null
              ? null
              : NpcAmbientDefinition.fromJson(
                json['ambient'] as Map<String, Object?>,
              ),
      entryReactions: [
        for (final reaction
            in json['entryReactions'] as List<Object?>? ?? const [])
          NpcEntryReactionDefinition.fromJson(reaction as Map<String, Object?>),
      ],
      initialStateValues: _intMap(json['initialStateValues']),
      followEndMessage: json['followEndMessage'] as String?,
      followEndStateValues: _intMap(json['followEndStateValues']),
      isGhost: json['isGhost'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String description;
  final String greeting;
  final List<DialogueOption> dialogueOptions;
  final List<GiveItemOption> giveItemOptions;
  final List<GreetingVariant> greetingVariants;
  final CombatDefinition? combat;
  final WorldCondition? conditions;
  final ShopDefinition? shop;
  final int intelligence;
  final List<TeachingSkillDefinition> teachingSkills;
  final String? familyId;
  final int? familyGeneration;
  final bool canAcceptApprentices;
  final String apprenticeTitle;
  final WorldCondition? apprenticeshipConditions;
  final String? apprenticeshipFailureMessage;
  final NpcPatrolDefinition? patrol;
  final NpcAmbientDefinition? ambient;
  final List<NpcEntryReactionDefinition> entryReactions;
  final Map<String, int> initialStateValues;
  final String? followEndMessage;
  final Map<String, int> followEndStateValues;
  final bool isGhost;

  String greetingFor(GameState state) {
    for (final variant in greetingVariants) {
      if (variant.conditions.isSatisfiedBy(state)) {
        return variant.text;
      }
    }
    return greeting;
  }
}

class NpcPatrolDefinition {
  const NpcPatrolDefinition({
    required this.roomIds,
    required this.intervalTurns,
  });

  factory NpcPatrolDefinition.fromJson(Map<String, Object?> json) {
    return NpcPatrolDefinition(
      roomIds: (json['roomIds'] as List<Object?>).cast<String>(),
      intervalTurns: json['intervalTurns'] as int? ?? 1,
    );
  }

  final List<String> roomIds;
  final int intervalTurns;
}

class NpcAmbientDefinition {
  const NpcAmbientDefinition({
    required this.messages,
    required this.intervalTurns,
  });

  factory NpcAmbientDefinition.fromJson(Map<String, Object?> json) {
    return NpcAmbientDefinition(
      messages: (json['messages'] as List<Object?>).cast<String>(),
      intervalTurns: json['intervalTurns'] as int? ?? 1,
    );
  }

  final List<String> messages;
  final int intervalTurns;
}

class NpcEntryReactionDefinition {
  const NpcEntryReactionDefinition({
    required this.messages,
    this.conditions,
    this.setsFlag,
    this.startsCombat = false,
    this.requiredNpcStateValues = const {},
    this.setNpcStateValues = const {},
    this.incrementNpcStateValues = const {},
  });

  factory NpcEntryReactionDefinition.fromJson(Map<String, Object?> json) {
    return NpcEntryReactionDefinition(
      messages: (json['messages'] as List<Object?>).cast<String>(),
      conditions: worldConditionFromJson(json['conditions']),
      setsFlag: json['setsFlag'] as String?,
      startsCombat: json['startsCombat'] as bool? ?? false,
      requiredNpcStateValues: _intMap(json['requiredNpcStateValues']),
      setNpcStateValues: _intMap(json['setNpcStateValues']),
      incrementNpcStateValues: _intMap(json['incrementNpcStateValues']),
    );
  }

  final List<String> messages;
  final WorldCondition? conditions;
  final String? setsFlag;
  final bool startsCombat;
  final Map<String, int> requiredNpcStateValues;
  final Map<String, int> setNpcStateValues;
  final Map<String, int> incrementNpcStateValues;
}

class TeachingSkillDefinition {
  const TeachingSkillDefinition({
    required this.skillId,
    required this.maxLevel,
    this.access = TeachingAccess.public,
    this.requiredRankId,
    this.requiredContribution = 0,
    this.requiredSkillLevels = const {},
    this.contributionCost = 0,
    this.requiredNpcStateValues = const {},
    this.npcStateFailureMessage,
  });

  factory TeachingSkillDefinition.fromJson(Map<String, Object?> json) {
    return TeachingSkillDefinition(
      skillId: json['skillId'] as String,
      maxLevel: json['maxLevel'] as int,
      access: TeachingAccess.values.byName(
        json['access'] as String? ?? TeachingAccess.public.name,
      ),
      requiredRankId: json['requiredRankId'] as String?,
      requiredContribution: json['requiredContribution'] as int? ?? 0,
      requiredSkillLevels:
          (json['requiredSkillLevels'] as Map<String, Object?>? ?? const {})
              .map((skillId, level) => MapEntry(skillId, level as int)),
      contributionCost: json['contributionCost'] as int? ?? 0,
      requiredNpcStateValues: _intMap(json['requiredNpcStateValues']),
      npcStateFailureMessage: json['npcStateFailureMessage'] as String?,
    );
  }

  final String skillId;
  final int maxLevel;
  final TeachingAccess access;
  final String? requiredRankId;
  final int requiredContribution;
  final Map<String, int> requiredSkillLevels;
  final int contributionCost;
  final Map<String, int> requiredNpcStateValues;
  final String? npcStateFailureMessage;
}

enum TeachingAccess { public, family, direct }

class GiveItemOption {
  const GiveItemOption({
    required this.itemId,
    required this.label,
    required this.response,
    this.conditions,
    this.consumesItem = true,
    this.givesItemIds = const [],
    this.setsQuestFlag,
    this.completesQuestId,
    this.startsFollowing = false,
    this.requiredNpcStateValues = const {},
    this.setNpcStateValues = const {},
    this.incrementNpcStateValues = const {},
  });

  factory GiveItemOption.fromJson(Map<String, Object?> json) {
    return GiveItemOption(
      itemId: json['itemId'] as String,
      label: json['label'] as String,
      response: json['response'] as String,
      conditions: worldConditionFromJson(json['conditions']),
      consumesItem: json['consumesItem'] as bool? ?? true,
      givesItemIds:
          (json['givesItemIds'] as List<Object?>? ?? const []).cast<String>(),
      setsQuestFlag: json['setsQuestFlag'] as String?,
      completesQuestId: json['completesQuestId'] as String?,
      startsFollowing: json['startsFollowing'] as bool? ?? false,
      requiredNpcStateValues: _intMap(json['requiredNpcStateValues']),
      setNpcStateValues: _intMap(json['setNpcStateValues']),
      incrementNpcStateValues: _intMap(json['incrementNpcStateValues']),
    );
  }

  final String itemId;
  final String label;
  final String response;
  final WorldCondition? conditions;
  final bool consumesItem;
  final List<String> givesItemIds;
  final String? setsQuestFlag;
  final String? completesQuestId;
  final bool startsFollowing;
  final Map<String, int> requiredNpcStateValues;
  final Map<String, int> setNpcStateValues;
  final Map<String, int> incrementNpcStateValues;

  bool get acceptsAnyItem => itemId == '*';

  GiveItemOption copyWith({String? itemId, String? label}) {
    return GiveItemOption(
      itemId: itemId ?? this.itemId,
      label: label ?? this.label,
      response: response,
      conditions: conditions,
      consumesItem: consumesItem,
      givesItemIds: givesItemIds,
      setsQuestFlag: setsQuestFlag,
      completesQuestId: completesQuestId,
      startsFollowing: startsFollowing,
      requiredNpcStateValues: requiredNpcStateValues,
      setNpcStateValues: setNpcStateValues,
      incrementNpcStateValues: incrementNpcStateValues,
    );
  }
}

class ShopDefinition {
  const ShopDefinition({required this.products});

  factory ShopDefinition.fromJson(Map<String, Object?> json) {
    return ShopDefinition(
      products: [
        for (final product in json['products'] as List<Object?>)
          ShopProductDefinition.fromJson(product as Map<String, Object?>),
      ],
    );
  }

  final List<ShopProductDefinition> products;

  ShopProductDefinition? product(String itemId) {
    for (final product in products) {
      if (product.itemId == itemId) {
        return product;
      }
    }
    return null;
  }
}

class ShopProductDefinition {
  const ShopProductDefinition({
    required this.itemId,
    required this.initialStock,
  });

  factory ShopProductDefinition.fromJson(Map<String, Object?> json) {
    return ShopProductDefinition(
      itemId: json['itemId'] as String,
      initialStock: json['initialStock'] as int? ?? -1,
    );
  }

  final String itemId;
  final int initialStock;

  bool get hasInfiniteStock => initialStock < 0;
}

class GreetingVariant {
  const GreetingVariant({required this.text, required this.conditions});

  factory GreetingVariant.fromJson(Map<String, Object?> json) {
    return GreetingVariant(
      text: json['text'] as String,
      conditions: WorldCondition.fromJson(
        json['conditions'] as Map<String, Object?>,
      ),
    );
  }

  final String text;
  final WorldCondition conditions;
}

class CombatDefinition {
  const CombatDefinition({
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.maxEnergy,
    required this.maxSpirit,
    required this.maxMana,
    this.combatExperience = 0,
    this.rewardSilver = 0,
    this.rewardExperience = 0,
    this.dropItemIds = const [],
    this.respawnAfterTurns,
    this.specialMove,
  });

  factory CombatDefinition.fromJson(Map<String, Object?> json) {
    final maxHp = json['maxHp'] as int;
    return CombatDefinition(
      maxHp: maxHp,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      maxEnergy: json['maxEnergy'] as int? ?? maxHp,
      maxSpirit: json['maxSpirit'] as int? ?? maxHp,
      maxMana: json['maxMana'] as int? ?? 0,
      combatExperience: json['combatExperience'] as int? ?? 0,
      rewardSilver: json['rewardSilver'] as int? ?? 0,
      rewardExperience: json['rewardExperience'] as int? ?? 0,
      dropItemIds:
          (json['dropItemIds'] as List<Object?>? ?? const []).cast<String>(),
      respawnAfterTurns:
          (json['respawnAfterTurns'] ?? json['respawnAfterMoves']) as int?,
      specialMove:
          json['specialMove'] == null
              ? null
              : EnemyMoveDefinition.fromJson(
                json['specialMove'] as Map<String, Object?>,
              ),
    );
  }

  final int maxHp;
  final int attack;
  final int defense;
  final int maxEnergy;
  final int maxSpirit;
  final int maxMana;
  final int combatExperience;
  final int rewardSilver;
  final int rewardExperience;
  final List<String> dropItemIds;
  final int? respawnAfterTurns;
  final EnemyMoveDefinition? specialMove;
}

class EnemyMoveDefinition {
  const EnemyMoveDefinition({
    required this.name,
    required this.interval,
    required this.damageBonus,
    required this.message,
    this.statusEffectId,
    this.statusEffect,
  });

  factory EnemyMoveDefinition.fromJson(Map<String, Object?> json) {
    return EnemyMoveDefinition(
      name: json['name'] as String,
      interval: json['interval'] as int,
      damageBonus: json['damageBonus'] as int? ?? 0,
      message: json['message'] as String,
      statusEffectId: json['statusEffectId'] as String?,
      statusEffect:
          json['statusEffect'] == null
              ? null
              : StatusEffectDefinition.fromJson(
                json['statusEffect'] as Map<String, Object?>,
              ),
    );
  }

  final String name;
  final int interval;
  final int damageBonus;
  final String message;
  final String? statusEffectId;
  final StatusEffectDefinition? statusEffect;
}

class DialogueOption {
  const DialogueOption({
    required this.id,
    required this.label,
    required this.response,
    this.requiredQuestId,
    this.requiredQuestStatus,
    this.startsQuestId,
    this.setsQuestFlag,
    this.completesQuestId,
    this.movesNpcToRoomId,
    this.conditions,
    this.startsFollowing = false,
    this.despawnNpcIds = const [],
    this.requiredNpcStateValues = const {},
    this.setNpcStateValues = const {},
    this.incrementNpcStateValues = const {},
    this.silverCost = 0,
    this.insufficientSilverResponse,
    this.followingDurationTurns,
    this.givesItemIds = const [],
  });

  factory DialogueOption.fromJson(Map<String, Object?> json) {
    final questStatus = json['requiredQuestStatus'] as String?;
    return DialogueOption(
      id: json['id'] as String,
      label: json['label'] as String,
      response: json['response'] as String,
      requiredQuestId: json['requiredQuestId'] as String?,
      requiredQuestStatus:
          questStatus == null ? null : QuestStatus.values.byName(questStatus),
      startsQuestId: json['startsQuestId'] as String?,
      setsQuestFlag: json['setsQuestFlag'] as String?,
      completesQuestId: json['completesQuestId'] as String?,
      movesNpcToRoomId: json['movesNpcToRoomId'] as String?,
      conditions: worldConditionFromJson(json['conditions']),
      startsFollowing: json['startsFollowing'] as bool? ?? false,
      despawnNpcIds:
          (json['despawnNpcIds'] as List<Object?>? ?? const []).cast<String>(),
      requiredNpcStateValues: _intMap(json['requiredNpcStateValues']),
      setNpcStateValues: _intMap(json['setNpcStateValues']),
      incrementNpcStateValues: _intMap(json['incrementNpcStateValues']),
      silverCost: json['silverCost'] as int? ?? 0,
      insufficientSilverResponse: json['insufficientSilverResponse'] as String?,
      followingDurationTurns: json['followingDurationTurns'] as int?,
      givesItemIds:
          (json['givesItemIds'] as List<Object?>? ?? const []).cast<String>(),
    );
  }

  final String id;
  final String label;
  final String response;
  final String? requiredQuestId;
  final QuestStatus? requiredQuestStatus;
  final String? startsQuestId;
  final String? setsQuestFlag;
  final String? completesQuestId;
  final String? movesNpcToRoomId;
  final WorldCondition? conditions;
  final bool startsFollowing;
  final List<String> despawnNpcIds;
  final Map<String, int> requiredNpcStateValues;
  final Map<String, int> setNpcStateValues;
  final Map<String, int> incrementNpcStateValues;
  final int silverCost;
  final String? insufficientSilverResponse;
  final int? followingDurationTurns;
  final List<String> givesItemIds;
}

Map<String, int> _intMap(Object? value) {
  return (value as Map<String, Object?>? ?? const {}).map(
    (key, value) => MapEntry(key, value as int),
  );
}
