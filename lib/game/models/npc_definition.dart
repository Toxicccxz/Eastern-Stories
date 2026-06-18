import 'quest_definition.dart';

class NpcDefinition {
  const NpcDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.greeting,
    this.dialogueOptions = const [],
  });

  final String id;
  final String name;
  final String description;
  final String greeting;
  final List<DialogueOption> dialogueOptions;
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
