import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/direction.dart';
import 'package:eastern_stories/game/models/corpse_state.dart';
import 'package:eastern_stories/game/models/equipment_slot.dart';
import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/models/innate_attributes.dart';
import 'package:eastern_stories/game/models/quest_definition.dart';
import 'package:eastern_stories/game/models/skill_definition.dart';
import 'package:eastern_stories/game/models/skill_progress.dart';
import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:eastern_stories/game/systems/npc_instance_system.dart';
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
    final initialState = repository.createInitialState();
    final state = initialState.npcStates['temple_taolord']!;
    final controller = GameController(
      repository: repository,
      initialState: initialState,
    );

    expect(
      state.itemCounts.keys,
      containsAll([
        'temple_wangzhou_sword',
        'temple_taolord_robe',
        'temple_trimystic_hat',
        'temple_cloudy_shoes',
      ]),
    );
    expect(
      state.equippedItemIds[EquipmentSlot.weapon],
      'temple_wangzhou_sword',
    );
    expect(state.equippedItemIds[EquipmentSlot.body], 'temple_taolord_robe');
    expect(state.equippedItemIds[EquipmentSlot.head], 'temple_trimystic_hat');
    expect(state.equippedItemIds[EquipmentSlot.feet], 'temple_cloudy_shoes');
    expect(controller.npcCombatStats('temple_taolord').attack, 66);
    expect(controller.npcCombatStats('temple_taolord').defense, 23);

    controller.replaceState(
      controller.state.copyWith(
        npcStates: {
          ...controller.state.npcStates,
          'temple_taolord': state.copyWith(equippedItemIds: const {}),
        },
      ),
    );
    expect(controller.npcCombatStats('temple_taolord').attack, 22);
    expect(controller.npcCombatStats('temple_taolord').defense, 18);
    expect(
      controller.npcCombatStats('temple_taoist_guard').attack,
      repository.npc('temple_taoist_guard').combat?.attack,
    );
  });

  test('Maoshan NPCs carry and wear their original equipment', () {
    final controller = GameController(repository: repository);
    final trainer = controller.state.npcStates['temple_trainer']!;
    final protector = controller.state.npcStates['temple_tfighter']!;
    final xuanZhen = controller.state.npcStates['temple_little_taoist1']!;
    final oldTaoist = controller.state.npcStates['temple_old_taoist']!;
    final libraryGuard = controller.state.npcStates['temple_guard_taoist']!;

    expect(
      trainer.itemCounts.keys,
      containsAll([
        'temple_longsword',
        'temple_magic_book',
        'temple_spells_book',
      ]),
    );
    expect(trainer.equippedItemIds[EquipmentSlot.weapon], 'temple_longsword');
    expect(trainer.itemCounts, isNot(contains('temple_whisk')));
    expect(controller.npcCombatStats('temple_trainer').attack, 35);

    expect(protector.itemCounts.keys, orderedEquals(['temple_longsword']));
    expect(protector.equippedItemIds[EquipmentSlot.weapon], 'temple_longsword');
    expect(controller.npcCombatStats('temple_tfighter').attack, 38);

    expect(
      xuanZhen.equippedItemIds,
      containsPair(EquipmentSlot.weapon, 'temple_bamboo_broom'),
    );
    expect(controller.npcCombatStats('temple_little_taoist1').attack, 6);
    expect(controller.npcCombatStats('temple_little_taoist1').defense, 4);

    expect(
      oldTaoist.equippedItemIds,
      containsPair(EquipmentSlot.weapon, 'temple_whisk'),
    );
    expect(controller.npcCombatStats('temple_old_taoist').attack, 15);

    expect(
      libraryGuard.equippedItemIds,
      containsPair(EquipmentSlot.body, 'temple_bagua_robe'),
    );
    expect(
      libraryGuard.equippedItemIds,
      containsPair(EquipmentSlot.head, 'temple_jade_hat'),
    );
    expect(controller.npcCombatStats('temple_guard_taoist').defense, 11);
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

  test('Snow Pavilion mountain pass connects to Green Stone Village', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'snow_crossroad',
        visitedRoomIds: {...baseState.visitedRoomIds, 'snow_crossroad'},
      ),
    );

    controller.dispatch(const GameAction.move(Direction.east));

    expect(controller.state.currentRoomId, 'green_path6');
    expect(repository.room(controller.state.currentRoomId).areaId, 'green');
    expect(
      repository.room('green_path6').exits[Direction.west],
      'snow_crossroad',
    );
  });

  test('original jade clues connect elder, drunk, and Shen Wannian', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'green_elder_home',
        visitedRoomIds: {...baseState.visitedRoomIds, 'green_elder_home'},
        inventoryItemIds: ['snow_wineskin', 'snow_wineskin'],
        player: baseState.player.copyWith(silver: 10),
      ),
    );

    controller.dispatch(
      const GameAction.selectDialogue('green_elder', 'ask_green_jade'),
    );
    expect(
      controller.state.questStatuses['green_jade_mystery'],
      QuestStatus.active,
    );
    expect(controller.state.questFlags, contains('green_elder_info'));

    controller.replaceState(
      controller.state.copyWith(
        currentRoomId: 'snow_main_street2',
        visitedRoomIds: {
          ...controller.state.visitedRoomIds,
          'snow_main_street2',
        },
      ),
    );
    controller.dispatch(
      const GameAction.giveItem('snow_drunk', 'snow_wineskin'),
    );
    expect(controller.state.questFlags, contains('green_drunk_jade_clue'));
    expect(controller.state.inventory.countOf('snow_wineskin'), 1);
    controller.dispatch(
      const GameAction.giveItem('snow_drunk', 'snow_wineskin'),
    );
    expect(controller.state.questFlags, contains('green_drunk_drug_clue'));
    expect(controller.state.inventory.countOf('snow_wineskin'), 0);

    controller.replaceState(
      controller.state.copyWith(
        currentRoomId: 'green_shop',
        visitedRoomIds: {...controller.state.visitedRoomIds, 'green_shop'},
      ),
    );
    controller.dispatch(
      const GameAction.selectDialogue(
        'green_shen_wannian',
        'ask_shen_for_jade',
      ),
    );
    expect(controller.state.inventory.contains('green_jade'), isTrue);
    expect(controller.state.questFlags, contains('green_had_jade'));
    expect(
      controller.state.questStatuses['green_jade_mystery'],
      QuestStatus.completed,
    );

    controller.dispatch(
      const GameAction.selectDialogue(
        'green_shen_wannian',
        'ask_shen_for_drug',
      ),
    );
    controller.dispatch(
      const GameAction.selectDialogue('green_shen_wannian', 'buy_slumber_drug'),
    );
    expect(controller.state.player.silver, 0);
    expect(controller.state.inventory.contains('green_slumber_drug'), isTrue);
  });

  test('slumber drug can be poured into the original wineskin', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        inventoryItemIds: ['green_slumber_drug', 'snow_wineskin'],
      ),
    );

    controller.dispatch(
      const GameAction.combineItems('green_slumber_drug', 'snow_wineskin'),
    );

    expect(controller.state.inventory.contains('green_slumber_drug'), isFalse);
    expect(controller.state.inventory.contains('snow_wineskin'), isFalse);
    expect(
      controller.state.inventory.contains('green_drugged_wineskin'),
      isTrue,
    );
    expect(controller.state.log.last, contains('蒙汗药'));
  });

  test('Eight Trigram array keeps the original combat experience gate', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'green_array_entrance',
        visitedRoomIds: {...baseState.visitedRoomIds, 'green_array_entrance'},
        player: baseState.player.copyWith(combatExperience: 99999),
      ),
    );

    expect(
      repository.room('green_array_entrance').availableExits(controller.state),
      isNot(contains(Direction.east)),
    );
    controller.replaceState(
      controller.state.copyWith(
        player: controller.state.player.copyWith(combatExperience: 100000),
      ),
    );
    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'green_eight0');
  });

  test('solving the array unlocks the original Windsword search', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'green_eight7',
        visitedRoomIds: {...baseState.visitedRoomIds, 'green_eight7'},
      ),
    );

    controller.dispatch(
      const GameAction.performRoomAction('leave_green_array'),
    );
    expect(controller.state.currentRoomId, 'green_stone_room');
    expect(controller.state.questFlags, contains('green_eight_solved'));
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(
      const GameAction.performRoomAction('search_green_water'),
    );

    expect(controller.state.inventory.contains('green_windsword'), isTrue);
    expect(controller.state.questFlags, contains('green_windsword_found'));
    expect(
      repository
          .room('green_water')
          .availableActions(controller.state)
          .map((action) => action.id),
      isNot(contains('search_green_water')),
    );
  });

  test('strong player can push out of the array dead end', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'green_closed',
        visitedRoomIds: {...baseState.visitedRoomIds, 'green_closed'},
        player: baseState.player.copyWith(
          attributes: baseState.player.attributes.copyWith(strength: 25),
        ),
      ),
    );

    controller.dispatch(const GameAction.performRoomAction('push_green_stone'));

    expect(controller.state.currentRoomId, 'green_array_entrance');
    expect(controller.state.player.hp, baseState.player.hp - 60);
    expect(controller.state.player.spirit, baseState.player.spirit - 18);
  });

  test('Juechenzi accepts a qualified unaffiliated player', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'green_outer_stone_room',
        visitedRoomIds: {...baseState.visitedRoomIds, 'green_outer_stone_room'},
        player: baseState.player.copyWith(
          combatExperience: 100000,
          attributes: baseState.player.attributes.copyWith(spirituality: 24),
        ),
      ),
    );

    expect(
      repository
          .room('green_outer_stone_room')
          .availableExits(controller.state),
      isNot(contains(Direction.enter)),
    );
    controller.dispatch(
      const GameAction.performRoomAction('request_juechen_entry'),
    );
    expect(controller.state.currentRoomId, 'green_cave_hall');
    controller.dispatch(const GameAction.apprenticeTo('green_master_juechen'));

    expect(controller.state.apprenticeship?.familyId, 'juechen');
    expect(
      controller.state.apprenticeship?.masterNpcId,
      'green_master_juechen',
    );
    expect(controller.state.apprenticeship?.generation, 2);
    expect(controller.state.apprenticeship?.title, '弟子');

    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.move(Direction.enter));
    expect(controller.state.currentRoomId, 'green_cave_hall');
  });

  test('Juechenzi teaches the original Juechen martial path', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'green_cave_hall',
        visitedRoomIds: {...baseState.visitedRoomIds, 'green_cave_hall'},
        player: baseState.player.copyWith(
          combatExperience: 100000,
          potential: 20,
          spirit: 300,
          maxSpirit: 300,
          maxInnerPower: 250,
          innerPower: 250,
          attributes: baseState.player.attributes.copyWith(
            strength: 25,
            spirituality: 24,
          ),
        ),
      ),
    );

    controller.dispatch(
      const GameAction.learnFromNpc('green_master_juechen', 'juechen_force'),
    );
    expect(controller.state.learnedSkillIds, isNot(contains('juechen_force')));
    expect(controller.state.log.last, contains('自己的弟子'));

    controller.dispatch(const GameAction.apprenticeTo('green_master_juechen'));
    for (final skillId in const [
      'literate',
      'basic_force',
      'magic',
      'spells',
      'basic_staff',
      'juechen_force',
      'tao_mystery',
      'magic_array',
      'jingang_staff',
    ]) {
      controller.dispatch(
        GameAction.learnFromNpc('green_master_juechen', skillId),
      );
    }

    expect(
      controller.state.learnedSkillIds,
      containsAll([
        'juechen_force',
        'tao_mystery',
        'magic_array',
        'jingang_staff',
      ]),
    );
    controller.dispatch(
      const GameAction.enableSkill('juechen_force', SkillUsage.force),
    );
    controller.dispatch(
      const GameAction.enableSkill('magic_array', SkillUsage.spells),
    );
    expect(controller.state.enabledSkillIds[SkillUsage.force], 'juechen_force');
    expect(controller.state.enabledSkillIds[SkillUsage.spells], 'magic_array');
  });

  test('Juechen skills enforce their original relative requirements', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'green_cave_hall',
        apprenticeship: const ApprenticeshipState(
          familyId: 'juechen',
          masterNpcId: 'green_master_juechen',
          generation: 2,
          title: '弟子',
          contribution: 0,
          rankId: 'disciple',
        ),
        skillProgress: const {
          'spells': SkillProgress(level: 5, experience: 0),
          'tao_mystery': SkillProgress(level: 1, experience: 0),
          'magic_array': SkillProgress(level: 1, experience: 0),
        },
        player: baseState.player.copyWith(
          potential: 10,
          spirit: 200,
          maxSpirit: 200,
          combatExperience: 100000,
        ),
      ),
    );

    controller.dispatch(
      const GameAction.learnFromNpc('green_master_juechen', 'magic_array'),
    );
    expect(controller.state.log.last, contains('小天魔道修为不够'));

    controller.replaceState(
      controller.state.copyWith(
        skillProgress: {
          ...controller.state.skillProgress,
          'tao_mystery': const SkillProgress(level: 2, experience: 0),
        },
      ),
    );
    controller.dispatch(
      const GameAction.learnFromNpc('green_master_juechen', 'magic_array'),
    );
    expect(controller.state.log.last, contains('似乎有所领悟'));
  });

  test('Juechen binding spell consumes mana and stops enemy actions', () {
    final controller = _juechenCombatController(repository, skillLevel: 10);
    final hpBefore = controller.state.player.hp;

    controller.dispatch(const GameAction.startCombat('green_spider'));
    controller.dispatch(const GameAction.useCombatMove('magic_array', 'dun'));

    expect(controller.state.player.mana, 300);
    expect(controller.state.player.spirit, 420);
    expect(controller.state.player.hp, hpBefore);
    expect(controller.state.combat?.round, 1);
    expect(
      controller.state.combat?.enemyStatusEffects.single.id,
      'juechen_bind',
    );
  });

  test('failed Juechen spell still consumes resources and combat turn', () {
    final controller = _juechenCombatController(
      repository,
      skillLevel: 10,
      randomIntGenerator: (_) => 0,
    );

    controller.dispatch(const GameAction.startCombat('green_spider'));
    controller.dispatch(const GameAction.useCombatMove('magic_array', 'dun'));

    expect(controller.state.player.mana, 300);
    expect(controller.state.player.spirit, 420);
    expect(controller.state.combat?.round, 1);
    expect(controller.state.combat?.enemyStatusEffects, isEmpty);
    expect(controller.state.log, contains(contains('没能困住敌人')));
  });

  test('Juechen escape spell leaves combat at Snow Pavilion temple', () {
    final controller = _juechenCombatController(repository, skillLevel: 10);

    controller.dispatch(const GameAction.startCombat('green_spider'));
    controller.dispatch(
      const GameAction.useCombatMove('magic_array', 'dun_escape'),
    );

    expect(controller.state.combat, isNull);
    expect(controller.state.currentRoomId, 'snow_temple');
    expect(controller.state.player.mana, 420);
    expect(controller.state.player.spirit, 470);
    expect(controller.state.visitedRoomIds, contains('snow_temple'));
  });

  test('Juechen summon fights until the current combat ends', () {
    final controller = _juechenCombatController(repository, skillLevel: 60);

    controller.dispatch(const GameAction.startCombat('green_spider'));
    controller.dispatch(
      const GameAction.useCombatMove('magic_array', 'saveme'),
    );

    expect(controller.state.player.mana, 400);
    expect(controller.state.player.spirit, 440);
    expect(controller.state.combat?.ally?.name, '天甲神兵');
    expect(controller.state.combat?.ally?.hp, 1000);
    expect(controller.state.combat?.enemyHp, 1);
    expect(controller.state.log, contains(contains('天甲神兵')));

    controller.dispatch(const GameAction.attack());

    expect(controller.state.combat, isNull);
    expect(controller.state.npcStates['green_spider']?.isDefeated, isTrue);
    expect(controller.state.log, contains(contains('护法已毕')));
  });

  test('summoned ally takes enemy attacks and can be defeated', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        player: initialState.player.copyWith(hp: 300, maxHp: 300),
      ),
    );
    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.replaceState(
      controller.state.copyWith(
        combat: controller.state.combat?.copyWith(
          ally: const SummonedAllyState(
            name: '试炼神兵',
            attack: 1,
            hp: 2,
            maxHp: 2,
            defense: 0,
            attackMessage: '试炼神兵攻向{enemy}，造成{damage}点伤害。',
            defeatMessage: '试炼神兵受创消散。',
            leaveMessage: '试炼神兵离开。',
          ),
        ),
      ),
    );
    final playerHp = controller.state.player.hp;

    controller.dispatch(const GameAction.attack());

    expect(controller.state.player.hp, playerHp);
    expect(controller.state.combat?.ally, isNull);
    expect(controller.state.log, contains(contains('试炼神兵受创消散')));
  });

  test('Jingang staff requires combined strength and a staff to practice', () {
    final baseState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: baseState.copyWith(
        currentRoomId: 'green_cave_hall',
        apprenticeship: const ApprenticeshipState(
          familyId: 'juechen',
          masterNpcId: 'green_master_juechen',
          generation: 2,
          title: '弟子',
          contribution: 0,
          rankId: 'disciple',
        ),
        inventoryItemIds: const ['green_jingang_staff'],
        skillProgress: const {
          'basic_staff': SkillProgress(level: 10, experience: 0),
        },
        player: baseState.player.copyWith(
          attributes: baseState.player.attributes.copyWith(strength: 20),
          maxInnerPower: 290,
          innerPower: 290,
          hp: 200,
          maxHp: 200,
          potential: 10,
          spirit: 200,
          maxSpirit: 200,
          combatExperience: 100000,
        ),
      ),
    );

    controller.dispatch(
      const GameAction.learnFromNpc('green_master_juechen', 'jingang_staff'),
    );
    expect(controller.state.learnedSkillIds, isNot(contains('jingang_staff')));
    expect(controller.state.log.last, contains('膂力还不够'));

    controller.replaceState(
      controller.state.copyWith(
        player: controller.state.player.copyWith(
          maxInnerPower: 300,
          innerPower: 300,
        ),
      ),
    );
    controller.dispatch(
      const GameAction.learnFromNpc('green_master_juechen', 'jingang_staff'),
    );
    expect(controller.state.learnedSkillIds, contains('jingang_staff'));
    controller.dispatch(
      const GameAction.enableSkill('jingang_staff', SkillUsage.staff),
    );
    controller.dispatch(const GameAction.practiceSkill(SkillUsage.staff));
    expect(controller.state.log.last, contains('必须先装备'));

    controller.dispatch(const GameAction.equipItem('green_jingang_staff'));
    controller.dispatch(const GameAction.practiceSkill(SkillUsage.staff));
    expect(controller.state.player.hp, 140);
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

    controller.dispatch(
      const GameAction.giveInventoryItem('snow_crazy_dog', 'plain_cloth'),
    );
    expect(controller.state.inventoryItemIds, isNot(contains('plain_cloth')));
    expect(controller.state.equippedItemIds[EquipmentSlot.body], isNull);
    expect(
      controller.state.npcStates['snow_crazy_dog']?.itemCounts,
      containsPair('plain_cloth', 1),
    );

    _defeatNpc(controller, 'snow_crazy_dog');
    final corpse = controller.state.corpses.values.firstWhere(
      (corpse) => corpse.victimName == '疯狗',
    );
    expect(
      controller.state.corpses.values.map((corpse) => corpse.victimName),
      contains('疯狗'),
    );
    expect(corpse.itemCounts, containsPair('snow_bone', 1));
    expect(corpse.itemCounts, containsPair('plain_cloth', 1));
    expect(controller.state.npcStates['snow_crazy_dog']?.itemCounts, isEmpty);
    expect(
      controller.state.npcStates['snow_crazy_dog']?.equippedItemIds,
      isEmpty,
    );

    controller.dispatch(GameAction.takeCorpseItem(corpse.id, 'snow_bone'));
    expect(controller.state.inventoryItemIds, contains('snow_bone'));
    expect(
      controller.state.corpses[corpse.id]?.itemCounts,
      isNot(contains('snow_bone')),
    );
    expect(
      controller.state.corpses[corpse.id]?.itemCounts,
      containsPair('plain_cloth', 1),
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

  test('old pine bandits carry their original equipment and quantities', () {
    final controller = GameController(repository: repository);
    final spy = controller.state.npcStates['oldpine_spy']!;
    final fatBandit = controller.state.npcStates['oldpine_fat_bandit']!;
    final commander = controller.state.npcStates['oldpine_commander']!;

    expect(spy.itemCounts['oldpine_throwing_knife'], 30);
    expect(spy.itemCounts['oldpine_corpse_dust'], 30);
    expect(
      spy.equippedItemIds,
      containsPair(EquipmentSlot.weapon, 'oldpine_throwing_knife'),
    );
    expect(
      spy.equippedItemIds,
      containsPair(EquipmentSlot.body, 'oldpine_night_clothes'),
    );
    expect(controller.npcCombatStats('oldpine_spy').attack, 27);
    expect(controller.npcCombatStats('oldpine_spy').defense, 4);

    expect(
      fatBandit.equippedItemIds,
      containsPair(EquipmentSlot.weapon, 'oldpine_short_sword'),
    );
    expect(
      fatBandit.equippedItemIds,
      containsPair(EquipmentSlot.body, 'oldpine_leather'),
    );
    expect(controller.npcCombatStats('oldpine_fat_bandit').attack, 21);
    expect(controller.npcCombatStats('oldpine_fat_bandit').defense, 7);

    expect(
      commander.equippedItemIds,
      containsPair(EquipmentSlot.weapon, 'oldpine_glaive'),
    );
    expect(
      commander.equippedItemIds,
      containsPair(EquipmentSlot.body, 'oldpine_leather'),
    );
    expect(
      commander.equippedItemIds,
      containsPair(EquipmentSlot.outerwear, 'oldpine_wolfskin_cloak'),
    );
    expect(commander.itemCounts['oldpine_bamboo_pipe'], 1);
    expect(controller.npcCombatStats('oldpine_commander').attack, 57);
    expect(controller.npcCombatStats('oldpine_commander').defense, 21);
  });

  test('dynamic NPC instances share a definition but keep separate state', () {
    final initialState = repository.createInitialState();
    final instanceSystem = NpcInstanceSystem(repository);
    final spawnedState = instanceSystem.spawn(
      initialState,
      definitionId: 'oldpine_keep_yard_guard',
      roomId: 'oldpine_keep_yard',
      count: 5,
      instancePrefix: 'oldpine_reinforcement',
    );
    final instanceIds =
        repository
            .visibleNpcsInRoom(spawnedState, 'oldpine_keep_yard')
            .where((npc) => npc.id.startsWith('oldpine_reinforcement_'))
            .map((npc) => npc.id)
            .toList();

    expect(instanceIds, hasLength(5));
    expect(instanceIds.toSet(), hasLength(5));
    expect(
      instanceIds.map((id) => repository.npcInstance(spawnedState, id).name),
      everyElement('土匪喽罗'),
    );
    expect(
      spawnedState.npcStates[instanceIds.first]?.definitionId,
      'oldpine_keep_yard_guard',
    );

    final targetId = instanceIds.first;
    final targetState = spawnedState.npcStates[targetId]!;
    final controller = GameController(
      repository: repository,
      initialState: spawnedState.copyWith(
        currentRoomId: 'oldpine_keep_yard',
        visitedRoomIds: {...spawnedState.visitedRoomIds, 'oldpine_keep_yard'},
        player: spawnedState.player.copyWith(hp: 1000, maxHp: 1000),
        inventoryItemIds: const ['temple_wangzhou_sword'],
        npcStates: {
          ...spawnedState.npcStates,
          targetId: targetState.copyWith(currentHp: 1),
        },
      ),
    );
    controller.dispatch(const GameAction.equipItem('temple_wangzhou_sword'));
    _defeatNpc(controller, targetId);

    expect(controller.state.npcStates[targetId]?.isDefeated, isTrue);
    for (final otherId in instanceIds.skip(1)) {
      expect(controller.state.npcStates[otherId]?.isDefeated, isFalse);
    }
    final restored = GameState.fromJson(controller.state.toJson());
    expect(
      restored.npcStates[targetId]?.definitionId,
      'oldpine_keep_yard_guard',
    );
    expect(
      repository.visibleNpcsInRoom(restored, 'oldpine_keep_yard'),
      hasLength(6),
    );
  });

  test('original fat bandit calls the chief into combat once', () {
    final initialState = repository.createInitialState();
    final fatBandit = initialState.npcStates['oldpine_fat_bandit']!;
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'oldpine_pine1',
        visitedRoomIds: {...initialState.visitedRoomIds, 'oldpine_pine1'},
        player: initialState.player.copyWith(hp: 5000, maxHp: 5000),
        npcStates: {
          ...initialState.npcStates,
          'oldpine_fat_bandit': fatBandit.copyWith(currentHp: 200),
        },
      ),
    );

    controller.dispatch(const GameAction.startCombat('oldpine_fat_bandit'));
    for (var round = 0; round < 3; round++) {
      controller.dispatch(const GameAction.attack());
    }

    final chiefIds =
        controller.state.npcStates.entries
            .where(
              (entry) =>
                  entry.value.definitionId == 'oldpine_bandit_chief' &&
                  entry.value.roomId == 'oldpine_pine1',
            )
            .map((entry) => entry.key)
            .toList();
    expect(chiefIds, hasLength(1));
    expect(controller.state.combat?.queuedNpcIds, chiefIds);
    expect(
      controller.state.npcStates['oldpine_fat_bandit']?.valueFor(
        'combat_event_call_for_chief',
      ),
      1,
    );
    expect(controller.state.log.join('\n'), contains('兄弟撑不住啦'));

    final restored = GameState.fromJson(controller.state.toJson());
    expect(restored.combat?.queuedNpcIds, chiefIds);
    expect(
      restored.npcStates[chiefIds.single]?.definitionId,
      'oldpine_bandit_chief',
    );

    final finishingController = GameController(
      repository: repository,
      initialState: restored.copyWith(
        combat: restored.combat?.copyWith(enemyHp: 1),
        npcStates: {
          ...restored.npcStates,
          'oldpine_fat_bandit': restored.npcStates['oldpine_fat_bandit']!
              .copyWith(currentHp: 1),
        },
      ),
    );
    finishingController.dispatch(const GameAction.attack());

    expect(
      finishingController.state.npcStates['oldpine_fat_bandit']?.isDefeated,
      isTrue,
    );
    expect(finishingController.state.combat?.npcId, chiefIds.single);
    expect(finishingController.state.log.last, contains('接下了这场战斗'));
  });

  test('old pine spy corpse keeps the original stacked possessions', () {
    final initialState = repository.createInitialState();
    final spyState = initialState.npcStates['oldpine_spy']!;
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'oldpine_tree1',
        visitedRoomIds: {...initialState.visitedRoomIds, 'oldpine_tree1'},
        player: initialState.player.copyWith(hp: 1000, maxHp: 1000),
        npcStates: {
          ...initialState.npcStates,
          'oldpine_spy': spyState.copyWith(currentHp: 1),
        },
      ),
    );

    _defeatNpc(controller, 'oldpine_spy');

    final corpse = controller.state.corpses.values.firstWhere(
      (corpse) => corpse.victimName == '黑衣人',
    );
    expect(corpse.itemCounts['oldpine_throwing_knife'], 30);
    expect(corpse.itemCounts['oldpine_corpse_dust'], 30);
    expect(corpse.itemCounts['oldpine_night_clothes'], 1);
  });

  test('old pine spy consumes each throwing knife when attacking', () {
    final initialState = repository.createInitialState();
    final spyState = initialState.npcStates['oldpine_spy']!;
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'oldpine_tree1',
        visitedRoomIds: {...initialState.visitedRoomIds, 'oldpine_tree1'},
        player: initialState.player.copyWith(hp: 5000, maxHp: 5000),
        npcStates: {
          ...initialState.npcStates,
          'oldpine_spy': spyState.copyWith(currentHp: 1000),
        },
      ),
    );

    controller.dispatch(const GameAction.startCombat('oldpine_spy'));
    for (var attack = 0; attack < 30; attack++) {
      controller.dispatch(const GameAction.attack());
    }

    final spy = controller.state.npcStates['oldpine_spy']!;
    expect(spy.itemCounts, isNot(contains('oldpine_throwing_knife')));
    expect(spy.equippedItemIds, isNot(contains(EquipmentSlot.weapon)));
    expect(controller.npcCombatStats('oldpine_spy').attack, 7);
    expect(controller.state.log, contains(contains('飞刀已经用尽')));
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
        player: initialState.player.copyWith(hp: 2000, maxHp: 2000),
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
        inventoryItemIds: ['temple_wangzhou_sword'],
      ),
    );
    controller.dispatch(const GameAction.equipItem('temple_wangzhou_sword'));

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
    expect(
      repository.room('oldpine_keep_yard').availableExits(controller.state),
      isNot(contains(Direction.west)),
    );
    final reinforcementIds =
        repository
            .visibleNpcsInRoom(controller.state, 'oldpine_keep_yard')
            .where((npc) => npc.id.startsWith('oldpine_keep_reinforcement_'))
            .map((npc) => npc.id)
            .toList();
    expect(reinforcementIds, hasLength(5));

    _defeatNpc(controller, 'oldpine_commander');
    expect(controller.state.npcStates['oldpine_commander']?.isDefeated, isTrue);
    _takeCorpseLoot(controller, 'oldpine_bamboo_pipe');
    controller.dispatch(const GameAction.move(Direction.west));
    for (final reinforcementId in reinforcementIds) {
      _defeatNpc(controller, reinforcementId);
    }
    expect(controller.state.currentRoomId, 'oldpine_keep_yard');
    expect(
      repository.room('oldpine_keep_yard').availableExits(controller.state),
      isNot(contains(Direction.west)),
    );

    controller.dispatch(const GameAction.useItem('oldpine_bamboo_pipe'));
    expect(controller.state.inventoryItemIds, contains('oldpine_bamboo_pipe'));
    expect(
      repository.room('oldpine_keep_yard').availableExits(controller.state),
      contains(Direction.west),
    );
    expect(controller.state.log.last, contains('巨石慢慢移开'));
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

    _takeCorpseLoot(controller, 'temple_bagua_robe');
    _takeCorpseLoot(controller, 'temple_jade_hat');
    expect(
      controller.state.inventoryItemIds,
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

  test('netherbolt uses original mana, spirit, and max mana roll', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      randomIntGenerator: (upperBound) => upperBound - 1,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        skillProgress: const {
          'necromancy': SkillProgress(level: 1, experience: 0),
          'spells': SkillProgress(level: 10, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.spells: 'necromancy'},
        player: initialState.player.copyWith(
          mana: 200,
          maxMana: 200,
          spirit: 100,
          maxSpirit: 100,
        ),
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(
      const GameAction.useCombatMove('necromancy', 'netherbolt'),
    );

    expect(controller.state.player.mana, 175);
    expect(controller.state.player.spirit, 90);
    expect(controller.state.player.innerPower, initialState.player.innerPower);
    expect(controller.state.combat?.enemyHp, lessThan(36));
  });

  test('failed netherbolt consumes resources without damaging enemy', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      randomIntGenerator: (_) => 0,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        skillProgress: const {
          'necromancy': SkillProgress(level: 1, experience: 0),
          'spells': SkillProgress(level: 10, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.spells: 'necromancy'},
        player: initialState.player.copyWith(
          mana: 200,
          maxMana: 200,
          spirit: 100,
          maxSpirit: 100,
        ),
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(
      const GameAction.useCombatMove('necromancy', 'netherbolt'),
    );

    expect(controller.state.player.mana, 175);
    expect(controller.state.player.spirit, 90);
    expect(controller.state.combat?.enemyHp, 36);
    expect(controller.state.log, contains(contains('消散无踪')));
  });

  test('necromancy damages and drains persisted enemy resources', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      randomIntGenerator: (upperBound) => upperBound - 1,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        skillProgress: const {
          'necromancy': SkillProgress(level: 1, experience: 0),
          'spells': SkillProgress(level: 10, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.spells: 'necromancy'},
        player: initialState.player.copyWith(
          hp: 200,
          maxHp: 200,
          energy: 50,
          maxEnergy: 100,
          mana: 200,
          maxMana: 200,
          spirit: 100,
          maxSpirit: 100,
        ),
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(
      const GameAction.useCombatMove('necromancy', 'feeblebolt'),
    );
    expect(controller.state.npcStates['white_ice_dragon']?.currentSpirit, 26);

    controller.dispatch(
      const GameAction.useCombatMove('necromancy', 'drainerbolt'),
    );

    expect(controller.state.npcStates['white_ice_dragon']?.currentEnergy, 26);
    expect(controller.state.player.energy, 60);
    expect(controller.state.player.mana, 150);
    expect(controller.state.player.spirit, 70);
    expect(controller.state.log, contains(contains('吸取了10点精力')));
  });

  test('necromancy bolts use original spell versus combat experience roll', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      randomIntGenerator:
          (upperBound) => upperBound == 200 ? upperBound - 1 : 0,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        skillProgress: const {
          'necromancy': SkillProgress(level: 1, experience: 0),
          'spells': SkillProgress(level: 10, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.spells: 'necromancy'},
        player: initialState.player.copyWith(
          hp: 200,
          maxHp: 200,
          mana: 200,
          maxMana: 200,
          spirit: 100,
          maxSpirit: 100,
        ),
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(
      const GameAction.useCombatMove('necromancy', 'netherbolt'),
    );

    expect(controller.state.player.mana, 175);
    expect(controller.state.player.spirit, 90);
    expect(controller.state.combat?.enemyHp, 36);
    expect(controller.state.log, contains(contains('被白鳞冰龙躲开')));
  });

  test('invocation keeps the original one-in-three heavenly summon', () {
    final rolls = [499, 0, 0];
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      randomIntGenerator: (_) => rolls.removeAt(0),
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        skillProgress: const {
          'necromancy': SkillProgress(level: 1, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.spells: 'necromancy'},
        player: initialState.player.copyWith(
          hp: 200,
          maxHp: 200,
          mana: 500,
          maxMana: 500,
          spirit: 500,
          maxSpirit: 500,
        ),
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(
      const GameAction.useCombatMove('necromancy', 'invocation'),
    );

    expect(controller.state.player.mana, 400);
    expect(controller.state.player.spirit, 440);
    expect(controller.state.combat?.ally?.name, '天甲神兵');
    expect(controller.state.combat?.ally?.lastsForCombat, isTrue);
    expect(controller.state.log, contains(contains('金光由天而降')));
  });

  test('invocation usually summons an original earthly-branch hell guard', () {
    final rolls = [499, 1, 0];
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      randomIntGenerator: (_) => rolls.removeAt(0),
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        skillProgress: const {
          'necromancy': SkillProgress(level: 1, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.spells: 'necromancy'},
        player: initialState.player.copyWith(
          hp: 200,
          maxHp: 200,
          mana: 500,
          maxMana: 500,
          spirit: 500,
          maxSpirit: 500,
        ),
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(
      const GameAction.useCombatMove('necromancy', 'invocation'),
    );

    expect(controller.state.combat?.ally?.name, '子阴鬼卒');
    expect(controller.state.combat?.ally?.attack, 24);
    expect(controller.state.log, contains(contains('蓝光从地底升起')));
  });

  test('failed invocation consumes its original resources', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      randomIntGenerator: (_) => 199,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
        skillProgress: const {
          'necromancy': SkillProgress(level: 1, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.spells: 'necromancy'},
        player: initialState.player.copyWith(
          hp: 200,
          maxHp: 200,
          mana: 500,
          maxMana: 500,
          spirit: 500,
          maxSpirit: 500,
        ),
      ),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    controller.dispatch(
      const GameAction.useCombatMove('necromancy', 'invocation'),
    );

    expect(controller.state.player.mana, 400);
    expect(controller.state.player.spirit, 440);
    expect(controller.state.combat?.ally, isNull);
    expect(controller.state.log, contains(contains('什么也没有发生')));
  });

  test('astral vision reveals an original ghost for the spells level', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'choyin_n_gate',
        visitedRoomIds: {...initialState.visitedRoomIds, 'choyin_n_gate'},
        skillProgress: const {
          'necromancy': SkillProgress(level: 1, experience: 0),
          'spells': SkillProgress(level: 3, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.spells: 'necromancy'},
        player: initialState.player.copyWith(
          mana: 100,
          maxMana: 100,
          spirit: 50,
          maxSpirit: 50,
        ),
      ),
    );

    expect(
      repository.visibleNpcsInRoom(controller.state, 'choyin_n_gate'),
      isEmpty,
    );

    controller.dispatch(
      const GameAction.useSkillMove('necromancy', 'astral_vision'),
    );

    expect(controller.state.player.mana, 70);
    expect(controller.state.player.spirit, 45);
    expect(controller.state.hasAstralVision, isTrue);
    expect(controller.state.playerStatusEffects.single.remainingRounds, 3);
    expect(
      repository.visibleNpcsInRoom(controller.state, 'choyin_n_gate').single.id,
      'choyin_wandering_ghost',
    );
    expect(
      GameState.fromJson(controller.state.toJson()).hasAstralVision,
      isTrue,
    );

    controller.dispatch(
      const GameAction.useSkillMove('necromancy', 'astral_vision'),
    );
    expect(controller.state.player.mana, 70);
    expect(controller.state.log, contains(contains('已经施展过阴阳眼')));

    controller.dispatch(const GameAction.move(Direction.west));
    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.hasAstralVision, isTrue);
    controller.dispatch(const GameAction.move(Direction.west));
    expect(controller.state.hasAstralVision, isFalse);
    expect(controller.state.log, contains(contains('阴阳眼法术失效')));
    controller.dispatch(const GameAction.move(Direction.east));
    expect(
      repository.visibleNpcsInRoom(controller.state, 'choyin_n_gate'),
      isEmpty,
    );
  });

  test('animate turns a corpse into a persistent original-style zombie', () {
    final initialState = repository.createInitialState();
    const corpse = CorpseState(
      id: 'test_corpse',
      npcId: 'snow_farmer',
      victimName: '农夫',
      roomId: 'snow_stone_road',
      rottensAtTurn: 12,
      skeletonizesAtTurn: 24,
      decaysAtTurn: 30,
    );
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'snow_stone_road',
        visitedRoomIds: {...initialState.visitedRoomIds, 'snow_stone_road'},
        corpses: const {'test_corpse': corpse},
        skillProgress: const {
          'necromancy': SkillProgress(level: 1, experience: 0),
          'spells': SkillProgress(level: 10, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.spells: 'necromancy'},
        player: initialState.player.copyWith(
          hp: 300,
          maxHp: 300,
          mana: 100,
          maxMana: 100,
          spirit: 100,
          maxSpirit: 100,
        ),
      ),
    );

    controller.dispatch(
      const GameAction.animateCorpse('necromancy', 'animate', 'test_corpse'),
    );

    expect(controller.state.corpses, isEmpty);
    expect(controller.state.player.mana, 50);
    expect(controller.state.player.spirit, 70);
    expect(controller.state.undeadCompanion?.name, '农夫的僵尸');
    expect(controller.state.undeadCompanion?.remainingTurns, 60);
    expect(
      GameState.fromJson(controller.state.toJson()).undeadCompanion?.name,
      '农夫的僵尸',
    );

    controller.dispatch(const GameAction.startCombat('snow_crazy_dog'));
    expect(controller.state.combat?.ally?.name, '农夫的僵尸');
    expect(controller.state.combat?.ally?.persistent, isTrue);
  });

  test(
    'corpse dust consumes one portion and dissolves corpse with its loot',
    () {
      final initialState = repository.createInitialState();
      const corpse = CorpseState(
        id: 'dust_target',
        npcId: 'snow_farmer',
        victimName: '农夫',
        roomId: 'snow_stone_road',
        rottensAtTurn: 12,
        skeletonizesAtTurn: 24,
        decaysAtTurn: 30,
        itemCounts: {'snow_bone': 1},
      );
      final controller = GameController(
        repository: repository,
        initialState: initialState.copyWith(
          currentRoomId: 'snow_stone_road',
          visitedRoomIds: {...initialState.visitedRoomIds, 'snow_stone_road'},
          inventoryItemIds: const [
            'oldpine_corpse_dust',
            'oldpine_corpse_dust',
          ],
          corpses: const {'dust_target': corpse},
        ),
      );

      controller.dispatch(
        const GameAction.dissolveCorpse('dust_target', 'oldpine_corpse_dust'),
      );

      expect(controller.state.corpses, isEmpty);
      expect(controller.state.inventory.countOf('oldpine_corpse_dust'), 1);
      expect(
        repository.room('snow_stone_road').visibleItemIds(controller.state),
        isNot(contains('snow_bone')),
      );
      expect(controller.state.log.last, contains('只剩下一滩黄水'));
    },
  );

  test('corpse follows original decay phases and drops remaining contents', () {
    final initialState = repository.createInitialState();
    const corpse = CorpseState(
      id: 'decaying_corpse',
      npcId: 'snow_farmer',
      victimName: '农夫',
      roomId: 'snow_inn',
      rottensAtTurn: 1,
      skeletonizesAtTurn: 2,
      decaysAtTurn: 3,
      itemCounts: {'snow_bone': 1},
    );
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        corpses: const {'decaying_corpse': corpse},
      ),
    );

    controller.dispatch(const GameAction.move(Direction.east));
    expect(
      controller.state.corpses[corpse.id]?.phaseAt(controller.state.worldTurn),
      CorpseDecayPhase.rotting,
    );
    controller.dispatch(const GameAction.move(Direction.west));
    expect(
      controller.state.corpses[corpse.id]?.phaseAt(controller.state.worldTurn),
      CorpseDecayPhase.skeleton,
    );
    controller.dispatch(const GameAction.move(Direction.east));

    expect(controller.state.corpses, isNot(contains(corpse.id)));
    expect(
      repository
          .visibleItemsInRoom(controller.state, 'snow_inn')
          .map((item) => item.id),
      contains('snow_bone'),
    );
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
  _takeCorpseLoot(controller, 'rough_short_sword');
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

