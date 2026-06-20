import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/direction.dart';
import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/models/quest_definition.dart';
import 'package:eastern_stories/game/models/skill_definition.dart';
import 'package:eastern_stories/game/models/skill_progress.dart';
import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDefinitionRepository repository;

  setUpAll(() async {
    repository = await GameDefinitionRepository.loadDemo();
  });

  test('moving through an exit updates current room and log', () {
    final controller = GameController(repository: repository);

    controller.dispatch(const GameAction.move(Direction.south));

    expect(controller.state.currentRoomId, 'little_garden');
    expect(controller.state.visitedRoomIds, contains('little_garden'));
    expect(controller.state.log.last, contains('花园'));
  });

  test('picking up an item moves it into inventory', () {
    final controller = GameController(repository: repository);

    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.pickUp('old_book'));

    expect(controller.state.inventoryItemIds, contains('old_book'));
    expect(
      controller.repository
          .room(controller.state.currentRoomId)
          .visibleItemIds(controller.state),
      isNot(contains('old_book')),
    );
  });

  test('dropping an item moves it into the current room', () {
    final controller = GameController(repository: repository);

    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.pickUp('old_book'));
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.dropItem('old_book'));

    expect(controller.state.inventoryItemIds, isNot(contains('old_book')));
    expect(
      repository.room('liu_home').visibleItemIds(controller.state),
      contains('old_book'),
    );
    expect(controller.state.log.last, contains('放下'));
  });

  test('legacy flower girl quest state is reset during load', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        npcStates: {
          ...initialState.npcStates,
          'flower_girl': const NpcRuntimeState(
            roomId: 'liu_home',
            currentHp: 0,
            isDefeated: false,
          ),
        },
        questStatuses: {'find_flower_girl': QuestStatus.completed},
        questFlags: {'found_flower_girl'},
      ),
    );

    expect(controller.state.npcStates['flower_girl']?.roomId, 'little_garden');
    expect(controller.state.questStatuses, isNot(contains('find_flower_girl')));
    expect(controller.state.questFlags, isNot(contains('found_flower_girl')));
  });

  test('old liu quest can be started, progressed, and completed', () {
    final controller = GameController(repository: repository);

    controller.dispatch(
      const GameAction.selectDialogue('old_liu', 'ask_daughter'),
    );
    expect(
      controller.dialogueOptionsFor('old_liu').map((option) => option.id),
      isNot(contains('report_daughter')),
    );
    expect(
      _questView(
        controller,
        'rescue_xiao_juan',
      ).steps.map((step) => step.status),
      [
        QuestStepStatus.completed,
        QuestStepStatus.current,
        QuestStepStatus.pending,
        QuestStepStatus.pending,
        QuestStepStatus.pending,
        QuestStepStatus.pending,
      ],
    );
    expect(
      repository
          .room('granite_road')
          .availableExits(controller.state)
          .containsKey(Direction.east),
      isFalse,
    );
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(
      const GameAction.selectDialogue('flower_girl', 'ask_about_xiao_juan'),
    );
    expect(controller.state.npcStates['flower_girl']?.roomId, 'little_garden');
    expect(
      controller.dialogueOptionsFor('flower_girl').map((option) => option.id),
      isNot(contains('ask_about_xiao_juan')),
    );
    expect(
      repository
          .room('granite_road')
          .availableExits(controller.state)
          .containsKey(Direction.east),
      isFalse,
    );
    expect(
      _questView(
        controller,
        'rescue_xiao_juan',
      ).steps.map((step) => step.status),
      [
        QuestStepStatus.completed,
        QuestStepStatus.completed,
        QuestStepStatus.current,
        QuestStepStatus.pending,
        QuestStepStatus.pending,
        QuestStepStatus.pending,
      ],
    );

    _moveToDungeon(controller);
    expect(
      repository
          .room('granite_road')
          .availableExits(controller.state)
          .containsKey(Direction.east),
      isTrue,
    );
    controller.dispatch(
      const GameAction.selectDialogue('xiao_juan', 'rescue_xiao_juan'),
    );

    expect(controller.state.npcStates['xiao_juan']?.isFollowing, isTrue);
    expect(
      _questView(
        controller,
        'rescue_xiao_juan',
      ).steps.map((step) => step.status),
      [
        QuestStepStatus.completed,
        QuestStepStatus.completed,
        QuestStepStatus.completed,
        QuestStepStatus.completed,
        QuestStepStatus.completed,
        QuestStepStatus.current,
      ],
    );

    controller.dispatch(const GameAction.move(Direction.west));
    expect(controller.state.npcStates['xiao_juan']?.roomId, 'dungeon_tunnel');
    _moveHomeFromDungeonTunnel(controller);
    expect(controller.state.npcStates['xiao_juan']?.roomId, 'liu_home');
    expect(
      controller.dialogueOptionsFor('old_liu').map((option) => option.id),
      contains('report_daughter'),
    );
    controller.dispatch(
      const GameAction.selectDialogue('old_liu', 'report_daughter'),
    );

    expect(controller.state.inventoryItemIds, contains('hengbing_sword'));
    expect(controller.state.inventoryItemIds, contains('parry_book'));
    expect(controller.state.inventoryItemIds, contains('rough_short_sword'));
    expect(controller.state.player.silver, 28);
    expect(controller.state.player.experience, 40);
    expect(controller.state.npcStates['old_liu']?.isRemoved, isTrue);
    expect(controller.state.npcStates['xiao_juan']?.isRemoved, isTrue);
    expect(
      _questView(
        controller,
        'rescue_xiao_juan',
      ).steps.map((step) => step.status),
      [
        QuestStepStatus.completed,
        QuestStepStatus.completed,
        QuestStepStatus.completed,
        QuestStepStatus.completed,
        QuestStepStatus.completed,
        QuestStepStatus.completed,
      ],
    );
    expect(controller.state.log.last, contains('完成委托'));
  });

  test('player can study parry book to learn basic parry', () {
    final controller = GameController(repository: repository);

    _completeRescueQuest(controller);
    controller.dispatch(const GameAction.studyItem('parry_book'));

    expect(controller.state.learnedSkillIds, contains('parry'));
    expect(controller.learnedSkills().single.name, '基本招架');
  });

  test('player can study the ancient sword manual', () {
    final controller = GameController(repository: repository);

    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.pickUp('old_book'));
    controller.dispatch(const GameAction.studyItem('old_book'));

    expect(controller.state.learnedSkillIds, contains('basic_sword'));
    expect(controller.activeCombatMoves(), isEmpty);
  });

  test('special sword art must be enabled before its move can be used', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        inventoryItemIds: const ['hengbing_sword'],
        player: initialState.player.copyWith(innerPower: 50, maxInnerPower: 50),
        skillProgress: const {
          'basic_sword': SkillProgress(level: 10, experience: 0),
          'deisword': SkillProgress(level: 5, experience: 0),
        },
      ),
    );

    controller.dispatch(const GameAction.equipItem('hengbing_sword'));
    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(
      const GameAction.useCombatMove('deisword', 'wild_drunkenness'),
    );

    expect(controller.state.combat?.enemyHp, 36);
    expect(controller.state.player.innerPower, 50);
    expect(controller.state.log.last, contains('尚未启用'));

    controller.dispatch(
      const GameAction.enableSkill('deisword', SkillUsage.sword),
    );
    expect(controller.state.enabledSkillIds[SkillUsage.sword], 'deisword');
    controller.dispatch(
      const GameAction.useCombatMove('deisword', 'wild_drunkenness'),
    );

    expect(controller.state.combat?.enemyHp, lessThan(36));
    expect(controller.state.player.innerPower, 42);
    expect(controller.state.skillProgress['deisword']?.experience, 20);
    expect(controller.state.log, contains(contains('拟把疏狂图一醉')));
  });

  test('active parry stance blocks the next enemy attack', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        learnedSkillIds: {'parry'},
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(const GameAction.useCombatMove('parry', 'hold_guard'));

    expect(controller.state.player.hp, 80);
    expect(controller.state.combat?.round, 1);
    expect(controller.state.skillProgress['parry']?.experience, 20);
    expect(controller.state.log.last, contains('挡下'));
  });

  test('repeated study raises skill level within the manual limit', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(inventoryItemIds: const ['old_book']),
    );

    for (var study = 0; study < 4; study += 1) {
      controller.dispatch(const GameAction.studyItem('old_book'));
    }

    expect(controller.state.skillProgress['basic_sword']?.level, 2);
    expect(controller.state.skillProgress['basic_sword']?.experience, 20);
    expect(controller.state.log, contains(contains('Lv.2')));
  });

  test('enemy special move triggers on its configured round', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(const GameAction.attack());
    controller.dispatch(const GameAction.attack());

    expect(controller.state.combat?.round, 2);
    expect(controller.state.player.hp, 66);
    expect(controller.state.log.last, contains('寒息'));
  });

  test('defeated player recovers at the starting room', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        player: initialState.player.copyWith(hp: 1),
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(const GameAction.attack());

    expect(controller.state.combat, isNull);
    expect(controller.state.currentRoomId, 'liu_home');
    expect(controller.state.player.hp, 40);
    expect(controller.state.player.innerPower, 15);
    expect(controller.state.npcStates['white_ice_dragon']?.currentHp, 32);
    expect(controller.state.log.last, contains('昏迷'));
  });

  test('room actions can move the player through lake scenes', () {
    final controller = GameController(repository: repository);

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.performRoomAction('paddle_to_lake'));
    controller.dispatch(const GameAction.performRoomAction('dive_into_lake'));

    expect(controller.state.currentRoomId, 'underwater_cave');
    expect(controller.state.visitedRoomIds, contains('jade_snail_lake_center'));
    expect(controller.state.log.last, contains('岩洞'));
  });

  test('player can cross from village into canyon area', () {
    final controller = GameController(repository: repository);

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.north));

    final room = repository.room(controller.state.currentRoomId);

    expect(room.id, 'canyon_gate');
    expect(repository.area(room.areaId).name, '天驼关');
    expect(repository.roomsInArea(room.areaId), hasLength(8));
    expect(controller.state.visitedRoomIds, contains('yellow_road'));
  });

  test('general seal quest follows the original fake seal exchange', () {
    final controller = GameController(repository: repository);

    _moveToGeneralTent(controller);
    controller.dispatch(
      const GameAction.selectDialogue('general_yan', 'ask_about_seal'),
    );
    controller.dispatch(
      const GameAction.selectDialogue('adviser_he', 'ask_about_armory'),
    );

    expect(
      controller.state.questStatuses['recover_general_seal'],
      QuestStatus.active,
    );
    expect(controller.state.questFlags, contains('canyon_armory_clue'));

    for (var step = 0; step < 3; step += 1) {
      controller.dispatch(const GameAction.move(Direction.west));
    }
    controller.dispatch(
      const GameAction.performRoomAction('swear_at_smooth_wall'),
    );
    controller.dispatch(
      const GameAction.buyItem('reserve_soldier', 'fake_general_seal'),
    );

    expect(controller.state.currentRoomId, 'canyon_armory');
    expect(controller.state.inventoryItemIds, contains('fake_general_seal'));
    expect(controller.state.player.silver, 0);

    _moveFromArmoryToGeneral(controller);
    controller.dispatch(
      const GameAction.giveItem('general_yan', 'fake_general_seal'),
    );

    expect(controller.state.questFlags, contains('fake_seal_rejected'));
    expect(controller.state.inventoryItemIds, contains('fake_general_seal'));

    for (var step = 0; step < 3; step += 1) {
      controller.dispatch(const GameAction.move(Direction.west));
    }
    controller.dispatch(
      const GameAction.performRoomAction('swear_at_smooth_wall'),
    );
    controller.dispatch(
      const GameAction.giveItem('reserve_soldier', 'fake_general_seal'),
    );

    expect(
      controller.state.inventoryItemIds,
      isNot(contains('fake_general_seal')),
    );
    expect(controller.state.inventoryItemIds, contains('general_seal'));
    expect(controller.state.questFlags, contains('real_seal_obtained'));

    _moveFromArmoryToGeneral(controller);
    controller.dispatch(
      const GameAction.giveItem('general_yan', 'general_seal'),
    );

    expect(
      controller.state.questStatuses['recover_general_seal'],
      QuestStatus.completed,
    );
    expect(controller.state.inventoryItemIds, contains('canyon_old_sword'));
    expect(controller.state.inventoryItemIds, isNot(contains('general_seal')));
    expect(
      _questView(
        controller,
        'recover_general_seal',
      ).steps.every((step) => step.status == QuestStepStatus.completed),
      isTrue,
    );

    controller.dispatch(const GameAction.studyItem('canyon_old_sword'));
    controller.dispatch(const GameAction.studyItem('canyon_old_sword'));
    expect(controller.state.skillProgress['parry']?.level, 1);
    expect(controller.state.skillProgress['parry']?.experience, 60);
  });

  test('player can buy, sell, and use melon', () {
    final controller = GameController(repository: repository);

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.buyItem('meloner', 'water_melon'));

    expect(controller.state.player.silver, 14);
    expect(controller.state.inventoryItemIds, contains('water_melon'));
    expect(controller.state.shopStates['meloner']?.stockByItemId, {
      'water_melon': -1,
    });

    controller.dispatch(const GameAction.sellItem('meloner', 'water_melon'));
    expect(controller.state.player.silver, 17);
    expect(controller.state.inventoryItemIds, isNot(contains('water_melon')));

    controller.dispatch(const GameAction.buyItem('meloner', 'water_melon'));
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.move(Direction.west));
    _completeRescueQuest(controller);
    controller.dispatch(const GameAction.equipItem('hengbing_sword'));
    controller.dispatch(const GameAction.studyItem('parry_book'));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.performRoomAction('paddle_to_lake'));
    controller.dispatch(const GameAction.performRoomAction('dive_into_lake'));
    controller.dispatch(const GameAction.move(Direction.west));
    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(const GameAction.attack());
    controller.dispatch(const GameAction.useItem('water_melon'));

    expect(controller.state.inventoryItemIds, isNot(contains('water_melon')));
    expect(controller.state.player.hp, 80);
  });

  test('finite shop stock prevents buying after sellout', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        shopStates: {
          ...initialState.shopStates,
          'meloner': const ShopRuntimeState(stockByItemId: {'water_melon': 1}),
        },
      ),
    );

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.buyItem('meloner', 'water_melon'));
    controller.dispatch(const GameAction.buyItem('meloner', 'water_melon'));

    expect(
      controller.state.inventoryItemIds.where((id) => id == 'water_melon'),
      hasLength(1),
    );
    expect(controller.state.shopStates['meloner']?.stockByItemId, {
      'water_melon': 0,
    });
    expect(controller.state.log.last, contains('卖完'));
  });

  test('player can equip a weapon and defeat the ice dragon', () {
    final controller = GameController(repository: repository);

    _completeRescueQuest(controller);
    controller.dispatch(const GameAction.equipItem('hengbing_sword'));
    controller.dispatch(const GameAction.studyItem('parry_book'));

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.performRoomAction('paddle_to_lake'));
    controller.dispatch(const GameAction.performRoomAction('dive_into_lake'));
    controller.dispatch(const GameAction.move(Direction.west));
    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(const GameAction.attack());
    controller.dispatch(const GameAction.attack());
    controller.dispatch(const GameAction.attack());

    expect(controller.state.equippedWeaponId, 'hengbing_sword');
    expect(controller.characterStats().attack, 18);
    expect(controller.state.learnedSkillIds, contains('parry'));
    expect(controller.state.combat, isNull);
    expect(controller.state.player.silver, 108);
    expect(controller.state.player.level, 2);
    expect(controller.state.player.experience, 10);
    expect(controller.state.player.hp, 92);
    expect(controller.state.npcStates['white_ice_dragon']?.isDefeated, isTrue);
    expect(
      controller.repository.visibleNpcsInRoom(
        controller.state,
        controller.state.currentRoomId,
      ),
      isEmpty,
    );
    expect(
      controller.repository
          .room(controller.state.currentRoomId)
          .visibleItemIds(controller.state),
      contains('ice_dragon_scale'),
    );
    expect(controller.state.log, contains(contains('白鳞冰龙')));
    expect(controller.state.log.last, contains('冰龙白鳞'));

    controller.dispatch(const GameAction.pickUp('ice_dragon_scale'));
    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));

    expect(controller.state.inventoryItemIds, contains('ice_dragon_scale'));
    expect(controller.state.combat, isNull);

    for (var index = 0; index < 3; index += 1) {
      controller.dispatch(const GameAction.move(Direction.east));
      controller.dispatch(const GameAction.move(Direction.west));
    }

    expect(controller.state.npcStates['white_ice_dragon']?.isDefeated, isFalse);
    expect(
      controller.state.npcStates['white_ice_dragon']?.hasDroppedLoot,
      isTrue,
    );
    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    expect(controller.state.combat, isNotNull);
  });

  test('enemy damage persists after fleeing and restarting combat', () {
    final controller = GameController(repository: repository);

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.performRoomAction('paddle_to_lake'));
    controller.dispatch(const GameAction.performRoomAction('dive_into_lake'));
    controller.dispatch(const GameAction.move(Direction.west));
    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(const GameAction.attack());
    controller.dispatch(const GameAction.fleeCombat());

    final remainingHp =
        controller.state.npcStates['white_ice_dragon']?.currentHp;

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));

    expect(remainingHp, 32);
    expect(controller.state.combat?.enemyHp, remainingHp);
  });
}

