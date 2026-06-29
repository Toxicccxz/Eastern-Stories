import 'direction.dart';
import 'game_state.dart';
import 'world_condition.dart';

class RoomDefinition {
  const RoomDefinition({
    required this.id,
    required this.name,
    required this.areaId,
    required this.description,
    required this.mapX,
    required this.mapY,
    required this.exits,
    this.exitConditions = const {},
    this.npcIds = const [],
    this.itemIds = const [],
    this.actions = const [],
    this.allowsCultivation = false,
  });

  factory RoomDefinition.fromJson(Map<String, Object?> json) {
    return RoomDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      areaId: json['areaId'] as String,
      description: json['description'] as String,
      mapX: json['mapX'] as int,
      mapY: json['mapY'] as int,
      exits: _parseExits(json['exits'] as Map<String, Object?>),
      exitConditions: _parseExitConditions(
        json['exits'] as Map<String, Object?>,
      ),
      npcIds: _stringList(json['npcIds']),
      itemIds: _stringList(json['itemIds']),
      actions: [
        for (final action in json['actions'] as List<Object?>? ?? const [])
          RoomActionDefinition.fromJson(action as Map<String, Object?>),
      ],
      allowsCultivation: json['allowsCultivation'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String areaId;
  final String description;
  final int mapX;
  final int mapY;
  final Map<Direction, String> exits;
  final Map<Direction, WorldCondition> exitConditions;
  final List<String> npcIds;
  final List<String> itemIds;
  final List<RoomActionDefinition> actions;
  final bool allowsCultivation;

  List<String> visibleItemIds(GameState state) {
    return state.roomItemOverrides[id] ?? itemIds;
  }

  Map<Direction, String> availableExits(GameState state) {
    return Map.fromEntries(
      exits.entries.where(
        (entry) => exitConditions[entry.key]?.isSatisfiedBy(state) ?? true,
      ),
    );
  }

  Iterable<RoomActionDefinition> availableActions(GameState state) {
    return actions.where(
      (action) => action.conditions?.isSatisfiedBy(state) ?? true,
    );
  }
}

class RoomActionDefinition {
  const RoomActionDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.resultRoomId,
    required this.log,
    this.conditions,
    this.setsQuestFlag,
    this.givesItemIds = const [],
  });

  factory RoomActionDefinition.fromJson(Map<String, Object?> json) {
    return RoomActionDefinition(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      resultRoomId: json['resultRoomId'] as String,
      log: json['log'] as String,
      conditions: worldConditionFromJson(json['conditions']),
      setsQuestFlag: json['setsQuestFlag'] as String?,
      givesItemIds:
          (json['givesItemIds'] as List<Object?>? ?? const []).cast<String>(),
    );
  }

  final String id;
  final String label;
  final String description;
  final String resultRoomId;
  final String log;
  final WorldCondition? conditions;
  final String? setsQuestFlag;
  final List<String> givesItemIds;
}

Map<Direction, String> _parseExits(Map<String, Object?> json) {
  return json.map((direction, value) {
    final roomId =
        value is String
            ? value
            : (value as Map<String, Object?>)['roomId'] as String;
    return MapEntry(Direction.values.byName(direction), roomId);
  });
}

Map<Direction, WorldCondition> _parseExitConditions(Map<String, Object?> json) {
  final conditions = <Direction, WorldCondition>{};
  for (final entry in json.entries) {
    final value = entry.value;
    if (value is! Map<String, Object?>) {
      continue;
    }
    final condition = worldConditionFromJson(value['conditions']);
    if (condition != null) {
      conditions[Direction.values.byName(entry.key)] = condition;
    }
  }
  return conditions;
}

List<String> _stringList(Object? value) {
  return (value as List<Object?>? ?? const []).cast<String>();
}
