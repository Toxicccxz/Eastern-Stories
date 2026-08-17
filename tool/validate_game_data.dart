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
  'statusEffects',
];

const _playerGenders = {'male', 'female'};
const _innateAttributes = {
  'strength',
  'courage',
  'intelligence',
  'spirituality',
  'composure',
  'personality',
  'constitution',
  'karma',
};
const _directions = {
  'north',
  'south',
  'east',
  'west',
  'northeast',
  'northwest',
  'southeast',
  'southwest',
  'up',
  'down',
  'northup',
  'southup',
  'eastup',
  'westup',
  'northdown',
  'southdown',
  'eastdown',
  'westdown',
  'enter',
  'out',
};
const _equipmentSlots = {
  'weapon',
  'head',
  'body',
  'outerwear',
  'feet',
  'accessory',
};
const _skillKinds = {'basic', 'special'};
const _skillUsages = {
  'unarmed',
  'sword',
  'blade',
  'stick',
  'staff',
  'throwing',
  'force',
  'parry',
  'dodge',
  'magic',
  'spells',
  'move',
  'array',
  'whip',
  'knowledge',
};
const _skillEffectTypes = {
  'damage',
  'defend',
  'heal',
  'summon',
  'escape',
  'resourceDamage',
  'selfStatus',
  'animateCorpse',
};
const _failureRollSources = {'skillLevel', 'maxMana'};
const _opposedRollTypes = {'spellPowerVsCombatExperience'};
const _combatResources = {'hp', 'energy', 'spirit', 'mana'};
const _questStatuses = {'notStarted', 'active', 'completed'};
const _teachingAccess = {'public', 'family', 'direct'};

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
    _validateStatusEffects();
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
      _validateOptionalPositiveInt(
        area.data['resetAfterTurns'],
        'area "${area.id}".resetAfterTurns',
      );
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
      _requireReference(
        'areas',
        room.data['outdoorAreaId'],
        '$context.outdoorAreaId',
        optional: true,
      );

      final mapX = room.data['mapX'];
      final mapY = room.data['mapY'];
      final allowsCombat = room.data['allowsCombat'];
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
      if (allowsCombat != null && allowsCombat is! bool) {
        errors.add('$context.allowsCombat must be a boolean.');
      }

      final exits = _optionalObject(room.data['exits'], '$context.exits');
      for (final entry in exits.entries) {
        _validateEnum(
          entry.key,
          _directions,
          '$context.exits.${entry.key}',
          'direction',
        );
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
        for (final field in [
          'hpCost',
          'spiritCost',
          'silverCost',
          'rewardSilver',
        ]) {
          _validateOptionalInt(action[field], '$actionContext.$field');
        }
      }
      final entryEvent = _optionalObject(
        room.data['entryEvent'],
        '$context.entryEvent',
      );
      if (entryEvent.isNotEmpty) {
        _validateOptionalBool(
          entryEvent['resetsWithArea'],
          '$context.entryEvent.resetsWithArea',
        );
        if (entryEvent['resetsWithArea'] == true) {
          final areaId = room.data['areaId'];
          final area = _definitions['areas']?[areaId];
          if (area?.data['resetAfterTurns'] == null) {
            errors.add(
              '$context.entryEvent resets with area "$areaId", '
              'but that area has no resetAfterTurns.',
            );
          }
        }
        if (entryEvent['onceFlag'] case final value?
            when value is! String || value.isEmpty) {
          errors.add('$context.entryEvent.onceFlag must be non-empty text.');
        }
        if (entryEvent['log'] case final value?
            when value is! String || value.isEmpty) {
          errors.add('$context.entryEvent.log must be non-empty text.');
        }
        _requireReference(
          'rooms',
          entryEvent['previousRoomId'],
          '$context.entryEvent.previousRoomId',
          optional: true,
        );
        for (final exit in _objects(
          entryEvent['blockedExits'],
          '$context.entryEvent.blockedExits',
        )) {
          _requireReference(
            'rooms',
            exit['roomId'],
            '$context.entryEvent blocked exit roomId',
          );
          _validateEnum(
            exit['direction'],
            _directions,
            '$context.entryEvent blocked exit direction',
            'direction',
          );
        }
        for (final spawn in _objects(
          entryEvent['spawns'],
          '$context.entryEvent.spawns',
        )) {
          _requireReference(
            'npcs',
            spawn['definitionId'],
            '$context.entryEvent spawn definitionId',
          );
          _requireReference(
            'rooms',
            spawn['roomId'],
            '$context.entryEvent spawn roomId',
          );
          _validateOptionalPositiveInt(
            spawn['count'],
            '$context.entryEvent spawn count',
          );
          if (spawn['instancePrefix'] case final value?
              when value is! String || value.isEmpty) {
            errors.add(
              '$context.entryEvent spawn instancePrefix must be non-empty text.',
            );
          }
        }
      }
    }
  }

  void _validateNpcs() {
    for (final npc in _all('npcs')) {
      final context = 'npc "${npc.id}" (${npc.source})';
      _validateIntegerMap(
        npc.data['initialStateValues'],
        '$context.initialStateValues',
      );
      _validateIntegerMap(
        npc.data['followEndStateValues'],
        '$context.followEndStateValues',
      );
      if (npc.data['followEndMessage'] case final value?
          when value is! String || value.isEmpty) {
        errors.add('$context.followEndMessage must be non-empty text.');
      }
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
      _validateOptionalBool(npc.data['isGhost'], '$context.isGhost');
      _validateOptionalPositiveInt(combat['maxHp'], '$context.combat.maxHp');
      _validateOptionalPositiveInt(
        combat['maxEnergy'],
        '$context.combat.maxEnergy',
      );
      _validateOptionalPositiveInt(
        combat['maxSpirit'],
        '$context.combat.maxSpirit',
      );
      _validateOptionalNonNegativeInt(
        combat['maxMana'],
        '$context.combat.maxMana',
      );
      _validateOptionalNonNegativeInt(
        combat['combatExperience'],
        '$context.combat.combatExperience',
      );
      _validateOptionalBool(
        combat['usesEquipmentStats'],
        '$context.combat.usesEquipmentStats',
      );
      for (final field in [
        'attack',
        'defense',
        'rewardSilver',
        'rewardExperience',
      ]) {
        _validateOptionalInt(combat[field], '$context.combat.$field');
      }
      _validateOptionalPositiveInt(
        combat['respawnAfterTurns'] ?? combat['respawnAfterMoves'],
        '$context.combat.respawnAfterTurns',
      );
      final specialMove = _optionalObject(
        combat['specialMove'],
        '$context.combat.specialMove',
      );
      _validateOptionalPositiveInt(
        specialMove['interval'],
        '$context.combat.specialMove.interval',
      );
      _validateOptionalInt(
        specialMove['damageBonus'],
        '$context.combat.specialMove.damageBonus',
      );
      _requireReference(
        'statusEffects',
        specialMove['statusEffectId'],
        '$context.combat.specialMove.statusEffectId',
        optional: true,
      );
      _requireReferences(
        'items',
        combat['dropItemIds'],
        '$context.combat.dropItemIds',
      );
      final roundEventIds = <String>{};
      for (final event in _objects(
        combat['roundEvents'],
        '$context.combat.roundEvents',
      )) {
        final eventContext = '$context.combat.roundEvents';
        final eventId = event['id'];
        if (eventId is! String || eventId.isEmpty) {
          errors.add('$eventContext.id must be non-empty text.');
        } else if (!roundEventIds.add(eventId)) {
          errors.add('$eventContext contains duplicate id "$eventId".');
        }
        if (event['round'] == null) {
          errors.add('$eventContext.round is required.');
        } else {
          _validateOptionalPositiveInt(event['round'], '$eventContext.round');
        }
        final message = event['message'];
        if (message is! String || message.isEmpty) {
          errors.add('$eventContext.message must be non-empty text.');
        }
        _requireReference(
          'npcs',
          event['spawnNpcId'],
          '$eventContext.spawnNpcId',
        );
        final instancePrefix = event['instancePrefix'];
        if (instancePrefix is! String || instancePrefix.isEmpty) {
          errors.add('$eventContext.instancePrefix must be non-empty text.');
        }
        _validateOptionalBool(
          event['queuesForCombat'],
          '$eventContext.queuesForCombat',
        );
      }
      final inventoryItemCounts = _optionalObject(
        npc.data['inventoryItemCounts'],
        '$context.inventoryItemCounts',
      );
      for (final entry in inventoryItemCounts.entries) {
        _requireReference(
          'items',
          entry.key,
          '$context.inventoryItemCounts.${entry.key}',
        );
        _validateOptionalPositiveInt(
          entry.value,
          '$context.inventoryItemCounts.${entry.key}',
        );
      }
      final inventoryItemIds =
          inventoryItemCounts.isNotEmpty
              ? inventoryItemCounts.keys.toList(growable: false)
              : npc.data.containsKey('inventoryItemIds')
              ? _stringList(
                npc.data['inventoryItemIds'],
                '$context.inventoryItemIds',
              )
              : _stringList(
                combat['dropItemIds'],
                '$context.combat.dropItemIds',
              );
      _requireReferences(
        'items',
        npc.data['inventoryItemIds'],
        '$context.inventoryItemIds',
      );
      final equippedItemIds = _optionalObject(
        npc.data['equippedItemIds'],
        '$context.equippedItemIds',
      );
      for (final entry in equippedItemIds.entries) {
        _validateEnum(
          entry.key,
          _equipmentSlots,
          '$context.equippedItemIds.${entry.key}',
          'equipment slot',
        );
        _requireReference(
          'items',
          entry.value,
          '$context.equippedItemIds.${entry.key}',
        );
        if (entry.value is String && !inventoryItemIds.contains(entry.value)) {
          errors.add(
            '$context equips item "${entry.value}" without carrying it.',
          );
        }
        final item = _definitions['items']?[entry.value];
        if (item != null && item.data['equipmentSlot'] != entry.key) {
          errors.add(
            '$context equips item "${entry.value}" in ${entry.key}, '
            'but the item uses ${item.data['equipmentSlot']}.',
          );
        }
      }
      final patrol = _optionalObject(npc.data['patrol'], '$context.patrol');
      if (patrol.isNotEmpty) {
        final roomIds = _stringList(
          patrol['roomIds'],
          '$context.patrol.roomIds',
        );
        _validateOptionalPositiveInt(
          patrol['intervalTurns'],
          '$context.patrol.intervalTurns',
        );
        if (roomIds.length < 2) {
          errors.add('$context.patrol.roomIds must contain at least 2 rooms.');
        }
        _requireReferences('rooms', roomIds, '$context.patrol.roomIds');
        for (var index = 0; index < roomIds.length; index++) {
          final fromRoomId = roomIds[index];
          final toRoomId = roomIds[(index + 1) % roomIds.length];
          if (_definitions['rooms']!.containsKey(fromRoomId) &&
              _definitions['rooms']!.containsKey(toRoomId) &&
              !_hasExit(fromRoomId, toRoomId)) {
            errors.add(
              '$context patrol step "$fromRoomId" -> "$toRoomId" '
              'does not follow a room exit.',
            );
          }
        }
      }
      final ambient = _optionalObject(npc.data['ambient'], '$context.ambient');
      if (ambient.isNotEmpty) {
        _validateOptionalPositiveInt(
          ambient['intervalTurns'],
          '$context.ambient.intervalTurns',
        );
        final messages = _stringList(
          ambient['messages'],
          '$context.ambient.messages',
        );
        if (messages.isEmpty || messages.any((message) => message.isEmpty)) {
          errors.add('$context.ambient.messages must contain non-empty text.');
        }
      }
      for (final reaction in _objects(
        npc.data['entryReactions'],
        '$context.entryReactions',
      )) {
        final reactionContext = '$context entry reaction';
        _validateCondition(
          reaction['conditions'],
          '$reactionContext.conditions',
        );
        final messages = _stringList(
          reaction['messages'],
          '$reactionContext.messages',
        );
        if (messages.isEmpty || messages.any((message) => message.isEmpty)) {
          errors.add('$reactionContext.messages must contain non-empty text.');
        }
        if (reaction['setsFlag'] case final value?
            when value is! String || value.isEmpty) {
          errors.add('$reactionContext.setsFlag must be non-empty text.');
        }
        if (reaction['startsCombat'] case final value? when value is! bool) {
          errors.add('$reactionContext.startsCombat must be a boolean.');
        }
        if (reaction['startsCombat'] == true && combat.isEmpty) {
          errors.add(
            '$reactionContext cannot start combat without combat data.',
          );
        }
        _validateNpcStateFields(reaction, reactionContext);
      }
      final shop = _optionalObject(npc.data['shop'], '$context.shop');
      for (final product in _objects(
        shop['products'],
        '$context.shop.products',
      )) {
        _requireReference('items', product['itemId'], '$context shop product');
        _validateOptionalInt(
          product['initialStock'],
          '$context shop product initialStock',
        );
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
        _validateNpcStateFields(option, optionContext);
        _requireReferences(
          'items',
          option['givesItemIds'],
          '$optionContext.givesItemIds',
        );
        _validateOptionalNonNegativeInt(
          option['silverCost'],
          '$optionContext.silverCost',
        );
        if (option['insufficientSilverResponse'] case final value?
            when value is! String || value.isEmpty) {
          errors.add(
            '$optionContext.insufficientSilverResponse must be non-empty text.',
          );
        }
        _validateOptionalPositiveInt(
          option['followingDurationTurns'],
          '$optionContext.followingDurationTurns',
        );
        if (option['followingDurationTurns'] != null &&
            option['startsFollowing'] != true) {
          errors.add(
            '$optionContext.followingDurationTurns requires startsFollowing.',
          );
        }
      }

      for (final option in _objects(
        npc.data['giveItemOptions'],
        '$context.giveItemOptions',
      )) {
        final optionContext = '$context give option';
        final itemId = option['itemId'];
        if (itemId != '*') {
          _requireReference('items', itemId, '$optionContext.itemId');
        }
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
        _validateNpcStateFields(option, optionContext);
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
        _validateEnum(
          teaching['access'],
          _teachingAccess,
          '$context teaching access',
          'teaching access',
          optional: true,
        );
        _validateOptionalPositiveInt(
          teaching['maxLevel'],
          '$context teaching maxLevel',
        );
        for (final field in ['requiredContribution', 'contributionCost']) {
          _validateOptionalInt(teaching[field], '$context teaching $field');
        }
        _validateIntegerMap(
          teaching['requiredNpcStateValues'],
          '$context teaching requiredNpcStateValues',
        );
        if (teaching['npcStateFailureMessage'] case final value?
            when value is! String || value.isEmpty) {
          errors.add(
            '$context teaching npcStateFailureMessage must be non-empty text.',
          );
        }
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
      _requireReference(
        'statusEffects',
        item.data['appliesStatusEffectId'],
        '$context.appliesStatusEffectId',
        optional: true,
      );
      _requireReference(
        'statusEffects',
        item.data['reducesStatusEffectId'],
        '$context.reducesStatusEffectId',
        optional: true,
      );
      if (item.data['reducesStatusEffectId'] != null) {
        _validateOptionalPositiveInt(
          item.data['statusEffectReduction'],
          '$context.statusEffectReduction',
        );
      } else {
        _validateOptionalInt(
          item.data['statusEffectReduction'],
          '$context.statusEffectReduction',
        );
      }
      _validateEnum(
        item.data['equipmentSlot'],
        _equipmentSlots,
        '$context.equipmentSlot',
        'equipment slot',
        optional: true,
      );
      _validateEnum(
        item.data['weaponSkillUsage'],
        _skillUsages,
        '$context.weaponSkillUsage',
        'skill usage',
        optional: true,
      );
      _validateOptionalBool(
        item.data['dissolvesCorpse'],
        '$context.dissolvesCorpse',
      );
      final roomUse = _optionalObject(item.data['roomUse'], '$context.roomUse');
      if (roomUse.isNotEmpty) {
        _requireReference(
          'rooms',
          roomUse['roomId'],
          '$context.roomUse.roomId',
        );
        for (final field in ['label', 'response']) {
          if (roomUse[field] case final value?
              when value is! String || value.isEmpty) {
            errors.add('$context.roomUse.$field must be non-empty text.');
          }
        }
        for (final exit in _objects(
          roomUse['unblocksExits'],
          '$context.roomUse.unblocksExits',
        )) {
          _requireReference(
            'rooms',
            exit['roomId'],
            '$context.roomUse unblocked exit roomId',
          );
          _validateEnum(
            exit['direction'],
            _directions,
            '$context.roomUse unblocked exit direction',
            'direction',
          );
        }
      }
      for (final field in [
        'attackPower',
        'restoreHp',
        'restoreInnerPower',
        'buyPrice',
        'sellPrice',
        'defensePower',
        'maxHpBonus',
        'maxInnerPowerBonus',
        'studyMaxSkillLevel',
        'studyExperience',
        'studyRequiredCombatExperience',
        'studySpiritCost',
        'studyDifficulty',
      ]) {
        _validateOptionalInt(item.data[field], '$context.$field');
      }
      final attributeBonuses = _optionalObject(
        item.data['attributeBonuses'],
        '$context.attributeBonuses',
      );
      for (final entry in attributeBonuses.entries) {
        if (!_innateAttributes.contains(entry.key)) {
          errors.add(
            '$context.attributeBonuses references unknown innate attribute '
            '"${entry.key}".',
          );
        }
        _validateOptionalInt(
          entry.value,
          '$context.attributeBonuses.${entry.key}',
        );
      }
      final skillBonuses = _optionalObject(
        item.data['skillBonuses'],
        '$context.skillBonuses',
      );
      for (final entry in skillBonuses.entries) {
        _requireReference('skills', entry.key, '$context.skillBonuses');
        _validateOptionalInt(entry.value, '$context.skillBonuses.${entry.key}');
      }
      for (final combination in _objects(
        item.data['combinations'],
        '$context.combinations',
      )) {
        final combinationContext = '$context combination';
        _requireReference(
          'items',
          combination['targetItemId'],
          '$combinationContext.targetItemId',
        );
        _requireReferences(
          'items',
          combination['resultItemIds'],
          '$combinationContext.resultItemIds',
        );
        for (final field in ['label', 'response']) {
          if (combination[field] is! String ||
              (combination[field] as String).isEmpty) {
            errors.add('$combinationContext.$field must be non-empty text.');
          }
        }
        for (final field in ['consumesSource', 'consumesTarget']) {
          if (combination[field] case final value? when value is! bool) {
            errors.add('$combinationContext.$field must be a boolean.');
          }
        }
      }
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
      _validateEnum(
        skill.data['kind'],
        _skillKinds,
        '$context.kind',
        'skill kind',
      );
      for (final usage in _stringList(
        skill.data['usages'],
        '$context.usages',
      )) {
        _validateEnum(usage, _skillUsages, '$context.usages', 'skill usage');
      }
      _validateEnum(
        skill.data['requiredEquipmentSlot'],
        _equipmentSlots,
        '$context.requiredEquipmentSlot',
        'equipment slot',
        optional: true,
      );
      for (final field in [
        'damageReduction',
        'maxLevel',
        'practiceExperience',
        'minimumMaxInnerPower',
        'practiceHpCost',
        'practiceInnerPowerCost',
      ]) {
        _validateOptionalInt(skill.data[field], '$context.$field');
      }
      _requireMapKeys(
        'skills',
        skill.data['requiredSkillLevels'],
        '$context.requiredSkillLevels',
      );
      _requireReferences(
        'skills',
        skill.data['requiredHigherSkillIds'],
        '$context.requiredHigherSkillIds',
      );
      final combinedRequirement = skill.data['combinedAttributeRequirement'];
      if (combinedRequirement != null) {
        final requirement = _object(
          combinedRequirement,
          '$context.combinedAttributeRequirement',
        );
        _validateEnum(
          requirement['attribute'],
          _innateAttributes,
          '$context.combinedAttributeRequirement.attribute',
          'innate attribute',
        );
        _validateOptionalNonNegativeInt(
          requirement['minimum'],
          '$context.combinedAttributeRequirement.minimum',
        );
        final divisor = requirement['maxInnerPowerDivisor'];
        if (divisor is! int || divisor <= 0) {
          errors.add(
            '$context.combinedAttributeRequirement.maxInnerPowerDivisor '
            'must be a positive integer.',
          );
        }
      }
      _validateEnum(
        skill.data['practiceRequiredWeaponUsage'],
        _skillUsages,
        '$context.practiceRequiredWeaponUsage',
        'skill usage',
        optional: true,
      );
      _requireReference(
        'families',
        skill.data['requiredFamilyId'],
        '$context.requiredFamilyId',
        optional: true,
      );
      for (final move in _objects(skill.data['moves'], '$context.moves')) {
        final moveId = move['id'] ?? '<missing id>';
        final moveContext = '$context move "$moveId"';
        _validateEnum(
          move['effectType'],
          _skillEffectTypes,
          '$moveContext.effectType',
          'skill effect type',
          optional: true,
        );
        _validateEnum(
          move['requiredEquipmentSlot'],
          _equipmentSlots,
          '$moveContext.requiredEquipmentSlot',
          'equipment slot',
          optional: true,
        );
        _validateEnum(
          move['targetResource'],
          _combatResources,
          '$moveContext.targetResource',
          'combat resource',
          optional: true,
        );
        _validateEnum(
          move['restoresPlayerResource'],
          _combatResources,
          '$moveContext.restoresPlayerResource',
          'combat resource',
          optional: true,
        );
        _validateOptionalPositiveInt(
          move['resourceDamageDivisor'],
          '$moveContext.resourceDamageDivisor',
        );
        _validateOptionalBool(
          move['usableOutsideCombat'],
          '$moveContext.usableOutsideCombat',
        );
        _requireReference(
          'skills',
          move['durationSkillId'],
          '$moveContext.durationSkillId',
          optional: true,
        );
        _validateOptionalPositiveInt(
          move['durationMultiplier'],
          '$moveContext.durationMultiplier',
        );
        _validateOptionalInt(
          move['durationBonus'],
          '$moveContext.durationBonus',
        );
        final activeFailureMessage = move['activeFailureMessage'];
        if (activeFailureMessage != null &&
            (activeFailureMessage is! String || activeFailureMessage.isEmpty)) {
          errors.add(
            '$moveContext.activeFailureMessage must be non-empty text.',
          );
        }
        for (final field in [
          'innerPowerCost',
          'manaCost',
          'spiritCost',
          'damageBonus',
          'defenseBonus',
          'healAmount',
          'minimumSkillLevel',
        ]) {
          _validateOptionalInt(move[field], '$moveContext.$field');
        }
        _requireReference(
          'rooms',
          move['escapeRoomId'],
          '$moveContext.escapeRoomId',
          optional: true,
        );
        final hasFailureRoll =
            move['castingSkillId'] != null ||
            move['failureRollBelow'] != null ||
            move['failureMessage'] != null;
        if (hasFailureRoll) {
          _validateEnum(
            move['failureRollSource'],
            _failureRollSources,
            '$moveContext.failureRollSource',
            'failure roll source',
            optional: true,
          );
          final failureRollSource = move['failureRollSource'] ?? 'skillLevel';
          _requireReference(
            'skills',
            move['castingSkillId'],
            '$moveContext.castingSkillId',
            optional: failureRollSource == 'maxMana',
          );
          final failureRollBelow = move['failureRollBelow'];
          if (failureRollBelow is! int || failureRollBelow <= 0) {
            errors.add(
              '$moveContext.failureRollBelow must be a positive integer.',
            );
          }
          final failureMessage = move['failureMessage'];
          if (failureMessage is! String || failureMessage.isEmpty) {
            errors.add('$moveContext.failureMessage must be non-empty text.');
          }
        }
        final opposedRollValue = move['opposedRoll'];
        if (opposedRollValue != null) {
          final opposedRoll = _object(
            opposedRollValue,
            '$moveContext.opposedRoll',
          );
          _validateEnum(
            opposedRoll['type'],
            _opposedRollTypes,
            '$moveContext.opposedRoll.type',
            'opposed roll type',
          );
          _requireReference(
            'skills',
            opposedRoll['skillId'],
            '$moveContext.opposedRoll.skillId',
          );
          final failureMessage = opposedRoll['failureMessage'];
          if (failureMessage is! String || failureMessage.isEmpty) {
            errors.add(
              '$moveContext.opposedRoll.failureMessage must be non-empty text.',
            );
          }
        }
        final summonValue = move['summon'];
        if (summonValue != null) {
          final summon = _object(summonValue, '$moveContext.summon');
          _validateSummon(summon, '$moveContext.summon');
        }
        final summons = _objects(move['summons'], '$moveContext.summons');
        for (var index = 0; index < summons.length; index++) {
          _validateSummon(summons[index], '$moveContext.summons[$index]');
        }
        _requireReference(
          'statusEffects',
          move['statusEffectId'],
          '$moveContext.statusEffectId',
          optional: true,
        );
      }
    }
  }

  void _validateSummon(Map<String, Object?> summon, String context) {
    for (final field in [
      'name',
      'summonMessage',
      'attackMessage',
      'defeatMessage',
      'leaveMessage',
    ]) {
      if (summon[field] is! String || (summon[field] as String).isEmpty) {
        errors.add('$context.$field must be non-empty text.');
      }
    }
    for (final field in ['attack', 'maxHp', 'selectionWeight']) {
      final value = summon[field];
      if (field == 'selectionWeight' && value == null) {
        continue;
      }
      if (value is! int || value <= 0) {
        errors.add('$context.$field must be a positive integer.');
      }
    }
    final defense = summon['defense'];
    if (defense is! int || defense < 0) {
      errors.add('$context.defense must be a non-negative integer.');
    }
    _validateOptionalNonNegativeInt(
      summon['durationRounds'],
      '$context.durationRounds',
    );
    final nameVariants = summon['nameVariants'];
    if (nameVariants != null) {
      if (nameVariants is! List<Object?> ||
          nameVariants.isEmpty ||
          nameVariants.any((name) => name is! String || name.isEmpty)) {
        errors.add('$context.nameVariants must contain non-empty text.');
      }
    }
  }

  void _validateStatusEffects() {
    for (final effect in _all('statusEffects')) {
      final context = 'status effect "${effect.id}" (${effect.source})';
      _validateOptionalBool(
        effect.data['grantsAstralVision'],
        '$context.grantsAstralVision',
      );
      final name = effect.data['name'];
      if (name is! String || name.trim().isEmpty) {
        errors.add('$context.name must be a non-empty string.');
      }
      final duration = effect.data['duration'];
      if (duration is! int || duration <= 0) {
        errors.add('$context.duration must be a positive integer.');
      }
      for (final field in [
        'damagePerRound',
        'spiritDamagePerRound',
        'innerPowerDamagePerRound',
        'hpRecoveryPerRound',
        'attackPenalty',
        'defensePenalty',
      ]) {
        _validateOptionalInt(effect.data[field], '$context.$field');
      }
      final blocksAction = effect.data['blocksAction'];
      if (blocksAction != null && blocksAction is! bool) {
        errors.add('$context.blocksAction must be a boolean.');
      }
    }
  }

  void _validateFamilies() {
    final taskIds = <String>{};
    for (final family in _all('families')) {
      final context = 'family "${family.id}" (${family.source})';
      final rankIds = <String>{};
      for (final rank in _objects(family.data['ranks'], '$context.ranks')) {
        final id = rank['id'];
        if (id is String && !rankIds.add(id)) {
          errors.add('$context has duplicated rank id "$id".');
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
        for (final field in [
          'rewardExperience',
          'rewardPotential',
          'rewardContribution',
        ]) {
          _validateOptionalInt(task[field], '$context task "$id" $field');
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
    for (final status
        in _optionalObject(
          condition['requiredQuestStatuses'],
          '$context.requiredQuestStatuses',
        ).values) {
      _validateEnum(
        status,
        _questStatuses,
        '$context.requiredQuestStatuses',
        'quest status',
      );
    }
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
    final requiredGender = condition['requiredGender'];
    if (requiredGender != null &&
        (requiredGender is! String ||
            !_playerGenders.contains(requiredGender))) {
      errors.add(
        '$context references unknown player gender "$requiredGender".',
      );
    }
    _validateOptionalNonNegativeInt(
      condition['minimumCombatExperience'],
      '$context.minimumCombatExperience',
    );
    if (condition['requiresNoFamily'] case final value? when value is! bool) {
      errors.add('$context.requiresNoFamily must be a boolean.');
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

  bool _hasExit(String fromRoomId, String toRoomId) {
    final room = _definitions['rooms']![fromRoomId];
    if (room == null) return false;
    final exits = _optionalObject(
      room.data['exits'],
      'room "$fromRoomId" exits',
    );
    return exits.values.any((exit) {
      final target =
          exit is String
              ? exit
              : _object(exit, 'room "$fromRoomId" exit')['roomId'];
      return target == toRoomId;
    });
  }

  void _validateEnum(
    Object? value,
    Set<String> allowedValues,
    String context,
    String label, {
    bool optional = false,
  }) {
    if (value == null && optional) return;
    if (value is! String || !allowedValues.contains(value)) {
      errors.add(
        '$context must be a valid $label: ${allowedValues.join(', ')}.',
      );
    }
  }

  void _validateOptionalInt(Object? value, String context) {
    if (value != null && value is! int) {
      errors.add('$context must be an integer.');
    }
  }

  void _validateOptionalBool(Object? value, String context) {
    if (value != null && value is! bool) {
      errors.add('$context must be a boolean.');
    }
  }

  void _validateIntegerMap(Object? value, String context) {
    final values = _optionalObject(value, context);
    for (final entry in values.entries) {
      if (entry.value is! int) {
        errors.add('$context.${entry.key} must be an integer.');
      }
    }
  }

  void _validateNpcStateFields(
    Map<String, Object?> definition,
    String context,
  ) {
    for (final field in [
      'requiredNpcStateValues',
      'setNpcStateValues',
      'incrementNpcStateValues',
    ]) {
      _validateIntegerMap(definition[field], '$context.$field');
    }
  }

  void _validateOptionalPositiveInt(Object? value, String context) {
    if (value == null) return;
    if (value is! int || value <= 0) {
      errors.add('$context must be a positive integer.');
    }
  }

  void _validateOptionalNonNegativeInt(Object? value, String context) {
    if (value == null) return;
    if (value is! int || value < 0) {
      errors.add('$context must be a non-negative integer.');
    }
  }

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