void _completeRescueQuest(GameController controller) {
  controller.dispatch(
    const GameAction.selectDialogue('old_liu', 'ask_daughter'),
  );
  controller.dispatch(const GameAction.move(Direction.south));
  controller.dispatch(
    const GameAction.selectDialogue('flower_girl', 'ask_about_xiao_juan'),
  );
  _moveToDungeon(controller);
  controller.dispatch(
    const GameAction.selectDialogue('xiao_juan', 'rescue_xiao_juan'),
  );
  controller.dispatch(const GameAction.move(Direction.west));
  _moveHomeFromDungeonTunnel(controller);
  controller.dispatch(
    const GameAction.selectDialogue('old_liu', 'report_daughter'),
  );
}

void _moveToDungeon(GameController controller) {
  for (final direction in const [
    Direction.north,
    Direction.east,
    Direction.north,
    Direction.north,
    Direction.east,
    Direction.north,
    Direction.north,
    Direction.up,
  ]) {
    controller.dispatch(GameAction.move(direction));
  }
  controller.dispatch(const GameAction.startCombat('black_pine_scout'));
  for (var turn = 0; turn < 3; turn += 1) {
    controller.dispatch(const GameAction.attack());
  }
  controller.dispatch(const GameAction.pickUp('rough_short_sword'));
  controller.dispatch(const GameAction.equipItem('rough_short_sword'));
  controller.dispatch(const GameAction.move(Direction.up));
  controller.dispatch(const GameAction.startCombat('black_pine_guard'));
  for (var turn = 0; turn < 3; turn += 1) {
    controller.dispatch(const GameAction.attack());
  }
  controller.dispatch(const GameAction.move(Direction.east));
  controller.dispatch(const GameAction.move(Direction.east));
}

void _moveHomeFromDungeonTunnel(GameController controller) {
  for (final direction in const [
    Direction.west,
    Direction.down,
    Direction.down,
    Direction.south,
    Direction.south,
    Direction.west,
    Direction.south,
    Direction.south,
    Direction.west,
  ]) {
    controller.dispatch(GameAction.move(direction));
  }
}

QuestView _questView(GameController controller, String questId) {
  return controller.questViews().firstWhere(
    (quest) => quest.definition.id == questId,
  );
}

void _moveToGeneralTent(GameController controller) {
  for (final direction in const [
    Direction.east,
    Direction.north,
    Direction.north,
    Direction.north,
    Direction.north,
    Direction.north,
    Direction.north,
    Direction.east,
    Direction.east,
    Direction.east,
  ]) {
    controller.dispatch(GameAction.move(direction));
  }
}

void _moveFromArmoryToGeneral(GameController controller) {
  for (final direction in const [
    Direction.east,
    Direction.east,
    Direction.east,
    Direction.east,
  ]) {
    controller.dispatch(GameAction.move(direction));
  }
}
