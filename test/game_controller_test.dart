import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/direction.dart';
import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/models/quest_definition.dart';
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
    expect(controller.questViews().single.steps.map((step) => step.status), [
      QuestStepStatus.completed,
      QuestStepStatus.current,
      QuestStepStatus.pending,
      QuestStepStatus.pending,
    ]);
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
      isTrue,
    );
    expect(controller.questViews().single.steps.map((step) => step.status), [
      QuestStepStatus.completed,
      QuestStepStatus.completed,
      QuestStepStatus.current,
      QuestStepStatus.pending,
    ]);

    _moveToDungeon(controller);
    controller.dispatch(
      const GameAction.selectDialogue('xiao_juan', 'rescue_xiao_juan'),
    );

    expect(controller.state.npcStates['xiao_juan']?.isFollowing, isTrue);
    expect(controller.questViews().single.steps.map((step) => step.status), [
      QuestStepStatus.completed,
      QuestStepStatus.completed,
      QuestStepStatus.completed,
      QuestStepStatus.current,
    ]);

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
    expect(controller.state.player.silver, 20);
    expect(controller.state.player.experience, 0);
    expect(controller.state.npcStates['old_liu']?.isRemoved, isTrue);
    expect(controller.state.npcStates['xiao_juan']?.isRemoved, isTrue);
    expect(controller.questViews().single.steps.map((step) => step.status), [
      QuestStepStatus.completed,
      QuestStepStatus.completed,
      QuestStepStatus.completed,
      QuestStepStatus.completed,
    ]);
    expect(controller.state.log.last, contains('完成委托'));
  });

  test('player can study parry book to learn basic parry', () {
    final controller = GameController(repository: repository);

    _completeRescueQuest(controller);
    controller.dispatch(const GameAction.studyItem('parry_book'));

    expect(controller.state.learnedSkillIds, contains('parry'));
    expect(controller.learnedSkills().single.name, '基础招架');
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
    expect(repository.roomsInArea(room.areaId), hasLength(3));
    expect(controller.state.visitedRoomIds, contains('yellow_road'));
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
    expect(controller.state.player.silver, 100);
    expect(controller.state.player.level, 1);
    expect(controller.state.player.experience, 70);
    expect(controller.state.player.hp, 80);
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
    Direction.up,
    Direction.east,
    Direction.east,
  ]) {
    controller.dispatch(GameAction.move(direction));
  }
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
