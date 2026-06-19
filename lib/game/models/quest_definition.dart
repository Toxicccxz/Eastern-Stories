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

  factory QuestDefinition.fromJson(Map<String, Object?> json) {
    return QuestDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      steps: [
        for (final step in json['steps'] as List<Object?>)
          QuestStepDefinition.fromJson(step as Map<String, Object?>),
      ],
      requiredFlags:
          (json['requiredFlags'] as List<Object?>? ?? const [])
              .cast<String>()
              .toSet(),
      rewardSilver: json['rewardSilver'] as int? ?? 0,
      rewardExperience: json['rewardExperience'] as int? ?? 0,
      rewardItemIds:
          (json['rewardItemIds'] as List<Object?>? ?? const []).cast<String>(),
    );
  }

  final String id;
  final String title;
  final String description;
  final List<QuestStepDefinition> steps;
  final Set<String> requiredFlags;
  final int rewardSilver;
  final int rewardExperience;
  final List<String> rewardItemIds;
}

enum QuestStatus { notStarted, active, completed }

enum QuestStepStatus { completed, current, pending }

class QuestStepDefinition {
  const QuestStepDefinition({required this.description, this.requiredFlag});

  factory QuestStepDefinition.fromJson(Map<String, Object?> json) {
    return QuestStepDefinition(
      description: json['description'] as String,
      requiredFlag: json['requiredFlag'] as String?,
    );
  }

  final String description;
  final String? requiredFlag;
}

class QuestStepView {
  const QuestStepView({required this.description, required this.status});

  final String description;
  final QuestStepStatus status;
}

class QuestView {
  const QuestView({
    required this.definition,
    required this.status,
    required this.isReadyToComplete,
    required this.steps,
  });

  final QuestDefinition definition;
  final QuestStatus status;
  final bool isReadyToComplete;
  final List<QuestStepView> steps;
}
