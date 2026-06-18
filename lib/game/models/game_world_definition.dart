import 'item_definition.dart';
import 'npc_definition.dart';
import 'quest_definition.dart';
import 'room_definition.dart';
import 'skill_definition.dart';

class GameWorldDefinition {
  const GameWorldDefinition({
    required this.startingRoomId,
    required this.rooms,
    required this.npcs,
    required this.items,
    required this.quests,
    required this.skills,
  });

  final String startingRoomId;
  final Map<String, RoomDefinition> rooms;
  final Map<String, NpcDefinition> npcs;
  final Map<String, ItemDefinition> items;
  final Map<String, QuestDefinition> quests;
  final Map<String, SkillDefinition> skills;
}
