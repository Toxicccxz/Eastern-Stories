import 'game_state.dart';
import 'quest_definition.dart';
import 'innate_attributes.dart';

class WorldCondition {
  const WorldCondition({
    this.requiredFlags = const {},
    this.forbiddenFlags = const {},
    this.requiredQuestStatuses = const {},
    this.requiredDefeatedNpcIds = const {},
    this.forbiddenDefeatedNpcIds = const {},
    this.minimumAttributes = const {},
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
      minimumAttributes:
          (json['minimumAttributes'] as Map<String, Object?>? ?? const {}).map(
            (attribute, value) => MapEntry(
              InnateAttribute.values.firstWhere(
                (candidate) => candidate.jsonKey == attribute,
              ),
              value as int,
            ),
          ),
    );
  }

  final Set<String> requiredFlags;
  final Set<String> forbiddenFlags;
  final Map<String, QuestStatus> requiredQuestStatuses;
  final Set<String> requiredDefeatedNpcIds;
  final Set<String> forbiddenDefeatedNpcIds;
  final Map<InnateAttribute, int> minimumAttributes;

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
    if (forbiddenDefeatedNpcIds.any(
      (npcId) => state.npcStates[npcId]?.isDefeated ?? false,
    )) {
      return false;
    }
    return minimumAttributes.entries.every(
      (entry) => state.player.attributes.valueFor(entry.key) >= entry.value,
    );
  }

  String? attributeFailureReason(GameState state) {
    for (final entry in minimumAttributes.entries) {
      if (state.player.attributes.valueFor(entry.key) < entry.value) {
        return '你的${entry.key.label}不足，需要达到 ${entry.value}。';
      }
    }
    return null;
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
