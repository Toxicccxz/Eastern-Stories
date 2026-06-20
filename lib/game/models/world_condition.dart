import 'game_state.dart';
import 'quest_definition.dart';

class WorldCondition {
  const WorldCondition({
    this.requiredFlags = const {},
    this.forbiddenFlags = const {},
    this.requiredQuestStatuses = const {},
    this.requiredDefeatedNpcIds = const {},
    this.forbiddenDefeatedNpcIds = const {},
  });

  factory WorldCondition.fromJson(Map<String, Object?> json) {
    return WorldCondition(
      requiredFlags: _stringSet(json['requiredFlags']),
      forbiddenFlags: _stringSet(json['forbiddenFlags']),
      requiredQuestStatuses: (json['requiredQuestStatuses']
                  as Map<String, Object?>? ??
              const {})
          .map(
            (questId, status) =>
                MapEntry(questId, QuestStatus.values.byName(status as String)),
          ),
      requiredDefeatedNpcIds: _stringSet(json['requiredDefeatedNpcIds']),
      forbiddenDefeatedNpcIds: _stringSet(json['forbiddenDefeatedNpcIds']),
    );
  }

  final Set<String> requiredFlags;
  final Set<String> forbiddenFlags;
  final Map<String, QuestStatus> requiredQuestStatuses;
  final Set<String> requiredDefeatedNpcIds;
  final Set<String> forbiddenDefeatedNpcIds;

  bool isSatisfiedBy(GameState state) {
    if (!requiredFlags.every(state.questFlags.contains) ||
        forbiddenFlags.any(state.questFlags.contains)) {
      return false;
    }
    for (final entry in requiredQuestStatuses.entries) {
      final status = state.questStatuses[entry.key] ?? QuestStatus.notStarted;
      if (status != entry.value) {
        return false;
      }
    }
    if (!requiredDefeatedNpcIds.every(
      (npcId) => state.npcStates[npcId]?.isDefeated ?? false,
    )) {
      return false;
    }
    return !forbiddenDefeatedNpcIds.any(
      (npcId) => state.npcStates[npcId]?.isDefeated ?? false,
    );
  }
}

WorldCondition? worldConditionFromJson(Object? value) {
  if (value == null) {
    return null;
  }
  return WorldCondition.fromJson(value as Map<String, Object?>);
}

Set<String> _stringSet(Object? value) {
  return (value as List<Object?>? ?? const []).cast<String>().toSet();
}
