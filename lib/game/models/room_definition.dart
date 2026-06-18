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

  List<String> visibleItemIds(GameState state) {
    return state.roomItemOverrides[id] ?? itemIds;
  }
}
