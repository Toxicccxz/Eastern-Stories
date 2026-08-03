import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/validate_game_data.dart';

void main() {
  test(
    'game data validator accepts the current manifest',
    () async {
      final validator = GameDataValidator();

      await validator.validate('assets/data/demo_world.json');

      expect(validator.errors, isEmpty);
      expect(validator.countFor('areas'), 14);
      expect(validator.countFor('rooms'), 353);
      expect(validator.countFor('quests'), 4);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  test('game data validator catches enum and numeric schema errors', () async {
    final directory = await Directory.systemTemp.createTemp(
      'eastern_stories_validator_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final manifestPath = await _writeMinimalWorld(
      directory,
      rooms: [
        {
          'id': 'start',
          'name': 'Start',
          'areaId': 'test',
          'description': 'Start room',
          'mapX': 0,
          'mapY': 0,
          'exits': {'in': 'start'},
        },
        {
          'id': 'other',
          'name': 'Other',
          'areaId': 'test',
          'description': 'Other room',
          'mapX': 1,
          'mapY': 0,
          'exits': <String, Object?>{},
        },
      ],
      npcs: [
        {
          'id': 'bad_npc',
          'name': 'Bad NPC',
          'description': 'Bad NPC',
          'greeting': 'Hello',
          'initialStateValues': {'mood': 'angry'},
          'followEndStateValues': {'employed': 'no'},
          'followEndMessage': '',
          'patrol': {
            'intervalTurns': 0,
            'roomIds': ['start', 'other'],
          },
          'ambient': {'intervalTurns': 0, 'messages': <String>[]},
          'entryReactions': [
            {
              'messages': <String>[],
              'setsFlag': '',
              'startsCombat': 'yes',
              'requiredNpcStateValues': {'warned': 'yes'},
            },
          ],
          'dialogueOptions': [
            {
              'id': 'bad_payment',
              'label': 'Pay',
              'response': 'No',
              'silverCost': -1,
              'insufficientSilverResponse': '',
              'followingDurationTurns': 0,
            },
          ],
          'teachingSkills': [
            {
              'skillId': 'bad_skill',
              'maxLevel': 1,
              'requiredNpcStateValues': {'student': 'yes'},
              'npcStateFailureMessage': '',
            },
          ],
          'combat': {
            'maxHp': 0,
            'attack': 'high',
            'specialMove': {'interval': 0, 'damageBonus': 'many'},
          },
        },
      ],
      items: [
        {
          'id': 'bad_item',
          'name': 'Bad Item',
          'description': 'Bad item',
          'equipmentSlot': 'hands',
          'weaponSkillUsage': 'axe',
          'attackPower': 'strong',
        },
      ],
      skills: [
        {
          'id': 'bad_skill',
          'name': 'Bad Skill',
          'description': 'Bad skill',
          'kind': 'kungfu',
          'usages': ['axe'],
          'moves': [
            {
              'id': 'bad_move',
              'effectType': 'burst',
              'requiredEquipmentSlot': 'hands',
              'damageBonus': 'lots',
            },
          ],
        },
      ],
    );
    final validator = GameDataValidator();

    await validator.validate(manifestPath);

    expect(
      validator.errors,
      containsAll([
        contains('must be a valid direction'),
        contains('combat.maxHp must be a positive integer'),
        contains('combat.attack must be an integer'),
        contains('combat.specialMove.interval must be a positive integer'),
        contains('combat.specialMove.damageBonus must be an integer'),
        contains('patrol.intervalTurns must be a positive integer'),
        contains('does not follow a room exit'),
        contains('ambient.intervalTurns must be a positive integer'),
        contains('ambient.messages must contain non-empty text'),
        contains('entry reaction.messages must contain non-empty text'),
        contains('entry reaction.setsFlag must be non-empty text'),
        contains('entry reaction.startsCombat must be a boolean'),
        contains('initialStateValues.mood must be an integer'),
        contains('followEndStateValues.employed must be an integer'),
        contains('followEndMessage must be non-empty text'),
        contains('requiredNpcStateValues.warned must be an integer'),
        contains('silverCost must be a non-negative integer'),
        contains('insufficientSilverResponse must be non-empty text'),
        contains('followingDurationTurns must be a positive integer'),
        contains('followingDurationTurns requires startsFollowing'),
        contains('teaching requiredNpcStateValues.student must be an integer'),
        contains('teaching npcStateFailureMessage must be non-empty text'),
        contains('equipmentSlot must be a valid equipment slot'),
        contains('weaponSkillUsage must be a valid skill usage'),
        contains('attackPower must be an integer'),
        contains('kind must be a valid skill kind'),
        contains('usages must be a valid skill usage'),
        contains('effectType must be a valid skill effect type'),
        contains('requiredEquipmentSlot must be a valid equipment slot'),
        contains('damageBonus must be an integer'),
      ]),
    );
  });
}

Future<String> _writeMinimalWorld(
  Directory directory, {
  List<Map<String, Object?>> rooms = const [],
  List<Map<String, Object?>> npcs = const [],
  List<Map<String, Object?>> items = const [],
  List<Map<String, Object?>> skills = const [],
}) async {
  final files = <String, List<Map<String, Object?>>>{
    'areas': [
      {'id': 'test', 'name': 'Test', 'description': 'Test area'},
    ],
    'rooms': rooms,
    'npcs': npcs,
    'items': items,
    'quests': const [],
    'skills': skills,
    'families': const [],
  };
  final sources = <String, List<String>>{};
  for (final entry in files.entries) {
    final path = '${directory.path}/${entry.key}.json';
    await File(path).writeAsString(jsonEncode(entry.value));
    sources[entry.key] = [path];
  }

  final manifestPath = '${directory.path}/manifest.json';
  await File(
    manifestPath,
  ).writeAsString(jsonEncode({'startingRoomId': 'start', 'sources': sources}));
  return manifestPath;
}
