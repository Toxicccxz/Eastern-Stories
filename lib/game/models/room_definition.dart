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

  final String id;
  final String label;
  final String description;
  final String resultRoomId;
  final String log;
}
