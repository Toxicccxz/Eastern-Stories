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
      areaResetAtTurns: const {'oldpine': 42},
      visitedRoomIds: {'liu_home', 'little_garden'},
      inventoryItemIds: ['old_book'],
      equippedWeaponId: 'hengbing_sword',
      skillProgress: {'parry': const SkillProgress(level: 3, experience: 45)},
      enabledSkillIds: const {SkillUsage.parry: 'deisword'},
      player: GameState.initial(startingRoomId: 'liu_home').player.copyWith(
        spirit: 37,
        energy: 77,
        maxEnergy: 120,
        atman: 22,
        maxAtman: 50,
        mana: 123,
        maxMana: 321,
        potential: 14,
        intelligence: 16,
        combatExperience: 240,
        betrayalCount: 2,
      ),
      apprenticeship: const ApprenticeshipState(
        familyId: 'fengshan_sword',
        masterNpcId: 'liu_chunfeng',
        generation: 2,
        title: '弟子',
        contribution: 7,
      ),
      npcStates: {
        'white_ice_dragon': const NpcRuntimeState(
          roomId: 'ice_cave',
          currentHp: 12,
          currentEnergy: 9,
          currentSpirit: 7,
          currentMana: 5,
          isDefeated: false,
          respawnAtTurn: 15,
          hasDroppedLoot: true,
          isFollowing: true,
          followUntilTurn: 20,
          followReturnRoomId: 'ice_cave',
          isRemoved: false,
          stateValues: {'trust': 2},
          itemCounts: {'hengbing_sword': 1},
          equippedItemIds: {EquipmentSlot.weapon: 'hengbing_sword'},
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
        queuedNpcIds: ['oldpine_called_bandit_chief_1'],
        ally: SummonedAllyState(
          name: '天甲神兵',
          attack: 20,
          hp: 812,
          maxHp: 1000,
          defense: 14,
          attackMessage: '神兵挥剑。',
          defeatMessage: '神兵消散。',
          leaveMessage: '神兵归天。',
          remainingRounds: 0,
        ),
      ),
    );

    await repository.save(state);

    expect(await repository.hasSave(), isTrue);

    final loaded = await repository.load();

    expect(loaded, isNotNull);
    expect(loaded?.currentRoomId, 'little_garden');
    expect(loaded?.worldTurn, 9);
    expect(loaded?.areaResetAtTurns, {'oldpine': 42});
    expect(loaded?.inventoryItemIds, ['old_book']);
    expect(loaded?.equippedWeaponId, 'hengbing_sword');
    expect(loaded?.equippedItemIds, {EquipmentSlot.weapon: 'hengbing_sword'});
    expect(loaded?.learnedSkillIds, {'parry'});
    expect(loaded?.skillProgress['parry']?.level, 3);
    expect(loaded?.skillProgress['parry']?.experience, 45);
    expect(loaded?.enabledSkillIds, {SkillUsage.parry: 'deisword'});
    expect(loaded?.player.spirit, 37);
    expect(loaded?.player.energy, 77);
    expect(loaded?.player.maxEnergy, 120);
    expect(loaded?.player.atman, 22);
    expect(loaded?.player.maxAtman, 50);
    expect(loaded?.player.mana, 123);
    expect(loaded?.player.maxMana, 321);
    expect(loaded?.player.potential, 14);
    expect(loaded?.player.intelligence, 16);
    expect(loaded?.player.combatExperience, 240);
    expect(loaded?.player.betrayalCount, 2);
    expect(loaded?.apprenticeship?.familyId, 'fengshan_sword');
    expect(loaded?.apprenticeship?.masterNpcId, 'liu_chunfeng');
    expect(loaded?.apprenticeship?.generation, 2);
    expect(loaded?.apprenticeship?.contribution, 7);
    expect(loaded?.npcStates['white_ice_dragon']?.roomId, 'ice_cave');
    expect(loaded?.npcStates['white_ice_dragon']?.currentHp, 12);
    expect(loaded?.npcStates['white_ice_dragon']?.currentEnergy, 9);
    expect(loaded?.npcStates['white_ice_dragon']?.currentSpirit, 7);
    expect(loaded?.npcStates['white_ice_dragon']?.currentMana, 5);
    expect(loaded?.npcStates['white_ice_dragon']?.isDefeated, isFalse);
    expect(loaded?.npcStates['white_ice_dragon']?.respawnAtTurn, 15);
    expect(loaded?.npcStates['white_ice_dragon']?.hasDroppedLoot, isTrue);
    expect(loaded?.npcStates['white_ice_dragon']?.isFollowing, isTrue);
    expect(loaded?.npcStates['white_ice_dragon']?.followUntilTurn, 20);
    expect(
      loaded?.npcStates['white_ice_dragon']?.followReturnRoomId,
      'ice_cave',
    );
    expect(loaded?.npcStates['white_ice_dragon']?.isRemoved, isFalse);
    expect(loaded?.npcStates['white_ice_dragon']?.stateValues, {'trust': 2});
    expect(loaded?.npcStates['white_ice_dragon']?.itemCounts, {
      'hengbing_sword': 1,
    });
    expect(loaded?.npcStates['white_ice_dragon']?.equippedItemIds, {
      EquipmentSlot.weapon: 'hengbing_sword',
    });
    expect(loaded?.shopStates['meloner']?.stockByItemId, {'water_melon': 3});
    expect(loaded?.questStatuses['old_liu_daughter'], QuestStatus.active);
    expect(loaded?.questFlags, {'flower_girl_found'});
    expect(loaded?.combat?.npcId, 'white_ice_dragon');
    expect(loaded?.combat?.enemyHp, 12);
    expect(loaded?.combat?.round, 4);
    expect(loaded?.combat?.queuedNpcIds, ['oldpine_called_bandit_chief_1']);
    expect(loaded?.combat?.ally?.name, '天甲神兵');
    expect(loaded?.combat?.ally?.attack, 20);
    expect(loaded?.combat?.ally?.hp, 812);
    expect(loaded?.combat?.ally?.maxHp, 1000);
    expect(loaded?.combat?.ally?.defense, 14);
    expect(loaded?.combat?.ally?.remainingRounds, 0);

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
