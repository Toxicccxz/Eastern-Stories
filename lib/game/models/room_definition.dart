import 'direction.dart';
import 'game_state.dart';

class RoomDefinition {
  const RoomDefinition({
    required this.id,
    required this.name,
    required this.areaName,
    required this.description,
    required this.mapX,
    required this.mapY,
    required this.exits,
    this.npcIds = const [],
    this.itemIds = const [],
    this.actions = const [],
  });

  factory RoomDefinition.fromJson(Map<String, Object?> json) {
    return RoomDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      areaName: json['areaName'] as String,
      description: json['description'] as String,
      mapX: json['mapX'] as int,
      mapY: json['mapY'] as int,
      exits: (json['exits'] as Map<String, Object?>).map(
        (direction, roomId) =>
            MapEntry(Direction.values.byName(direction), roomId as String),
      ),
      npcIds: _stringList(json['npcIds']),
      itemIds: _stringList(json['itemIds']),
      actions: [
        for (final action in json['actions'] as List<Object?>? ?? const [])
          RoomActionDefinition.fromJson(action as Map<String, Object?>),
      ],
    );
  }

  final String id;
  final String name;
  final String areaName;
  final String description;
  final int mapX;
  final int mapY;
  final Map<Direction, String> exits;
  final List<String> npcIds;
  final List<String> itemIds;
  final List<RoomActionDefinition> actions;

  List<String> visibleItemIds(GameState state) {
    return state.roomItemOverrides[id] ?? itemIds;
  }
}

class RoomActionDefinition {
  const RoomActionDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.resultRoomId,
    required this.log,
  });

  factory RoomActionDefinition.fromJson(Map<String, Object?> json) {
    return RoomActionDefinition(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      resultRoomId: json['resultRoomId'] as String,
      log: json['log'] as String,
    );
  }

  final String id;
  final String label;
  final String description;
  final String resultRoomId;
  final String log;
}

List<String> _stringList(Object? value) {
  return (value as List<Object?>? ?? const []).cast<String>();
}
