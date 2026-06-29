import 'dart:convert';
import 'dart:io';

const _categories = <String>[
  'areas',
  'rooms',
  'npcs',
  'items',
  'quests',
  'skills',
  'families',
];

Future<void> main(List<String> arguments) async {
  final manifestPath = arguments.firstOrNull ?? 'assets/data/demo_world.json';
  final validator = GameDataValidator();

  try {
    await validator.validate(manifestPath);
  } on Object catch (error) {
    stderr.writeln('Unable to validate game data: $error');
    exitCode = 2;
    return;
  }

  for (final warning in validator.warnings) {
    stdout.writeln('WARNING: $warning');
  }
  for (final error in validator.errors) {
    stderr.writeln('ERROR: $error');
  }

  final counts = _categories
      .map((category) => '$category=${validator.countFor(category)}')
      .join(', ');
  if (validator.errors.isEmpty) {
    stdout.writeln(
      'Game data is valid ($counts, warnings=${validator.warnings.length}).',
    );
    return;
  }

  stderr.writeln(
    'Game data validation failed '
    '(${validator.errors.length} errors, ${validator.warnings.length} warnings).',
  );
  exitCode = 1;
}

class GameDataValidator {
  final errors = <String>[];
  final warnings = <String>[];

  final _definitions = <String, Map<String, _Definition>>{};

  int countFor(String category) => _definitions[category]?.length ?? 0;

  Future<void> validate(String manifestPath) async {
    errors.clear();
    warnings.clear();
    _definitions.clear();

    final manifest = await _readObject(manifestPath);
    final sources = _object(manifest['sources'], '$manifestPath.sources');
    for (final category in _categories) {
      final paths = _stringList(sources[category], '$manifestPath.$category');
      _definitions[category] = await _loadCategory(category, paths);
    }

    _requireReference(
      'rooms',
      manifest['startingRoomId'],
      '$manifestPath.startingRoomId',
    );
    _validateAreas();
    _validateRooms();
    _validateNpcs();
    _validateItems();
    _validateQuests();
    _validateSkills();
    _validateFamilies();
  }

  Future<Map<String, _Definition>> _loadCategory(
    String category,
    List<String> paths,
  ) async {
    final result = <String, _Definition>{};
    for (final path in paths) {
      final entries = await _readList(path);
      for (var index = 0; index < entries.length; index++) {
        final context = '$path[$index]';
        final data = _object(entries[index], context);
        final id = data['id'];
        if (id is! String || id.trim().isEmpty) {
          errors.add('$context must have a non-empty string id.');
          continue;
        }
        final existing = result[id];
        if (existing != null) {
          errors.add(
            '$category id "$id" is duplicated in '
            '${existing.source} and $context.',
          );
          continue;
        }
        result[id] = _Definition(data, context);
      }
    }
    return result;
  }

  void _validateAreas() {
    for (final area in _all('areas')) {
      final hasRoom = _all(
        'rooms',
      ).any((room) => room.data['areaId'] == area.id);
      if (!hasRoom) {
        warnings.add('Area "${area.id}" has no rooms (${area.source}).');
      }
    }
  }

  void _validateRooms() {
    final coordinates = <String, _Definition>{};
    for (final room in _all('rooms')) {
      final context = 'room "${room.id}" (${room.source})';
      _requireReference('areas', room.data['areaId'], '$context.areaId');

      final mapX = room.data['mapX'];
      final mapY = room.data['mapY'];
      if (mapX is! int || mapY is! int) {
        errors.add('$context must have integer mapX and mapY values.');
      } else {
        final key = '${room.data['areaId']}:$mapX:$mapY';
        final existing = coordinates[key];
        if (existing != null) {
          errors.add(
            '$context overlaps room "${existing.id}" at ($mapX, $mapY).',
          );
        } else {
          coordinates[key] = room;
        }
      }

      final exits = _optionalObject(room.data['exits'], '$context.exits');
      for (final entry in exits.entries) {
        final value = entry.value;
        final target =
            value is String
                ? value
                : _object(value, '$context.exits.${entry.key}')['roomId'];
        _requireReference('rooms', target, '$context exit ${entry.key}');
        if (value is Map<String, Object?>) {
          _validateCondition(value['conditions'], '$context exit ${entry.key}');
        }
      }
      _requireReferences('npcs', room.data['npcIds'], '$context.npcIds');
      _requireReferences('items', room.data['itemIds'], '$context.itemIds');

      for (final action in _objects(room.data['actions'], '$context.actions')) {
        final actionId = action['id'] ?? '<missing id>';
        final actionContext = '$context action "$actionId"';
        _requireReference(
          'rooms',
          action['resultRoomId'],
          '$actionContext.resultRoomId',
        );
        _requireReferences(
          'items',
          action['givesItemIds'],
          '$actionContext.givesItemIds',
        );
        _validateCondition(action['conditions'], '$actionContext.conditions');
      }
    }
  }