void _takeCorpseLoot(GameController controller, String itemId) {
  final corpse = controller.state.corpses.values.firstWhere(
    (corpse) =>
        corpse.roomId == controller.state.currentRoomId &&
        (corpse.itemCounts[itemId] ?? 0) > 0,
  );
  controller.dispatch(GameAction.takeCorpseItem(corpse.id, itemId));
}

GameController _juechenCombatController(
  GameDefinitionRepository repository, {
  required int skillLevel,
  int Function(int upperBound)? randomIntGenerator,
}) {
  final initialState = repository.createInitialState();
  return GameController(
    repository: repository,
    randomIntGenerator: randomIntGenerator ?? (upperBound) => upperBound - 1,
    initialState: initialState.copyWith(
      currentRoomId: 'green_abandoned_house',
      visitedRoomIds: {...initialState.visitedRoomIds, 'green_abandoned_house'},
      skillProgress: {
        'magic_array': SkillProgress(level: skillLevel, experience: 0),
        'spells': const SkillProgress(level: 120, experience: 0),
      },
      enabledSkillIds: const {SkillUsage.spells: 'magic_array'},
      player: initialState.player.copyWith(
        hp: 300,
        maxHp: 300,
        mana: 500,
        maxMana: 500,
        spirit: 500,
        maxSpirit: 500,
      ),
    ),
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
