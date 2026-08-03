import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/direction.dart';
import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/models/innate_attributes.dart';
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

  test('new story uses the original Snow Pavilion inn opening', () {
    final state = repository.createInitialState();

    expect(state.currentRoomId, 'snow_inn');
    expect(state.player.potential, 99);
    expect(state.player.silver, 0);
    expect(state.inventoryItemIds, contains('plain_cloth'));
    expect(state.equippedItemIds.values, contains('plain_cloth'));
    expect(state.skillProgress, isEmpty);
    expect(
      repository
          .visibleNpcsInRoom(state, state.currentRoomId)
          .map((npc) => npc.id),
      containsAll([
        'snow_inn_waiter',
        'snow_inn_traveller',
        'snow_inn_traveller_2',
      ]),
    );
  });

  test('Snow Pavilion main street reaches the original town services', () {
    final controller = GameController(repository: repository);

    expect(
      repository
          .room('snow_inn')
          .availableActions(controller.state)
          .map((action) => action.id),
      contains('read_snow_inn_sign'),
    );

    controller.dispatch(const GameAction.move(Direction.east));
    expect(
      repository
          .visibleNpcsInRoom(controller.state, 'snow_square')
          .map((npc) => npc.id),
      containsAll([
        'snow_square_blade_traveller',
        'snow_square_blade_traveller_2',
        'snow_square_blade_traveller_3',
      ]),
    );
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.west));
    expect(controller.state.currentRoomId, 'snow_bank');
    expect(
      repository.visibleNpcsInRoom(controller.state, 'snow_bank').single.name,
      '安惜迩',
    );

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.west));
    expect(controller.state.currentRoomId, 'snow_smithy');
    expect(
      repository.npc('snow_smith_wang').shop?.products.single.itemId,
      'snow_smith_hammer',
    );

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.west));
    expect(controller.state.currentRoomId, 'snow_herbshop');
    expect(repository.npc('snow_herbalist_yang').shop?.products.length, 2);
    expect(
      repository
          .room('snow_herbshop')
          .availableActions(controller.state)
          .map((action) => action.id),
      containsAll(['read_herbshop_sign', 'inspect_herbshop_cabinet']),
    );

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'snow_hockshop');
    controller.dispatch(const GameAction.move(Direction.west));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.west));
    expect(controller.state.currentRoomId, 'snow_postoffice');

    controller.replaceState(
      controller.state.copyWith(currentRoomId: 'snow_square'),
    );
    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'snow_temple');
    controller.dispatch(const GameAction.move(Direction.south));
    expect(controller.state.currentRoomId, 'snow_east_path1');
  });

  test(
    'Snow Pavilion east mountain road reaches the original Lingxin Temple',
    () {
      final initialState = repository.createInitialState().copyWith(
        currentRoomId: 'snow_east_mountain_road',
        visitedRoomIds: {'snow_inn', 'snow_east_mountain_road'},
      );
      final controller = GameController(
        repository: repository,
        initialState: initialState,
      );

      controller.dispatch(const GameAction.move(Direction.east));
      expect(controller.state.currentRoomId, 'temple_sroad');
      final templeRoad = repository.room(controller.state.currentRoomId);
      expect(repository.area(templeRoad.areaId).id, 'temple');
      expect(templeRoad.outdoorAreaId, 'temple');

      for (final direction in const [
        Direction.eastup,
        Direction.northup,
        Direction.eastup,
        Direction.northup,
        Direction.east,
        Direction.north,
        Direction.north,
        Direction.north,
      ]) {
        controller.dispatch(GameAction.move(direction));
      }

      expect(controller.state.currentRoomId, 'temple_main_hall');
      expect(
        repository
            .visibleNpcsInRoom(controller.state, 'temple_main_hall')
            .map((npc) => npc.id),
        containsAll(['temple_taolord', 'temple_trainer', 'temple_tfighter']),
      );
      expect(
        repository
            .room('temple_main_hall')
            .availableActions(controller.state)
            .map((action) => action.id),
        contains('read_taoist_board'),
      );
    },
  );

  test('Lingxin Temple library opens for Maoshan disciples only', () {
    final initialState = repository.createInitialState().copyWith(
      currentRoomId: 'temple_main_hall',
      visitedRoomIds: {'snow_inn', 'temple_main_hall'},
    );
    final controller = GameController(
      repository: repository,
      initialState: initialState,
    );

    controller.replaceState(
      controller.state.copyWith(
        currentRoomId: 'temple_road2',
        visitedRoomIds: {...controller.state.visitedRoomIds, 'temple_road2'},
      ),
    );
    expect(
      repository.room('temple_road2').availableExits(controller.state),
      isNot(contains(Direction.enter)),
    );
    expect(
      repository
          .visibleNpcsInRoom(controller.state, 'temple_road2')
          .map((npc) => npc.id),
      containsAll([
        'temple_guard_taoist',
        'temple_guard_taoist2',
        'temple_guard_taoist3',
        'temple_taoist_guard',
        'temple_taoist_guard2',
        'temple_taoist_guard3',
      ]),
    );
    expect(
      repository
          .room('temple_road2')
          .availableActions(controller.state)
          .map((action) => action.id),
      contains('read_temple_library_slab'),
    );

    controller.dispatch(
      const GameAction.performRoomAction('read_temple_library_slab'),
    );
    expect(controller.state.log.last, contains('非茅山弟子不得进入'));

    controller.replaceState(
      controller.state.copyWith(currentRoomId: 'temple_main_hall'),
    );
    controller.dispatch(const GameAction.apprenticeTo('temple_taolord'));
    expect(controller.state.apprenticeship?.familyId, 'maoshan_taoist');
    expect(controller.state.apprenticeship?.generation, 6);

    controller.replaceState(
      controller.state.copyWith(
        currentRoomId: 'temple_road2',
        visitedRoomIds: {...controller.state.visitedRoomIds, 'temple_road2'},
      ),
    );
    expect(
      repository.room('temple_road2').availableExits(controller.state),
      containsPair(Direction.enter, 'temple_book_room1'),
    );
    controller.dispatch(const GameAction.move(Direction.enter));
    expect(controller.state.currentRoomId, 'temple_book_room1');
    controller.dispatch(const GameAction.move(Direction.up));
    expect(controller.state.currentRoomId, 'temple_book_room2');
    expect(
      repository
          .visibleItemsInRoom(controller.state, 'temple_book_room2')
          .map((item) => item.id),
      containsAll(['temple_magic_book', 'temple_spells_book']),
    );
  });

  test('Lin Ji follows the original male-only apprentice rule', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'temple_main_hall',
        visitedRoomIds: {'snow_inn', 'temple_main_hall'},
        player: initialState.player.copyWith(gender: PlayerGender.female),
      ),
    );

    controller.dispatch(const GameAction.apprenticeTo('temple_taolord'));

    expect(controller.state.apprenticeship, isNull);
    expect(controller.state.log.last, contains('不便收女徒'));
  });

  test('Lin Ji carries the original Taoist master equipment', () {
    final dropItemIds = repository.npc('temple_taolord').combat?.dropItemIds;

    expect(
      dropItemIds,
      containsAll([
        'temple_wangzhou_sword',
        'temple_taolord_robe',
        'temple_trimystic_hat',
        'temple_cloudy_shoes',
      ]),
    );
  });

  test(
    'Snow Pavilion academy and weapon storage follow original room layout',
    () {
      final controller = GameController(repository: repository);

      controller.dispatch(const GameAction.move(Direction.east));
      controller.dispatch(const GameAction.move(Direction.south));
      controller.dispatch(const GameAction.move(Direction.west));
      controller.dispatch(const GameAction.move(Direction.south));
      expect(controller.state.currentRoomId, 'snow_academy');
      expect(
        repository
            .visibleNpcsInRoom(controller.state, 'snow_academy')
            .map((npc) => npc.id),
        contains('snow_teacher_wei'),
      );

      controller.replaceState(
        controller.state.copyWith(currentRoomId: 'chunfeng_training_ground'),
      );
      controller.dispatch(const GameAction.move(Direction.north));
      expect(controller.state.currentRoomId, 'chunfeng_weapon_storage');
      expect(
        repository
            .room('chunfeng_weapon_storage')
            .availableExits(controller.state),
        isNot(contains(Direction.down)),
      );

      controller.dispatch(
        const GameAction.performRoomAction('push_weapon_shelf'),
      );
      expect(
        controller.state.questFlags,
        contains('chunfeng_secret_storage_opened'),
      );
      expect(
        repository
            .room('chunfeng_weapon_storage')
            .availableExits(controller.state),
        contains(Direction.down),
      );

      controller.dispatch(const GameAction.move(Direction.down));
      controller.dispatch(const GameAction.pickUp('snow_round_shield'));
      expect(controller.state.currentRoomId, 'chunfeng_secret_storage');
      expect(controller.state.inventoryItemIds, contains('snow_round_shield'));
    },
  );

  test(
    'Snow Pavilion inn rooms and workplace are mapped from original rooms',
    () {
      final controller = GameController(repository: repository);

      controller.dispatch(const GameAction.move(Direction.up));
      expect(controller.state.currentRoomId, 'snow_inn_second_floor');
      expect(
        repository
            .visibleNpcsInRoom(controller.state, 'snow_inn_second_floor')
            .map((npc) => npc.id),
        containsAll([
          'snow_rat',
          'snow_rat_2',
          'snow_rat_3',
          'snow_rat_4',
          'snow_rat_5',
          'snow_rat_6',
        ]),
      );

      controller.dispatch(const GameAction.move(Direction.west));
      expect(controller.state.currentRoomId, 'snow_inn_west_room');
      controller.dispatch(const GameAction.move(Direction.east));
      controller.dispatch(const GameAction.move(Direction.north));
      expect(controller.state.currentRoomId, 'snow_inn_north_room');
      controller.dispatch(const GameAction.move(Direction.south));
      controller.dispatch(const GameAction.move(Direction.east));
      expect(controller.state.currentRoomId, 'snow_inn_east_room');

      controller.replaceState(
        controller.state.copyWith(currentRoomId: 'snow_main_street2'),
      );
      controller.dispatch(const GameAction.move(Direction.east));
      expect(controller.state.currentRoomId, 'snow_workplace');
      expect(
        repository
            .room('snow_workplace')
            .availableActions(controller.state)
            .map((action) => action.id),
        containsAll(['read_workplace_sign', 'work_at_snow_workplace']),
      );
      expect(
        repository
            .visibleNpcsInRoom(controller.state, 'snow_workplace')
            .map((npc) => npc.id),
        contains('snow_worker'),
      );

      final silverBeforeWork = controller.state.player.silver;
      final hpBeforeWork = controller.state.player.hp;
      final spiritBeforeWork = controller.state.player.spirit;
      controller.dispatch(
        const GameAction.performRoomAction('work_at_snow_workplace'),
      );
      expect(controller.state.player.silver, silverBeforeWork + 1);
      expect(controller.state.player.hp, hpBeforeWork - 8);
      expect(controller.state.player.spirit, spiritBeforeWork - 12);

      controller.replaceState(
        controller.state.copyWith(
          player: controller.state.player.copyWith(hp: 8, spirit: 0),
        ),
      );
      final silverBeforeFailedWork = controller.state.player.silver;
      controller.dispatch(
        const GameAction.performRoomAction('work_at_snow_workplace'),
      );
      expect(controller.state.player.silver, silverBeforeFailedWork);
      expect(controller.state.log.last, contains('疲惫'));
    },
  );

  test('giving a bone makes the Snow Pavilion dog follow the player', () {
    final initialState = repository.createInitialState().copyWith(
      currentRoomId: 'snow_east_path2',
      visitedRoomIds: {'snow_inn', 'snow_east_path2'},
      inventoryItemIds: ['snow_bone', 'snow_bone'],
    );
    final controller = GameController(
      repository: repository,
      initialState: initialState,
    );

    expect(
      controller
          .giveItemOptionsFor('snow_wild_dog')
          .map((option) => option.itemId),
      contains('snow_bone'),
    );

    controller.dispatch(
      const GameAction.giveItem('snow_wild_dog', 'snow_bone'),
    );
    expect(controller.state.inventory.countOf('snow_bone'), 1);
    expect(controller.state.npcStates['snow_wild_dog']?.isFollowing, isTrue);
    expect(
      controller.state.npcStates['snow_wild_dog']?.valueFor('fedCount'),
      1,
    );

    expect(
      controller
          .giveItemOptionsFor('snow_wild_dog')
          .map((option) => option.itemId),
      contains('snow_bone'),
    );
    controller.dispatch(
      const GameAction.giveItem('snow_wild_dog', 'snow_bone'),
    );
    expect(controller.state.inventory.countOf('snow_bone'), 0);
    expect(
      controller.state.npcStates['snow_wild_dog']?.valueFor('fedCount'),
      2,
    );

    controller.dispatch(const GameAction.move(Direction.west));
    expect(controller.state.currentRoomId, 'snow_east_path1');
    expect(
      controller.state.npcStates['snow_wild_dog']?.roomId,
      'snow_east_path1',
    );
  });

  test('Wei Wuji requires the original tuition before teaching literacy', () {
    final initialState = repository.createInitialState().copyWith(
      currentRoomId: 'snow_academy',
      visitedRoomIds: {'snow_inn', 'snow_academy'},
      player: repository.createInitialState().player.copyWith(silver: 4),
    );
    final controller = GameController(
      repository: repository,
      initialState: initialState,
    );

    controller.dispatch(
      const GameAction.learnFromNpc('snow_teacher_wei', 'literate'),
    );
    expect(controller.state.skillProgress, isNot(contains('literate')));
    expect(controller.state.log.last, contains('不记得收过你'));

    controller.dispatch(
      const GameAction.selectDialogue('snow_teacher_wei', 'pay_tuition'),
    );
    expect(controller.state.player.silver, 4);
    expect(
      controller.state.npcStates['snow_teacher_wei']?.valueFor('student'),
      0,
    );
    expect(controller.state.log.last, contains('诚意不够'));

    controller.replaceState(
      controller.state.copyWith(
        player: controller.state.player.copyWith(silver: 5),
      ),
    );
    controller.dispatch(
      const GameAction.selectDialogue('snow_teacher_wei', 'pay_tuition'),
    );
    expect(controller.state.player.silver, 0);
    expect(
      controller.state.npcStates['snow_teacher_wei']?.valueFor('student'),
      1,
    );
    expect(
      controller
          .dialogueOptionsFor('snow_teacher_wei')
          .map((option) => option.id),
      isNot(contains('pay_tuition')),
    );

    controller.dispatch(
      const GameAction.learnFromNpc('snow_teacher_wei', 'literate'),
    );
    expect(controller.state.skillProgress['literate']?.level, 1);
  });

  test('Snow Pavilion worker can be hired and returns when duty ends', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'snow_workplace',
        visitedRoomIds: {...baseState.visitedRoomIds, 'snow_workplace'},
        player: baseState.player.copyWith(silver: 1),
      ),
    );

    controller.dispatch(
      const GameAction.selectDialogue('snow_worker', 'hire_worker'),
    );
    final hiredState = controller.state.npcStates['snow_worker'];
    expect(controller.state.player.silver, 0);
    expect(hiredState?.isFollowing, isTrue);
    expect(hiredState?.followUntilTurn, 12);
    expect(hiredState?.followReturnRoomId, 'snow_workplace');
    expect(hiredState?.valueFor('employed'), 1);
    expect(
      controller.dialogueOptionsFor('snow_worker').map((option) => option.id),
      isNot(contains('hire_worker')),
    );

    controller.dispatch(const GameAction.move(Direction.west));
    expect(
      controller.state.npcStates['snow_worker']?.roomId,
      'snow_main_street2',
    );
    controller.replaceState(controller.state.copyWith(worldTurn: 11));
    controller.dispatch(const GameAction.move(Direction.north));

    final endedState = controller.state.npcStates['snow_worker'];
    expect(controller.state.worldTurn, 12);
    expect(endedState?.isFollowing, isFalse);
    expect(endedState?.roomId, 'snow_workplace');
    expect(endedState?.followUntilTurn, isNull);
    expect(endedState?.followReturnRoomId, isNull);
    expect(endedState?.valueFor('employed'), 0);
    expect(controller.state.log, contains(contains('下工时间到了')));
  });

  test('Pang Yi requires the original one hundred tael hiring fee', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'chunfeng_guest_room',
        visitedRoomIds: {...baseState.visitedRoomIds, 'chunfeng_guest_room'},
        player: baseState.player.copyWith(silver: 99),
      ),
    );

    controller.dispatch(
      const GameAction.selectDialogue('pang_yi', 'hire_pang_yi'),
    );
    expect(controller.state.player.silver, 99);
    expect(controller.state.npcStates['pang_yi']?.isFollowing, isFalse);

    controller.replaceState(
      controller.state.copyWith(
        player: controller.state.player.copyWith(silver: 100),
      ),
    );
    controller.dispatch(
      const GameAction.selectDialogue('pang_yi', 'hire_pang_yi'),
    );
    expect(controller.state.player.silver, 0);
    expect(controller.state.npcStates['pang_yi']?.isFollowing, isTrue);
    expect(controller.state.npcStates['pang_yi']?.followUntilTurn, 12);
    expect(controller.state.npcStates['pang_yi']?.valueFor('employed'), 1);
  });

  test('defeating a Snow Pavilion dog leaves a bone to pick up', () {
    final initialState = repository.createInitialState().copyWith(
      currentRoomId: 'snow_stone_road',
      visitedRoomIds: {'snow_inn', 'snow_stone_road'},
    );
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        player: initialState.player.copyWith(hp: 300, maxHp: 300),
      ),
    );

    _defeatNpc(controller, 'snow_crazy_dog');
    expect(
      controller.repository
          .visibleItemsInRoom(controller.state, 'snow_stone_road')
          .map((item) => item.id),
      contains('snow_bone'),
    );

    controller.dispatch(const GameAction.pickUp('snow_bone'));
    expect(controller.state.inventoryItemIds, contains('snow_bone'));
    expect(
      controller.repository
          .visibleItemsInRoom(controller.state, 'snow_stone_road')
          .map((item) => item.id),
      isNot(contains('snow_bone')),
    );
  });

  test('Snow Pavilion scavenger accepts any carried item', () {
    final initialState = repository.createInitialState().copyWith(
      currentRoomId: 'snow_main_street2',
      visitedRoomIds: {'snow_inn', 'snow_main_street2'},
      inventoryItemIds: ['snow_bone'],
    );
    final controller = GameController(
      repository: repository,
      initialState: initialState,
    );

    final giveOptions = controller.giveItemOptionsFor('snow_scavenger');
    expect(giveOptions.map((option) => option.itemId), contains('snow_bone'));
    expect(giveOptions.map((option) => option.label), contains('给他骨头'));

    controller.dispatch(
      const GameAction.giveItem('snow_scavenger', 'snow_bone'),
    );
    expect(controller.state.inventoryItemIds, isNot(contains('snow_bone')));
    expect(controller.state.log.last, contains('多谢'));
  });

  test('Snow Pavilion temple donation consumes silver', () {
    final initialState = repository.createInitialState().copyWith(
      currentRoomId: 'snow_temple',
      visitedRoomIds: {'snow_inn', 'snow_temple'},
    );
    final controller = GameController(
      repository: repository,
      initialState: initialState,
    );

    controller.dispatch(
      const GameAction.performRoomAction('donate_to_snow_temple'),
    );
    expect(controller.state.player.silver, 0);
    expect(controller.state.log.last, contains('一两银子也没有'));

    controller.replaceState(
      controller.state.copyWith(currentRoomId: 'snow_workplace'),
    );
    controller.dispatch(
      const GameAction.performRoomAction('work_at_snow_workplace'),
    );
    expect(controller.state.player.silver, 1);

    controller.replaceState(
      controller.state.copyWith(currentRoomId: 'snow_temple'),
    );
    controller.dispatch(
      const GameAction.performRoomAction('donate_to_snow_temple'),
    );
    expect(controller.state.player.silver, 0);
    expect(controller.state.log.last, contains('功德箱'));
  });

  test(
    'Snow Pavilion temple prevents combat like the original no_fight room',
    () {
      final initialState = repository.createInitialState();
      final crazyDogState = initialState.npcStates['snow_crazy_dog'];
      final controller = GameController(
        repository: repository,
        initialState: initialState.copyWith(
          currentRoomId: 'snow_temple',
          visitedRoomIds: {'snow_inn', 'snow_temple'},
          npcStates: {
            ...initialState.npcStates,
            if (crazyDogState != null)
              'snow_crazy_dog': crazyDogState.copyWith(roomId: 'snow_temple'),
          },
        ),
      );

      expect(repository.room('snow_temple').allowsCombat, isFalse);
      controller.dispatch(const GameAction.startCombat('snow_crazy_dog'));

      expect(controller.state.combat, isNull);
      expect(controller.state.log.last, contains('不是动手的地方'));
    },
  );

  test('Snow Pavilion keeps original outdoor room flags', () {
    expect(repository.room('snow_square').outdoorAreaId, 'snow');
    expect(repository.room('snow_square').isOutdoor, isTrue);
    expect(repository.room('snow_east_mountain_road').outdoorAreaId, 'snow');
    expect(repository.room('chunfeng_training_ground').outdoorAreaId, 'snow');
    expect(repository.room('snow_inn').isOutdoor, isFalse);
    expect(repository.room('snow_temple').isOutdoor, isFalse);
    expect(repository.room('snow_workplace').isOutdoor, isFalse);
  });

  test('moving through an exit updates current room and log', () {
    final controller = _controllerAtLiuHome(repository);

    controller.dispatch(const GameAction.move(Direction.south));

    expect(controller.state.currentRoomId, 'little_garden');
    expect(controller.state.visitedRoomIds, contains('little_garden'));
    expect(controller.state.log.last, contains('花园'));
  });

  test('picking up an item moves it into inventory', () {
    final controller = _controllerAtLiuHome(repository);

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

  test('capital passage quest follows the original token event', () {
    final controller = _controllerAtLiuHome(repository);

    for (final direction in const [
      Direction.east,
      Direction.north,
      Direction.north,
      Direction.west,
      Direction.south,
      Direction.south,
      Direction.south,
    ]) {
      controller.dispatch(GameAction.move(direction));
    }
    expect(controller.state.currentRoomId, 'capital_north_gate');
    expect(
      repository.room('capital_north_gate').availableExits(controller.state),
      isNot(contains(Direction.north)),
    );

    controller.dispatch(
      const GameAction.selectDialogue(
        'capital_guard',
        'ask_about_leaving_capital',
      ),
    );
    expect(
      controller.state.questStatuses['capital_passage'],
      QuestStatus.active,
    );

    for (final direction in const [
      Direction.south,
      Direction.south,
      Direction.west,
      Direction.west,
      Direction.north,
    ]) {
      controller.dispatch(GameAction.move(direction));
    }
    controller.dispatch(
      const GameAction.performRoomAction('search_abandoned_garden'),
    );
    expect(controller.state.inventoryItemIds, contains('capital_exit_token'));
    expect(controller.state.questFlags, contains('capital_exit_token_found'));

    for (final direction in const [
      Direction.south,
      Direction.east,
      Direction.east,
      Direction.north,
      Direction.north,
    ]) {
      controller.dispatch(GameAction.move(direction));
    }
    controller.dispatch(
      const GameAction.giveItem('capital_guard', 'capital_exit_token'),
    );

    expect(
      controller.state.questStatuses['capital_passage'],
      QuestStatus.completed,
    );
    expect(
      controller.state.inventoryItemIds,
      isNot(contains('capital_exit_token')),
    );
    expect(controller.state.questFlags, contains('capital_passage_registered'));
    expect(
      repository.room('capital_north_gate').availableExits(controller.state),
      contains(Direction.north),
    );
  });

  test('original capital routes do not require an exam storyline', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'capital_taibai_inn',
        visitedRoomIds: {...initialState.visitedRoomIds, 'capital_taibai_inn'},
      ),
    );

    controller.dispatch(const GameAction.move(Direction.up));
    expect(controller.state.currentRoomId, 'capital_taibai_upstairs');
    controller.replaceState(
      controller.state.copyWith(currentRoomId: 'capital_training_ground'),
    );
    controller.dispatch(const GameAction.move(Direction.north));
    expect(controller.state.currentRoomId, 'capital_meridian_gate');
    expect(
      repository.visibleNpcsInRoom(controller.state, 'capital_training_ground'),
      isEmpty,
    );
  });

  test('capital route reaches the original Ministry manor', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'capital_east_huguo_street',
        visitedRoomIds: {
          ...initialState.visitedRoomIds,
          'capital_east_huguo_street',
        },
      ),
    );

    controller.dispatch(const GameAction.move(Direction.north));
    expect(controller.state.currentRoomId, 'shangshu_gate');
    expect(
      repository
          .visibleNpcsInRoom(controller.state, 'shangshu_gate')
          .map((npc) => npc.id),
      contains('shangshu_gatekeeper'),
    );

    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'shangshu_yard');
    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'shangshu_hall');
    expect(
      repository
          .visibleNpcsInRoom(controller.state, 'shangshu_hall')
          .map((npc) => npc.id),
      contains('shangshu_yu'),
    );

    controller.dispatch(const GameAction.move(Direction.west));
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.move(Direction.south));
    expect(controller.state.currentRoomId, 'shangshu_garden');
    expect(
      repository
          .visibleNpcsInRoom(controller.state, 'shangshu_garden')
          .map((npc) => npc.id),
      contains('shangshu_gardener'),
    );
    controller.dispatch(
      const GameAction.selectDialogue('shangshu_gardener', 'ask_about_maoshan'),
    );
    expect(controller.state.log.last, contains('师门'));

    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'shangshu_inner_house');
    expect(
      repository
          .visibleNpcsInRoom(controller.state, 'shangshu_inner_house')
          .map((npc) => npc.id),
      contains('shangshu_qing_chen'),
    );
  });

  test('capital public shops and city gates are reachable', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'capital_bridge',
        visitedRoomIds: {...initialState.visitedRoomIds, 'capital_bridge'},
        player: initialState.player.copyWith(silver: 500),
      ),
    );

    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'capital_city_street11');
    controller.dispatch(const GameAction.move(Direction.north));
    expect(controller.state.currentRoomId, 'capital_boots_shop');
    expect(
      repository.npc('capital_shoer').shop?.products.map((item) => item.itemId),
      containsAll([
        'capital_deer_boots',
        'capital_elephant_boots',
        'capital_flower_boots',
      ]),
    );

    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.north));
    expect(controller.state.currentRoomId, 'capital_weapon_shop');
    controller.dispatch(
      const GameAction.buyItem('capital_weaponor', 'capital_wuqing_sword'),
    );
    expect(controller.state.inventoryItemIds, contains('capital_wuqing_sword'));

    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'capital_east_gate_1');

    controller.replaceState(
      controller.state.copyWith(currentRoomId: 'capital_west_street'),
    );
    controller.dispatch(const GameAction.move(Direction.west));
    expect(controller.state.currentRoomId, 'capital_city_street14');
    controller.dispatch(const GameAction.move(Direction.south));
    expect(controller.state.currentRoomId, 'capital_cloth_shop');
    expect(
      repository
          .npc('capital_clother')
          .shop
          ?.products
          .map((item) => item.itemId),
      containsAll([
        'capital_lady_dress',
        'capital_green_cloth',
        'capital_color_cloth',
      ]),
    );

    controller.replaceState(
      controller.state.copyWith(currentRoomId: 'capital_bridge'),
    );
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.move(Direction.south));
    expect(controller.state.currentRoomId, 'capital_south_gate');
  });

  test(
    'capital palace ring links Shenwu Gate, Meridian Gate, and manor wall',
    () {
      final initialState = repository.createInitialState();
      final controller = GameController(
        repository: repository,
        initialState: initialState.copyWith(
          currentRoomId: 'capital_altar',
          visitedRoomIds: {...initialState.visitedRoomIds, 'capital_altar'},
        ),
      );

      controller.dispatch(const GameAction.move(Direction.south));
      expect(controller.state.currentRoomId, 'capital_shenwu_gate');
      expect(
        repository
            .visibleNpcsInRoom(controller.state, 'capital_shenwu_gate')
            .map((npc) => npc.id),
        contains('capital_palace_guard'),
      );

      controller.dispatch(const GameAction.move(Direction.east));
      expect(controller.state.currentRoomId, 'capital_palace_east_street1');
      controller.dispatch(const GameAction.move(Direction.south));
      controller.dispatch(const GameAction.move(Direction.south));
      expect(controller.state.currentRoomId, 'capital_palace_east_street3');
      expect(
        repository
            .room('capital_palace_east_street3')
            .availableActions(controller.state)
            .map((action) => action.id),
        contains('climb_shangshu_wall'),
      );
      controller.dispatch(
        const GameAction.performRoomAction('climb_shangshu_wall'),
      );
      expect(controller.state.currentRoomId, 'capital_shangshu_wall');
      controller.dispatch(
        const GameAction.performRoomAction('jump_into_shangshu'),
      );
      expect(controller.state.currentRoomId, 'shangshu_abandoned_room');

      controller.replaceState(
        controller.state.copyWith(currentRoomId: 'capital_meridian_gate'),
      );
      controller.dispatch(const GameAction.move(Direction.west));
      expect(controller.state.currentRoomId, 'capital_palace_west_street4');
      controller.dispatch(const GameAction.move(Direction.west));
      expect(controller.state.currentRoomId, 'capital_xiangguo_gate');

      controller.replaceState(
        controller.state.copyWith(currentRoomId: 'capital_palace_west_street4'),
      );
      controller.dispatch(const GameAction.move(Direction.north));
      controller.dispatch(const GameAction.move(Direction.west));
      expect(controller.state.currentRoomId, 'capital_taibai_inn');
    },
  );

  test('waterfog mountain route reaches the fighter guild hall', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'snow_stone_road',
        visitedRoomIds: {...initialState.visitedRoomIds, 'snow_stone_road'},
      ),
    );

    for (final direction in const [
      Direction.north,
      Direction.west,
      Direction.west,
      Direction.west,
      Direction.north,
      Direction.north,
      Direction.east,
      Direction.north,
      Direction.north,
      Direction.west,
      Direction.north,
      Direction.north,
      Direction.north,
    ]) {
      controller.dispatch(GameAction.move(direction));
    }

    expect(controller.state.currentRoomId, 'waterfog_guildhall');
    expect(
      controller.state.visitedRoomIds,
      containsAll([
        'waterfog_sroad3',
        'waterfog_clifftop',
        'waterfog_frontyard',
        'waterfog_entrance',
      ]),
    );
    controller.dispatch(
      const GameAction.performRoomAction('join_fighter_guild'),
    );
    expect(controller.state.questFlags, contains('fighter_guild_member'));
  });

  test('waterfog monuments can be read without an invented quest', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'waterfog_wpath2',
        visitedRoomIds: {...initialState.visitedRoomIds, 'waterfog_wpath2'},
      ),
    );

    controller.dispatch(
      const GameAction.performRoomAction('read_honggu_stele'),
    );
    for (final direction in const [
      Direction.north,
      Direction.north,
      Direction.north,
      Direction.west,
    ]) {
      controller.dispatch(GameAction.move(direction));
    }
    controller.dispatch(
      const GameAction.performRoomAction('read_sword_tomb_monolith'),
    );
    expect(
      controller.state.questFlags,
      containsAll(['waterfog_honggu_stele_read', 'waterfog_sword_tomb_read']),
    );

    expect(
      controller.state.questStatuses,
      isNot(contains('waterfog_inscriptions')),
    );
  });

  test('old pine forest entrance connects both stable branches', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'snow_square',
        visitedRoomIds: {...initialState.visitedRoomIds, 'snow_square'},
      ),
    );

    for (final direction in const [
      Direction.south,
      Direction.east,
      Direction.east,
      Direction.east,
      Direction.south,
      Direction.south,
      Direction.south,
      Direction.east,
    ]) {
      controller.dispatch(GameAction.move(direction));
    }
    expect(controller.state.currentRoomId, 'oldpine_clearing');

    for (final direction in const [
      Direction.east,
      Direction.east,
      Direction.east,
    ]) {
      controller.dispatch(GameAction.move(direction));
    }
    expect(controller.state.currentRoomId, 'oldpine_east_path3');
    expect(
      repository
          .visibleNpcsInRoom(controller.state, controller.state.currentRoomId)
          .map((npc) => npc.id),
      contains('oldpine_maniac'),
    );

    for (final direction in const [
      Direction.west,
      Direction.west,
      Direction.west,
      Direction.north,
    ]) {
      controller.dispatch(GameAction.move(direction));
    }
    expect(controller.state.currentRoomId, 'oldpine_slope_path1');
    expect(
      repository
          .visibleNpcsInRoom(controller.state, controller.state.currentRoomId)
          .map((npc) => npc.id),
      contains('oldpine_bandit_scout'),
    );
  });

  test('old pine forest actions form a complete ravine route', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'oldpine_clearing',
        visitedRoomIds: {...initialState.visitedRoomIds, 'oldpine_clearing'},
      ),
    );

    controller.dispatch(
      const GameAction.performRoomAction('climb_ancient_pine'),
    );
    controller.dispatch(const GameAction.move(Direction.up));
    controller.dispatch(const GameAction.move(Direction.up));
    expect(controller.state.currentRoomId, 'oldpine_tree3');
    for (var step = 0; step < 3; step++) {
      controller.dispatch(const GameAction.move(Direction.down));
    }
    expect(controller.state.currentRoomId, 'oldpine_clearing');

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(
      const GameAction.performRoomAction('swing_below_stone_bridge'),
    );
    expect(controller.state.currentRoomId, 'oldpine_secret_entrance');
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.north));
    expect(controller.state.currentRoomId, 'oldpine_deep_passage');
    expect(
      repository
          .visibleNpcsInRoom(controller.state, controller.state.currentRoomId)
          .map((npc) => npc.id),
      contains('oldpine_venom_snake'),
    );

    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.move(Direction.south));
    for (var step = 0; step < 4; step++) {
      controller.dispatch(const GameAction.move(Direction.south));
    }
    expect(controller.state.currentRoomId, 'oldpine_lake');
    expect(
      repository
          .visibleNpcsInRoom(controller.state, controller.state.currentRoomId)
          .map((npc) => npc.id),
      contains('oldpine_giant_serpent'),
    );

    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(
      const GameAction.performRoomAction('climb_ravine_wall'),
    );
    controller.dispatch(
      const GameAction.performRoomAction('climb_out_of_ravine'),
    );
    expect(controller.state.currentRoomId, 'oldpine_east_path3');
  });

  test('old pine cave route rewards the original parry manual', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'oldpine_deep_passage',
        player: initialState.player.copyWith(hp: 400, maxHp: 400),
        visitedRoomIds: {
          ...initialState.visitedRoomIds,
          'oldpine_deep_passage',
        },
      ),
    );

    controller.dispatch(const GameAction.startCombat('oldpine_venom_snake'));
    for (var turn = 0; turn < 20 && controller.state.combat != null; turn++) {
      controller.dispatch(const GameAction.attack());
    }
    expect(
      controller.state.npcStates['oldpine_venom_snake']?.isDefeated,
      isTrue,
    );

    controller.dispatch(
      const GameAction.performRoomAction('climb_passage_stone'),
    );
    controller.dispatch(
      const GameAction.performRoomAction('descend_into_oldpine_caves'),
    );
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(
      const GameAction.performRoomAction('follow_cave_water_sound'),
    );
    expect(controller.state.currentRoomId, 'oldpine_cave5');

    controller.dispatch(
      const GameAction.performRoomAction('bury_oldpine_skeleton'),
    );
    expect(
      controller.state.inventoryItemIds,
      contains('oldpine_parry_essentials'),
    );
    expect(controller.state.questFlags, contains('oldpine_skeleton_buried'));
    expect(
      repository
          .room('oldpine_cave5')
          .availableActions(controller.state)
          .map((action) => action.id),
      isNot(contains('bury_oldpine_skeleton')),
    );

    controller.dispatch(
      const GameAction.performRoomAction('leave_oldpine_caves'),
    );
    expect(controller.state.currentRoomId, 'oldpine_waterfall');
  });

  test('old pine maze leads through the gated bandit keep', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'oldpine_east_path3',
        visitedRoomIds: {...initialState.visitedRoomIds, 'oldpine_east_path3'},
        player: initialState.player.copyWith(hp: 400, maxHp: 400),
        inventoryItemIds: ['hengbing_sword'],
      ),
    );
    controller.dispatch(const GameAction.equipItem('hengbing_sword'));

    controller.dispatch(
      const GameAction.performRoomAction('enter_oldpine_maze'),
    );
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'oldpine_keep_entrance');
    expect(
      repository.room('oldpine_keep_entrance').availableExits(controller.state),
      isNot(contains(Direction.east)),
    );

    _defeatNpc(controller, 'oldpine_keep_gate_guard');
    expect(
      repository.room('oldpine_keep_entrance').availableExits(controller.state),
      contains(Direction.east),
    );
    controller.dispatch(const GameAction.move(Direction.east));
    expect(
      repository.room('oldpine_keep_yard').availableExits(controller.state),
      isNot(contains(Direction.east)),
    );

    _defeatNpc(controller, 'oldpine_keep_yard_guard');
    _defeatNpc(controller, 'oldpine_bandit_leader');
    expect(
      repository.room('oldpine_keep_yard').availableExits(controller.state),
      contains(Direction.east),
    );
    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'oldpine_keep_hall');
    _defeatNpc(controller, 'oldpine_commander');
    expect(controller.state.npcStates['oldpine_commander']?.isDefeated, isTrue);
  });

  test('dropping an item moves it into the current room', () {
    final controller = _controllerAtLiuHome(repository);

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
    final controller = _controllerAtLiuHome(repository);

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
    final controller = _controllerAtLiuHome(repository);

    _completeRescueQuest(controller);
    controller.dispatch(const GameAction.studyItem('parry_book'));

    expect(controller.state.learnedSkillIds, contains('parry'));
    expect(
      controller.learnedSkills().map((skill) => skill.name),
      contains('基本招架'),
    );
  });

  test('player can study the ancient sword manual', () {
    final controller = _controllerAtLiuHome(repository);

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
      initialState: initialState.copyWith(
        inventoryItemIds: const ['old_book'],
        skillProgress: const {
          'literate': SkillProgress(level: 10, experience: 0),
        },
      ),
    );

    for (var study = 0; study < 4; study += 1) {
      controller.dispatch(const GameAction.studyItem('old_book'));
    }

    expect(controller.state.skillProgress['basic_sword']?.level, 2);
    expect(controller.state.skillProgress['basic_sword']?.experience, 26);
    expect(controller.state.log, contains(contains('Lv.2')));
  });

  test('original ice dragon has no invented timed special move', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        inventoryItemIds: const [],
        equippedItemIds: const {},
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(const GameAction.attack());
    controller.dispatch(const GameAction.attack());

    expect(controller.state.combat?.round, 2);
    expect(controller.state.player.hp, 70);
    expect(controller.state.log.last, isNot(contains('寒息')));
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
    expect(controller.state.currentRoomId, 'snow_inn');
    expect(controller.state.player.hp, 40);
    expect(controller.state.player.innerPower, 15);
    expect(controller.state.npcStates['white_ice_dragon']?.currentHp, 32);
    expect(controller.state.log.last, contains('昏迷'));
  });

  test('room actions can move the player through lake scenes', () {
    final controller = _controllerAtLiuHome(repository);

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.performRoomAction('paddle_to_lake'));
    controller.dispatch(const GameAction.performRoomAction('dive_into_lake'));

    expect(controller.state.currentRoomId, 'underwater_cave');
    expect(controller.state.visitedRoomIds, contains('jade_snail_lake_center'));
    expect(controller.state.log.last, contains('岩洞'));
  });

  test('player can cross from village into canyon area', () {
    final controller = _controllerAtLiuHome(repository);

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
    final controller = _controllerAtLiuHome(repository);

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
    expect(controller.state.inventoryItemIds, contains('deisword_manual'));
    expect(controller.state.inventoryItemIds, isNot(contains('general_seal')));
    expect(
      _questView(
        controller,
        'recover_general_seal',
      ).steps.every((step) => step.status == QuestStepStatus.completed),
      isTrue,
    );

    controller.replaceState(
      controller.state.copyWith(
        player: controller.state.player.copyWith(combatExperience: 40),
      ),
    );
    controller.dispatch(const GameAction.studyItem('canyon_old_sword'));
    controller.dispatch(const GameAction.studyItem('canyon_old_sword'));
    expect(controller.state.skillProgress['parry']?.level, 1);
    expect(controller.state.skillProgress['parry']?.experience, 62);
  });

  test('old Liu is not an apprentice master in the original content', () {
    final controller = _controllerAtLiuHome(repository);

    controller.dispatch(const GameAction.apprenticeTo('old_liu'));
    controller.dispatch(
      const GameAction.learnFromNpc('old_liu', 'basic_sword'),
    );

    expect(controller.state.apprenticeship, isNull);
    expect(controller.state.skillProgress['basic_sword'], isNull);
  });

  test('leaving a family records betrayal and halves skill levels', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        apprenticeship: const ApprenticeshipState(
          familyId: 'fengshan_sword',
          masterNpcId: 'liu_chunfeng',
          generation: 2,
          title: '弟子',
          contribution: 8,
        ),
        skillProgress: const {
          'literate': SkillProgress(level: 10, experience: 0),
          'basic_sword': SkillProgress(level: 12, experience: 40),
        },
      ),
    );

    controller.dispatch(const GameAction.leaveFamily());

    expect(controller.state.apprenticeship, isNull);
    expect(controller.state.player.betrayalCount, 1);
    expect(controller.state.skillProgress['basic_sword']?.level, 6);
    expect(controller.state.skillProgress['basic_sword']?.experience, 0);
  });

  test('rescuing Xiao Juan gives the original item rewards only', () {
    final controller = _controllerAtLiuHome(repository);

    _completeRescueQuest(controller);

    expect(controller.state.apprenticeship, isNull);
    expect(
      controller.state.inventoryItemIds,
      containsAll(['hengbing_sword', 'parry_book']),
    );
  });

  test('old Liu does not teach six chaos sword', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'liu_home',
        visitedRoomIds: {...initialState.visitedRoomIds, 'liu_home'},
        inventoryItemIds: const ['hengbing_sword'],
        equippedWeaponId: 'hengbing_sword',
        skillProgress: const {
          'literate': SkillProgress(level: 10, experience: 0),
          'basic_sword': SkillProgress(level: 5, experience: 0),
        },
      ),
    );

    controller.dispatch(
      const GameAction.learnFromNpc('old_liu', 'six_chaos_sword'),
    );

    expect(controller.state.skillProgress['six_chaos_sword'], isNull);
  });

  test('studying requires literacy and enough combat experience', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        inventoryItemIds: const ['canyon_old_sword'],
        skillProgress: const {},
      ),
    );

    controller.dispatch(const GameAction.studyItem('canyon_old_sword'));
    expect(controller.state.log.last, contains('不识字'));

    controller.replaceState(
      controller.state.copyWith(
        skillProgress: const {
          'literate': SkillProgress(level: 10, experience: 0),
        },
      ),
    );
    controller.dispatch(const GameAction.studyItem('canyon_old_sword'));
    expect(controller.state.log.last, contains('实战经验不足'));
  });

  test('Lingxin Temple books teach original magic and spells basics', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        inventoryItemIds: const ['temple_magic_book', 'temple_spells_book'],
        player: initialState.player.copyWith(combatExperience: 100),
        skillProgress: const {
          'literate': SkillProgress(level: 10, experience: 0),
        },
      ),
    );

    controller.dispatch(const GameAction.studyItem('temple_magic_book'));
    controller.dispatch(const GameAction.studyItem('temple_spells_book'));

    expect(controller.state.learnedSkillIds, containsAll(['magic', 'spells']));
  });

  test('Lingxin Temple original equipment can be found and dropped', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'temple_training_room',
        visitedRoomIds: {'snow_inn', 'temple_training_room'},
      ),
    );

    controller.dispatch(const GameAction.pickUp('temple_bamboo_broom'));
    controller.dispatch(const GameAction.equipItem('temple_bamboo_broom'));

    expect(controller.state.inventoryItemIds, contains('temple_bamboo_broom'));
    expect(controller.state.equippedWeaponId, 'temple_bamboo_broom');
    expect(controller.characterStats().attack, greaterThan(5));

    controller.replaceState(
      controller.state.copyWith(
        currentRoomId: 'temple_road2',
        visitedRoomIds: {...controller.state.visitedRoomIds, 'temple_road2'},
        player: controller.state.player.copyWith(hp: 1000, maxHp: 1000),
      ),
    );
    _defeatNpc(controller, 'temple_taoist_guard');

    expect(
      repository
          .visibleItemsInRoom(controller.state, 'temple_road2')
          .map((item) => item.id),
      containsAll(['temple_bagua_robe', 'temple_jade_hat']),
    );
  });

  test('practicing an enabled special skill consumes vitals', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        inventoryItemIds: const ['hengbing_sword'],
        equippedWeaponId: 'hengbing_sword',
        player: initialState.player.copyWith(innerPower: 50, maxInnerPower: 50),
        skillProgress: const {
          'literate': SkillProgress(level: 10, experience: 0),
          'basic_sword': SkillProgress(level: 10, experience: 0),
          'deisword': SkillProgress(level: 5, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.sword: 'deisword'},
      ),
    );

    controller.dispatch(const GameAction.practiceSkill(SkillUsage.sword));

    expect(controller.state.player.hp, 65);
    expect(controller.state.player.innerPower, 45);
    expect(controller.state.skillProgress['deisword']?.experience, 12);
    expect(controller.state.log, contains(contains('演练')));
  });

  test('player can buy, sell, and use melon', () {
    final controller = _controllerAtLiuHome(repository);

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
        currentRoomId: 'liu_home',
        visitedRoomIds: {...initialState.visitedRoomIds, 'liu_home'},
        player: initialState.player.copyWith(silver: 20),
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

  test('buying duplicate items stacks them and selling removes one', () {
    final controller = _controllerAtLiuHome(repository);

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.buyItem('meloner', 'water_melon'));
    controller.dispatch(const GameAction.buyItem('meloner', 'water_melon'));

    expect(controller.state.inventory.countOf('water_melon'), 2);

    controller.dispatch(const GameAction.sellItem('meloner', 'water_melon'));

    expect(controller.state.inventory.countOf('water_melon'), 1);
  });

  test('player can equip a weapon and defeat the ice dragon', () {
    final controller = _controllerAtLiuHome(repository);

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
    expect(controller.state.player.silver, 28);
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
    expect(controller.state.log, contains(contains('白鳞冰龙')));
    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));

    expect(controller.state.combat, isNull);

    for (var index = 0; index < 3; index += 1) {
      controller.dispatch(const GameAction.move(Direction.east));
      controller.dispatch(const GameAction.move(Direction.west));
    }

    expect(controller.state.npcStates['white_ice_dragon']?.isDefeated, isTrue);
    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    expect(controller.state.combat, isNull);
  });

  test('enemy damage persists after fleeing and restarting combat', () {
    final controller = _controllerAtLiuHome(repository);

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

GameController _controllerAtLiuHome(GameDefinitionRepository repository) {
  final initialState = repository.createInitialState();
  return GameController(
    repository: repository,
    initialState: initialState.copyWith(
      currentRoomId: 'liu_home',
      visitedRoomIds: {...initialState.visitedRoomIds, 'liu_home'},
      player: initialState.player.copyWith(potential: 20, silver: 20),
      inventoryItemIds: const [],
      equippedItemIds: const {},
      skillProgress: const {
        'literate': SkillProgress(level: 10, experience: 0),
      },
    ),
  );
}

void _defeatNpc(GameController controller, String npcId) {
  controller.dispatch(GameAction.startCombat(npcId));
  for (var turn = 0; turn < 100 && controller.state.combat != null; turn++) {
    controller.dispatch(const GameAction.attack());
  }
  expect(controller.state.npcStates[npcId]?.isDefeated, isTrue);
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
