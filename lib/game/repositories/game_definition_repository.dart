import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/area_definition.dart';
import '../models/game_world_definition.dart';
import '../models/item_definition.dart';
import '../models/npc_definition.dart';
import '../models/quest_definition.dart';
import '../models/room_definition.dart';
import '../models/skill_definition.dart';

class GameDefinitionRepository {
  const GameDefinitionRepository({
    required this.startingRoomId,
    required Map<String, AreaDefinition> areas,
    required Map<String, RoomDefinition> rooms,
    required Map<String, NpcDefinition> npcs,
    required Map<String, ItemDefinition> items,
    required Map<String, QuestDefinition> quests,
    required Map<String, SkillDefinition> skills,
  }) : _areas = areas,
       _rooms = rooms,
       _npcs = npcs,
       _items = items,
       _quests = quests,
       _skills = skills;

  factory GameDefinitionRepository.fromWorld(GameWorldDefinition world) {
    return GameDefinitionRepository(
      startingRoomId: world.startingRoomId,
      areas: world.areas,
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
    return loadFromManifest('assets/data/demo_world.json', bundle: bundle);
  }

  static Future<GameDefinitionRepository> loadFromManifest(
    String assetPath, {
    AssetBundle? bundle,
  }) async {
    final assetBundle = bundle ?? rootBundle;
    final manifestSource = await assetBundle.loadString(assetPath);
    final manifest = jsonDecode(manifestSource) as Map<String, Object?>;
    final sources = manifest['sources'] as Map<String, Object?>;

    final definitions = await Future.wait([
      _loadDefinitionFiles(assetBundle, sources, 'areas'),
      _loadDefinitionFiles(assetBundle, sources, 'rooms'),
      _loadDefinitionFiles(assetBundle, sources, 'npcs'),
      _loadDefinitionFiles(assetBundle, sources, 'items'),
      _loadDefinitionFiles(assetBundle, sources, 'quests'),
      _loadDefinitionFiles(assetBundle, sources, 'skills'),
    ]);

    return GameDefinitionRepository.fromWorld(
      GameWorldDefinition.fromJson({
        'startingRoomId': manifest['startingRoomId'],
        'areas': definitions[0],
        'rooms': definitions[1],
        'npcs': definitions[2],
        'items': definitions[3],
        'quests': definitions[4],
        'skills': definitions[5],
      }),
    );
  }

  final String startingRoomId;
  final Map<String, AreaDefinition> _areas;
  final Map<String, RoomDefinition> _rooms;
  final Map<String, NpcDefinition> _npcs;
  final Map<String, ItemDefinition> _items;
  final Map<String, QuestDefinition> _quests;
  final Map<String, SkillDefinition> _skills;

  Iterable<AreaDefinition> get areas => _areas.values;

  Iterable<RoomDefinition> get rooms => _rooms.values;

  Iterable<RoomDefinition> roomsInArea(String areaId) {
    return _rooms.values.where((room) => room.areaId == areaId);
  }

  Iterable<NpcDefinition> get npcs => _npcs.values;

  Iterable<ItemDefinition> get items => _items.values;

  Iterable<QuestDefinition> get quests => _quests.values;

  Iterable<SkillDefinition> get skills => _skills.values;

  AreaDefinition area(String id) {
    final area = _areas[id];
    if (area == null) {
      throw StateError('Unknown area id: $id');
    }
    return area;
  }

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

Future<List<Object?>> _loadDefinitionFiles(
  AssetBundle bundle,
  Map<String, Object?> sources,
  String category,
) async {
  final paths = (sources[category] as List<Object?>).cast<String>();
  final files = await Future.wait([
    for (final path in paths) bundle.loadString(path),
  ]);

  return [for (final source in files) ...jsonDecode(source) as List<Object?>];
}