  void _validateNpcs() {
    for (final npc in _all('npcs')) {
      final context = 'npc "${npc.id}" (${npc.source})';
      _validateCondition(npc.data['conditions'], '$context.conditions');
      _validateCondition(
        npc.data['apprenticeshipConditions'],
        '$context.apprenticeshipConditions',
      );
      _requireReference(
        'families',
        npc.data['familyId'],
        '$context.familyId',
        optional: true,
      );

      final combat = _optionalObject(npc.data['combat'], '$context.combat');
      _requireReferences(
        'items',
        combat['dropItemIds'],
        '$context.combat.dropItemIds',
      );
      final shop = _optionalObject(npc.data['shop'], '$context.shop');
      for (final product in _objects(
        shop['products'],
        '$context.shop.products',
      )) {
        _requireReference('items', product['itemId'], '$context shop product');
      }

      for (final option in _objects(
        npc.data['dialogueOptions'],
        '$context.dialogueOptions',
      )) {
        final optionContext = '$context dialogue "${option['id']}"';
        _validateCondition(option['conditions'], '$optionContext.conditions');
        _requireReference(
          'rooms',
          option['movesNpcToRoomId'],
          '$optionContext.movesNpcToRoomId',
          optional: true,
        );
        _requireReferences(
          'npcs',
          option['despawnNpcIds'],
          '$optionContext.despawnNpcIds',
        );
        for (final field in [
          'requiredQuestId',
          'startsQuestId',
          'completesQuestId',
        ]) {
          _requireReference(
            'quests',
            option[field],
            '$optionContext.$field',
            optional: true,
          );
        }
      }

      for (final option in _objects(
        npc.data['giveItemOptions'],
        '$context.giveItemOptions',
      )) {
        final optionContext = '$context give option';
        _requireReference('items', option['itemId'], '$optionContext.itemId');
        _requireReferences(
          'items',
          option['givesItemIds'],
          '$optionContext.givesItemIds',
        );
        _requireReference(
          'quests',
          option['completesQuestId'],
          '$optionContext.completesQuestId',
          optional: true,
        );
        _validateCondition(option['conditions'], '$optionContext.conditions');
      }

      for (final teaching in _objects(
        npc.data['teachingSkills'],
        '$context.teachingSkills',
      )) {
        _requireReference(
          'skills',
          teaching['skillId'],
          '$context teaching skill',
        );
        _requireMapKeys(
          'skills',
          teaching['requiredSkillLevels'],
          '$context teaching requirements',
        );
        final requiredRankId = teaching['requiredRankId'];
        if (requiredRankId != null &&
            (requiredRankId is! String ||
                !_familyRankIds().contains(requiredRankId))) {
          errors.add(
            '$context teaching skill references unknown family rank '
            '"$requiredRankId".',
          );
        }
      }
    }
  }

  void _validateItems() {
    for (final item in _all('items')) {
      final context = 'item "${item.id}" (${item.source})';
      _requireReference(
        'skills',
        item.data['studySkillId'],
        '$context.studySkillId',
        optional: true,
      );
      _validateCondition(item.data['conditions'], '$context.conditions');
    }
  }

  void _validateQuests() {
    for (final quest in _all('quests')) {
      final context = 'quest "${quest.id}" (${quest.source})';
      _requireReferences(
        'npcs',
        quest.data['requiredDefeatedNpcIds'],
        '$context.requiredDefeatedNpcIds',
      );
      _requireReferences(
        'items',
        quest.data['rewardItemIds'],
        '$context.rewardItemIds',
      );
      _requireReference(
        'families',
        quest.data['rewardFamilyId'],
        '$context.rewardFamilyId',
        optional: true,
      );
      for (final step in _objects(quest.data['steps'], '$context.steps')) {
        _requireReference(
          'npcs',
          step['requiredDefeatedNpcId'],
          '$context step.requiredDefeatedNpcId',
          optional: true,
        );
        _requireReference(
          'npcs',
          step['targetNpcId'],
          '$context step.targetNpcId',
          optional: true,
        );
        _requireReference(
          'rooms',
          step['targetRoomId'],
          '$context step.targetRoomId',
          optional: true,
        );
      }
    }
  }

  void _validateSkills() {
    for (final skill in _all('skills')) {
      final context = 'skill "${skill.id}" (${skill.source})';
      _requireMapKeys(
        'skills',
        skill.data['requiredSkillLevels'],
        '$context.requiredSkillLevels',
      );
      _requireReference(
        'families',
        skill.data['requiredFamilyId'],
        '$context.requiredFamilyId',
        optional: true,
      );
    }
  }

