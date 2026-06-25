import 'world_condition.dart';

class FamilyDefinition {
  const FamilyDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.tasks = const [],
    this.ranks = const [],
  });

  factory FamilyDefinition.fromJson(Map<String, Object?> json) {
    return FamilyDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      tasks: [
        for (final task in json['tasks'] as List<Object?>? ?? const [])
          FamilyTaskDefinition.fromJson(task as Map<String, Object?>),
      ],
      ranks: [
        for (final rank in json['ranks'] as List<Object?>? ?? const [])
          FamilyRankDefinition.fromJson(rank as Map<String, Object?>),
      ],
    );
  }

  final String id;
  final String name;
  final String description;
  final List<FamilyTaskDefinition> tasks;
  final List<FamilyRankDefinition> ranks;

  FamilyRankDefinition? rank(String id) {
    for (final rank in ranks) {
      if (rank.id == id) {
        return rank;
      }
    }
    return null;
  }
}

enum FamilyTaskType { defeatNpc, visitRoom, talkToNpc, patrolRooms }

class FamilyTaskDefinition {
  const FamilyTaskDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.issuerNpcId,
    required this.type,
    required this.targetId,
    this.targetIds = const [],
    this.rewardExperience = 0,
    this.rewardPotential = 0,
    this.rewardContribution = 0,
    this.conditions,
  });

  factory FamilyTaskDefinition.fromJson(Map<String, Object?> json) {
    return FamilyTaskDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      issuerNpcId: json['issuerNpcId'] as String,
      type: FamilyTaskType.values.byName(json['type'] as String),
      targetId: json['targetId'] as String,
      targetIds:
          (json['targetIds'] as List<Object?>? ?? const []).cast<String>(),
      rewardExperience: json['rewardExperience'] as int? ?? 0,
      rewardPotential: json['rewardPotential'] as int? ?? 0,
      rewardContribution: json['rewardContribution'] as int? ?? 0,
      conditions: worldConditionFromJson(json['conditions']),
    );
  }

  final String id;
  final String title;
  final String description;
  final String issuerNpcId;
  final FamilyTaskType type;
  final String targetId;
  final List<String> targetIds;
  final int rewardExperience;
  final int rewardPotential;
  final int rewardContribution;
  final WorldCondition? conditions;

  List<String> get objectiveIds => targetIds.isEmpty ? [targetId] : targetIds;
}

class FamilyRankDefinition {
  const FamilyRankDefinition({
    required this.id,
    required this.title,
    this.minimumContribution = 0,
    this.minimumCompletedTasks = 0,
    this.requiredSkillLevels = const {},
  });

  factory FamilyRankDefinition.fromJson(Map<String, Object?> json) {
    return FamilyRankDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      minimumContribution: json['minimumContribution'] as int? ?? 0,
      minimumCompletedTasks: json['minimumCompletedTasks'] as int? ?? 0,
      requiredSkillLevels:
          (json['requiredSkillLevels'] as Map<String, Object?>? ?? const {})
              .map((skillId, level) => MapEntry(skillId, level as int)),
    );
  }

  final String id;
  final String title;
  final int minimumContribution;
  final int minimumCompletedTasks;
  final Map<String, int> requiredSkillLevels;
}
