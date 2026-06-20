import 'game_state.dart';
import 'quest_definition.dart';
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

  String greetingFor(GameState state) {
    for (final variant in greetingVariants) {
      if (variant.conditions.isSatisfiedBy(state)) {
        return variant.text;
      }
    }
    return greeting;
  }
}

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
    this.rewardSilver = 0,
    this.rewardExperience = 0,
    this.dropItemIds = const [],
    this.respawnAfterMoves,
    this.specialMove,
  });

  factory CombatDefinition.fromJson(Map<String, Object?> json) {
    return CombatDefinition(
      maxHp: json['maxHp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      rewardSilver: json['rewardSilver'] as int? ?? 0,
      rewardExperience: json['rewardExperience'] as int? ?? 0,
      dropItemIds:
          (json['dropItemIds'] as List<Object?>? ?? const []).cast<String>(),
      respawnAfterMoves: json['respawnAfterMoves'] as int?,
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
  final int rewardSilver;
  final int rewardExperience;
  final List<String> dropItemIds;
  final int? respawnAfterMoves;
  final EnemyMoveDefinition? specialMove;
}

class EnemyMoveDefinition {
  const EnemyMoveDefinition({
    required this.name,
    required this.interval,
    required this.damageBonus,
    required this.message,
  });

  factory EnemyMoveDefinition.fromJson(Map<String, Object?> json) {
    return EnemyMoveDefinition(
      name: json['name'] as String,
      interval: json['interval'] as int,
      damageBonus: json['damageBonus'] as int? ?? 0,
      message: json['message'] as String,
    );
  }

  final String name;
  final int interval;
  final int damageBonus;
  final String message;
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
}
