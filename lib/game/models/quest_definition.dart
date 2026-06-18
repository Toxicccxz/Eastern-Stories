class QuestDefinition {
  const QuestDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    required this.requiredFlags,
    this.rewardSilver = 0,
    this.rewardExperience = 0,
    this.rewardItemIds = const [],
  });

  final String id;
  final String title;
  final String description;
  final List<String> steps;
  final Set<String> requiredFlags;
  final int rewardSilver;
  final int rewardExperience;
  final List<String> rewardItemIds;
}

enum QuestStatus { notStarted, active, completed }

class QuestView {
  const QuestView({
    required this.definition,
    required this.status,
    required this.isReadyToComplete,
  });

  final QuestDefinition definition;
  final QuestStatus status;
  final bool isReadyToComplete;
}
