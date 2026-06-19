import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/game_world_definition.dart';
import '../models/item_definition.dart';
import '../models/npc_definition.dart';
import '../models/quest_definition.dart';
import '../models/room_definition.dart';
import '../models/skill_definition.dart';

class GameDefinitionRepository {
  const GameDefinitionRepository({
    required this.startingRoomId,
    required Map<String, RoomDefinition> rooms,
    required Map<String, NpcDefinition> npcs,
    required Map<String, ItemDefinition> items,
    required Map<String, QuestDefinition> quests,
    required Map<String, SkillDefinition> skills,
  }) : _rooms = rooms,
       _npcs = npcs,
       _items = items,
       _quests = quests,
       _skills = skills;

  factory GameDefinitionRepository.fromWorld(GameWorldDefinition world) {
    return GameDefinitionRepository(
      startingRoomId: world.startingRoomId,
      rooms: world.rooms,
      npcs: world.npcs,
      items: world.items,
      quests: world.quests,
      skills: world.skills,
    );
  }

  factory GameDefinitionRepository.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    return GameDefinitionRepository.fromWorld(
      GameWorldDefinition.fromJson(json),
    );
  }

  static Future<GameDefinitionRepository> loadDemo({
    AssetBundle? bundle,
  }) async {
    final source = await (bundle ?? rootBundle).loadString(
      'assets/data/demo_world.json',
    );
    return GameDefinitionRepository.fromJson(source);
  }

  final String startingRoomId;
  final Map<String, RoomDefinition> _rooms;
  final Map<String, NpcDefinition> _npcs;
  final Map<String, ItemDefinition> _items;
  final Map<String, QuestDefinition> _quests;
  final Map<String, SkillDefinition> _skills;

  Iterable<RoomDefinition> get rooms => _rooms.values;

  Iterable<NpcDefinition> get npcs => _npcs.values;

  Iterable<ItemDefinition> get items => _items.values;

  Iterable<QuestDefinition> get quests => _quests.values;

  Iterable<SkillDefinition> get skills => _skills.values;

  RoomDefinition room(String id) {
    final room = _rooms[id];
    if (room == null) {
      throw StateError('Unknown room id: $id');
    }
    return room;
  }

  NpcDefinition npc(String id) {
    final npc = _npcs[id];
    if (npc == null) {
      throw StateError('Unknown npc id: $id');
    }
    return npc;
  }

  ItemDefinition item(String id) {
    final item = _items[id];
    if (item == null) {
      throw StateError('Unknown item id: $id');
    }
    return item;
  }

  QuestDefinition quest(String id) {
    final quest = _quests[id];
    if (quest == null) {
      throw StateError('Unknown quest id: $id');
    }
    return quest;
  }

  SkillDefinition skill(String id) {
    final skill = _skills[id];
    if (skill == null) {
      throw StateError('Unknown skill id: $id');
    }
    return skill;
  }
}