  void _validateFamilies() {
    final taskIds = <String>{};
    final rankIds = <String>{};
    for (final family in _all('families')) {
      final context = 'family "${family.id}" (${family.source})';
      for (final rank in _objects(family.data['ranks'], '$context.ranks')) {
        final id = rank['id'];
        if (id is String && !rankIds.add(id)) {
          errors.add('Family rank id "$id" is duplicated.');
        }
        _requireMapKeys(
          'skills',
          rank['requiredSkillLevels'],
          '$context rank "$id" requirements',
        );
      }
      for (final task in _objects(family.data['tasks'], '$context.tasks')) {
        final id = task['id'];
        if (id is String && !taskIds.add(id)) {
          errors.add('Family task id "$id" is duplicated.');
        }
        _requireReference(
          'npcs',
          task['issuerNpcId'],
          '$context task "$id" issuer',
        );
        final type = task['type'];
        final targetIds = _stringList(
          task['targetIds'],
          '$context task "$id" targetIds',
        );
        final targets =
            targetIds.isEmpty
                ? _stringList([task['targetId']], '$context task "$id" target')
                : targetIds;
        final category = switch (type) {
          'visitRoom' || 'patrolRooms' => 'rooms',
          'defeatNpc' || 'talkToNpc' => 'npcs',
          _ => null,
        };
        if (category == null) {
          errors.add('$context task "$id" has unknown type "$type".');
        } else {
          for (final target in targets) {
            _requireReference(category, target, '$context task "$id" target');
          }
        }
        _validateCondition(task['conditions'], '$context task "$id"');
      }
    }
  }

  void _validateCondition(Object? value, String context) {
    if (value == null) return;
    final condition = _object(value, context);
    _requireMapKeys(
      'quests',
      condition['requiredQuestStatuses'],
      '$context.requiredQuestStatuses',
    );
    _requireReferences(
      'npcs',
      condition['requiredDefeatedNpcIds'],
      '$context.requiredDefeatedNpcIds',
    );
    _requireReferences(
      'npcs',
      condition['forbiddenDefeatedNpcIds'],
      '$context.forbiddenDefeatedNpcIds',
    );
    _requireReference(
      'families',
      condition['requiredFamilyId'],
      '$context.requiredFamilyId',
      optional: true,
    );
    for (final rankId in _stringList(
      condition['requiredFamilyRankIds'],
      '$context.requiredFamilyRankIds',
    )) {
      if (!_familyRankIds().contains(rankId)) {
        errors.add('$context references unknown family rank "$rankId".');
      }
    }
    final familyTaskId = condition['requiredFamilyTaskId'];
    if (familyTaskId != null &&
        (familyTaskId is! String || !_familyTaskIds().contains(familyTaskId))) {
      errors.add('$context references unknown family task "$familyTaskId".');
    }
  }

  void _requireReferences(String category, Object? value, String context) {
    for (final id in _stringList(value, context)) {
      _requireReference(category, id, context);
    }
  }

  void _requireMapKeys(String category, Object? value, String context) {
    final map = _optionalObject(value, context);
    for (final id in map.keys) {
      _requireReference(category, id, context);
    }
  }

  void _requireReference(
    String category,
    Object? value,
    String context, {
    bool optional = false,
  }) {
    if (value == null && optional) return;
    if (value is! String || value.isEmpty) {
      errors.add('$context must reference a $category id.');
      return;
    }
    if (!_definitions[category]!.containsKey(value)) {
      errors.add('$context references unknown $category id "$value".');
    }
  }

  Iterable<_Definition> _all(String category) =>
      _definitions[category]?.values ?? const [];

  Set<String> _familyRankIds() => {
    for (final family in _all('families'))
      for (final rank in _objects(
        family.data['ranks'],
        'family "${family.id}" ranks',
      ))
        if (rank['id'] case final String id) id,
  };

  Set<String> _familyTaskIds() => {
    for (final family in _all('families'))
      for (final task in _objects(
        family.data['tasks'],
        'family "${family.id}" tasks',
      ))
        if (task['id'] case final String id) id,
  };
}

class _Definition {
  const _Definition(this.data, this.source);

  final Map<String, Object?> data;
  final String source;

  String get id => data['id'] as String;
}

Future<Map<String, Object?>> _readObject(String path) async {
  final value = jsonDecode(await File(path).readAsString());
  return _object(value, path);
}

Future<List<Object?>> _readList(String path) async {
  final value = jsonDecode(await File(path).readAsString());
  if (value is! List<Object?>) {
    throw FormatException('$path must contain a JSON array.');
  }
  return value;
}

Map<String, Object?> _object(Object? value, String context) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$context must be a JSON object.');
  }
  return value;
}

Map<String, Object?> _optionalObject(Object? value, String context) {
  if (value == null) return const {};
  return _object(value, context);
}

List<Map<String, Object?>> _objects(Object? value, String context) {
  if (value == null) return const [];
  if (value is! List<Object?>) {
    throw FormatException('$context must be a JSON array.');
  }
  return [
    for (var index = 0; index < value.length; index++)
      _object(value[index], '$context[$index]'),
  ];
}

List<String> _stringList(Object? value, String context) {
  if (value == null) return const [];
  if (value is! List<Object?> || value.any((item) => item is! String)) {
    throw FormatException('$context must be an array of strings.');
  }
  return value.cast<String>();
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
