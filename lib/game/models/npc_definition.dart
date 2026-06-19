import 'quest_definition.dart';

class NpcDefinition {
  const NpcDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.greeting,
    this.dialogueOptions = const [],
    this.combat,
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
      combat:
          json['combat'] == null
              ? null
              : CombatDefinition.fromJson(
                json['combat'] as Map<String, Object?>,
              ),
    );
  }

  final String id;
  final String name;
  final String description;
  final String greeting;
  final List<DialogueOption> dialogueOptions;
  final CombatDefinition? combat;
}

class CombatDefinition {
  const CombatDefinition({
    required this.maxHp,
    required this.attack,
    required this.defense,
    this.rewardSilver = 0,
    this.rewardExperience = 0,
  });

  factory CombatDefinition.fromJson(Map<String, Object?> json) {
    return CombatDefinition(
      maxHp: json['maxHp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      rewardSilver: json['rewardSilver'] as int? ?? 0,
      rewardExperience: json['rewardExperience'] as int? ?? 0,
    );
  }

  final int maxHp;
  final int attack;
  final int defense;
  final int rewardSilver;
  final int rewardExperience;
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
}
