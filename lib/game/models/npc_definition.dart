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
  });

  final int maxHp;
  final int attack;
  final int defense;
  final int rewardSilver;
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

  final String id;
  final String label;
  final String response;
  final String? requiredQuestId;
  final QuestStatus? requiredQuestStatus;
  final String? startsQuestId;
  final String? setsQuestFlag;
  final String? completesQuestId;
}
