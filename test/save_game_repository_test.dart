import 'dart:io';

import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/models/equipment_slot.dart';
import 'package:eastern_stories/game/models/quest_definition.dart';
import 'package:eastern_stories/game/models/skill_progress.dart';
import 'package:eastern_stories/game/models/skill_definition.dart';
import 'package:eastern_stories/game/repositories/save_game_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('save repository writes, loads, and deletes game state', () async {
    final directory = await Directory.systemTemp.createTemp(
      'eastern_stories_save_test',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final file = File('${directory.path}${Platform.pathSeparator}save.json');
    final repository = SaveGameRepository(file: file);
    final state = GameState.initial(startingRoomId: 'liu_home').copyWith(
      currentRoomId: 'little_garden',
      worldTurn: 9,
      visitedRoomIds: {'liu_home', 'little_garden'},
      inventoryItemIds: ['old_book'],
      equippedWeaponId: 'hengbing_sword',
      skillProgress: {'parry': const SkillProgress(level: 3, experience: 45)},
      enabledSkillIds: const {SkillUsage.parry: 'deisword'},
      npcStates: {
        'white_ice_dragon': const NpcRuntimeState(
          roomId: 'ice_cave',
          currentHp: 12,
          isDefeated: false,
          respawnAtTurn: 15,
          hasDroppedLoot: true,
          isFollowing: true,
          isRemoved: false,
        ),
      },
      shopStates: {
        'meloner': const ShopRuntimeState(stockByItemId: {'water_melon': 3}),
      },
      questStatuses: {'old_liu_daughter': QuestStatus.active},
      questFlags: {'flower_girl_found'},
      combat: const CombatState(
        npcId: 'white_ice_dragon',
        enemyHp: 12,
        round: 4,
      ),
    );

    await repository.save(state);

    expect(await repository.hasSave(), isTrue);

    final loaded = await repository.load();

    expect(loaded, isNotNull);
    expect(loaded?.currentRoomId, 'little_garden');
    expect(loaded?.worldTurn, 9);
    expect(loaded?.inventoryItemIds, ['old_book']);
    expect(loaded?.equippedWeaponId, 'hengbing_sword');
    expect(loaded?.equippedItemIds, {EquipmentSlot.weapon: 'hengbing_sword'});
    expect(loaded?.learnedSkillIds, {'parry'});
    expect(loaded?.skillProgress['parry']?.level, 3);
    expect(loaded?.skillProgress['parry']?.experience, 45);
    expect(loaded?.enabledSkillIds, {SkillUsage.parry: 'deisword'});
    expect(loaded?.npcStates['white_ice_dragon']?.roomId, 'ice_cave');
    expect(loaded?.npcStates['white_ice_dragon']?.currentHp, 12);
    expect(loaded?.npcStates['white_ice_dragon']?.isDefeated, isFalse);
    expect(loaded?.npcStates['white_ice_dragon']?.respawnAtTurn, 15);
    expect(loaded?.npcStates['white_ice_dragon']?.hasDroppedLoot, isTrue);
    expect(loaded?.npcStates['white_ice_dragon']?.isFollowing, isTrue);
    expect(loaded?.npcStates['white_ice_dragon']?.isRemoved, isFalse);
    expect(loaded?.shopStates['meloner']?.stockByItemId, {'water_melon': 3});
    expect(loaded?.questStatuses['old_liu_daughter'], QuestStatus.active);
    expect(loaded?.questFlags, {'flower_girl_found'});
    expect(loaded?.combat?.npcId, 'white_ice_dragon');
    expect(loaded?.combat?.enemyHp, 12);
    expect(loaded?.combat?.round, 4);

    await repository.delete();

    expect(await repository.hasSave(), isFalse);
  });

  test('legacy equipped weapon field migrates into weapon slot', () {
    final json =
        GameState.initial(
            startingRoomId: 'liu_home',
          ).copyWith(equippedWeaponId: 'hengbing_sword').toJson()
          ..remove('equippedItemIds');

    final state = GameState.fromJson(json);

    expect(state.equippedItemIds, {EquipmentSlot.weapon: 'hengbing_sword'});
  });

  test('legacy combat state defaults to round zero', () {
    final state = CombatState.fromJson({
      'npcId': 'white_ice_dragon',
      'enemyHp': 12,
    });

    expect(state.round, 0);
  });

  test('legacy learned skills migrate to level one progress', () {
    final json =
        GameState.initial(
            startingRoomId: 'liu_home',
          ).copyWith(learnedSkillIds: {'parry'}).toJson()
          ..remove('skillProgress');

    final state = GameState.fromJson(json);

    expect(state.skillProgress['parry']?.level, 1);
    expect(state.skillProgress['parry']?.experience, 0);
  });
}
