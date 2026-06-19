import 'area_definition.dart';
import 'item_definition.dart';
import 'npc_definition.dart';
import 'quest_definition.dart';
import 'room_definition.dart';
import 'skill_definition.dart';

class GameWorldDefinition {
  const GameWorldDefinition({
    required this.startingRoomId,
    required this.areas,
    required this.rooms,
    required this.npcs,
    required this.items,
    required this.quests,
    required this.skills,
  });

  factory GameWorldDefinition.fromJson(Map<String, Object?> json) {
    final areas = [
      for (final value in json['areas'] as List<Object?>)
        AreaDefinition.fromJson(value as Map<String, Object?>),
    ];
    final rooms = [
      for (final value in json['rooms'] as List<Object?>)
        RoomDefinition.fromJson(value as Map<String, Object?>),
    ];
    final npcs = [
      for (final value in json['npcs'] as List<Object?>)
        NpcDefinition.fromJson(value as Map<String, Object?>),
    ];
    final items = [
      for (final value in json['items'] as List<Object?>)
        ItemDefinition.fromJson(value as Map<String, Object?>),
    ];
    final quests = [
      for (final value in json['quests'] as List<Object?>)
        QuestDefinition.fromJson(value as Map<String, Object?>),
    ];
    final skills = [
      for (final value in json['skills'] as List<Object?>)
        SkillDefinition.fromJson(value as Map<String, Object?>),
    ];

    return GameWorldDefinition(
      startingRoomId: json['startingRoomId'] as String,
      areas: {for (final area in areas) area.id: area},
      rooms: {for (final room in rooms) room.id: room},
      npcs: {for (final npc in npcs) npc.id: npc},
      items: {for (final item in items) item.id: item},
      quests: {for (final quest in quests) quest.id: quest},
      skills: {for (final skill in skills) skill.id: skill},
    );
  }

  final String startingRoomId;
  final Map<String, AreaDefinition> areas;
  final Map<String, RoomDefinition> rooms;
  final Map<String, NpcDefinition> npcs;
  final Map<String, ItemDefinition> items;
  final Map<String, QuestDefinition> quests;
  final Map<String, SkillDefinition> skills;
}
