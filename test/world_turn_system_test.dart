import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/direction.dart';
import 'package:eastern_stories/game/models/game_state.dart';
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

  test('only a successful journey advances time among navigation actions', () {
    final controller = GameController(repository: repository);
    final initialTurn = controller.state.worldTurn;

    controller.dispatch(const GameAction.look());
    controller.dispatch(const GameAction.move(Direction.down));

    expect(controller.state.worldTurn, initialTurn);

    controller.dispatch(const GameAction.move(Direction.east));

    expect(controller.state.worldTurn, initialTurn + 1);
  });

  test('successful cultivation advances conditions and npc respawns', () {
    final initial = repository.createInitialState();
    final dogState = initial.npcStates['snow_crazy_dog']!;
    final controller = GameController(
      repository: repository,
      initialState: initial.copyWith(
        currentRoomId: 'liu_home',
        player: initial.player.copyWith(hp: 100, maxHp: 100),
        skillProgress: {
          ...initial.skillProgress,
          'basic_force': const SkillProgress(level: 5, experience: 0),
          'fonxan_force': const SkillProgress(level: 1, experience: 0),
        },
        enabledSkillIds: const {SkillUsage.force: 'fonxan_force'},
        npcStates: {
          ...initial.npcStates,
          'snow_crazy_dog': dogState.copyWith(
            currentHp: 0,
            isDefeated: true,
            respawnAtTurn: 1,
          ),
        },
        playerStatusEffects: const [
          StatusEffectState(
            id: 'snake_poison',
            name: '蛇毒',
            remainingRounds: 3,
            damagePerRound: 4,
          ),
        ],
      ),
    );

    controller.dispatch(const GameAction.meditate());

    expect(controller.state.worldTurn, 1);
    expect(controller.state.player.hp, 96);
    expect(controller.state.playerStatusEffects.single.remainingRounds, 2);
    expect(controller.state.npcStates['snow_crazy_dog']?.isDefeated, isFalse);
    expect(
      controller.state.npcStates['snow_crazy_dog']?.itemCounts,
      containsPair('snow_bone', 1),
    );
  });

  test('combat advances world time without ticking conditions twice', () {
    final initial = repository.createInitialState();
    final dogState = initial.npcStates['snow_crazy_dog']!;
    final controller = GameController(
      repository: repository,
      initialState: initial.copyWith(
        currentRoomId: 'snow_square',
        visitedRoomIds: {...initial.visitedRoomIds, 'snow_square'},
        npcStates: {
          ...initial.npcStates,
          'snow_crazy_dog': dogState.copyWith(roomId: 'snow_square'),
        },
        playerStatusEffects: const [
          StatusEffectState(
            id: 'snake_poison',
            name: '蛇毒',
            remainingRounds: 3,
            damagePerRound: 1,
          ),
        ],
      ),
    );

    controller.dispatch(const GameAction.startCombat('snow_crazy_dog'));
    expect(controller.state.worldTurn, 0);

    controller.dispatch(const GameAction.attack());

    expect(controller.state.worldTurn, 1);
    expect(controller.state.playerStatusEffects.single.remainingRounds, 2);
  });

  test('leaving a resettable area schedules its lifecycle reset', () {
    final initial = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initial.copyWith(
        currentRoomId: 'oldpine_north_path1',
        visitedRoomIds: {...initial.visitedRoomIds, 'oldpine_north_path1'},
      ),
    );

    controller.dispatch(const GameAction.move(Direction.north));

    expect(controller.state.currentRoomId, 'snow_east_mountain_road');
    expect(controller.state.worldTurn, 1);
    expect(controller.state.areaResetAtTurns['oldpine'], 31);
  });

  test('area reset restores encounters but keeps permanent story flags', () {
    final initial = repository.createInitialState();
    final commander = initial.npcStates['oldpine_commander']!;
    final gateGuard = initial.npcStates['oldpine_keep_gate_guard']!;
    final controller = GameController(
      repository: repository,
      initialState: initial.copyWith(
        currentRoomId: 'snow_east_mountain_road',
        worldTurn: 30,
        visitedRoomIds: {...initial.visitedRoomIds, 'snow_east_mountain_road'},
        roomItemOverrides: const {
          'oldpine_pine1': ['oldpine_short_sword'],
        },
        blockedRoomExits: const {
          'oldpine_keep_yard': {Direction.west},
          'oldpine_keep_entrance': {Direction.east},
        },
        areaResetAtTurns: const {'oldpine': 31},
        npcStates: {
          ...initial.npcStates,
          'oldpine_commander': commander.copyWith(
            currentHp: 0,
            isDefeated: true,
            itemCounts: const {},
            equippedItemIds: const {},
          ),
          'oldpine_keep_gate_guard': gateGuard.copyWith(
            currentHp: 0,
            isDefeated: true,
          ),
          'oldpine_reset_reinforcement': repository.createNpcInstanceState(
            'oldpine_keep_yard_guard',
            'oldpine_keep_yard',
          ),
        },
        questFlags: const {
          'oldpine_keep_ambush_triggered',
          'oldpine_skeleton_buried',
        },
      ),
    );

    controller.dispatch(const GameAction.move(Direction.west));

    expect(controller.state.worldTurn, 31);
    expect(controller.state.areaResetAtTurns, isNot(contains('oldpine')));
    expect(
      controller.state.npcStates['oldpine_commander']?.isDefeated,
      isFalse,
    );
    expect(
      controller.state.npcStates['oldpine_commander']?.itemCounts,
      containsPair('oldpine_bamboo_pipe', 1),
    );
    expect(
      controller.state.npcStates['oldpine_keep_gate_guard']?.isDefeated,
      isFalse,
    );
    expect(
      controller.state.npcStates,
      isNot(contains('oldpine_reset_reinforcement')),
    );
    expect(
      controller.state.blockedRoomExits,
      isNot(contains('oldpine_keep_yard')),
    );
    expect(
      controller.state.roomItemOverrides,
      isNot(contains('oldpine_pine1')),
    );
    expect(
      controller.state.questFlags,
      isNot(contains('oldpine_keep_ambush_triggered')),
    );
    expect(controller.state.questFlags, contains('oldpine_skeleton_buried'));
  });

  test('re-entering an area cancels its pending reset', () {
    final initial = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initial.copyWith(
        currentRoomId: 'snow_east_mountain_road',
        worldTurn: 10,
        visitedRoomIds: {...initial.visitedRoomIds, 'snow_east_mountain_road'},
        areaResetAtTurns: const {'oldpine': 20},
      ),
    );

    controller.dispatch(const GameAction.move(Direction.south));

    expect(controller.state.currentRoomId, 'oldpine_north_path1');
    expect(controller.state.areaResetAtTurns, isNot(contains('oldpine')));
  });

  test('dragonhill explicitly resets its renewable bandits', () {
    final initial = repository.createInitialState();
    final firstBandit = initial.npcStates['dragonhill_gangster']!;
    final secondBandit = initial.npcStates['dragonhill_gangster_2']!;
    final controller = GameController(
      repository: repository,
      initialState: initial.copyWith(
        currentRoomId: 'snow_stone_road',
        worldTurn: 20,
        visitedRoomIds: {...initial.visitedRoomIds, 'snow_stone_road'},
        areaResetAtTurns: const {'dragonhill': 21},
        npcStates: {
          ...initial.npcStates,
          'dragonhill_gangster': firstBandit.copyWith(
            currentHp: 0,
            isDefeated: true,
          ),
          'dragonhill_gangster_2': secondBandit.copyWith(
            currentHp: 0,
            isDefeated: true,
          ),
        },
      ),
    );

    controller.dispatch(const GameAction.move(Direction.east));

    expect(
      controller.state.npcStates['dragonhill_gangster']?.isDefeated,
      isFalse,
    );
    expect(
      controller.state.npcStates['dragonhill_gangster_2']?.isDefeated,
      isFalse,
    );
    expect(controller.state.areaResetAtTurns, isNot(contains('dragonhill')));
  });

  test('original roaming npc follows its persisted patrol route', () {
    final initial = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initial.copyWith(
        currentRoomId: 'snow_official_road',
        worldTurn: 1,
        visitedRoomIds: {...initial.visitedRoomIds, 'snow_official_road'},
      ),
    );

    controller.dispatch(const GameAction.move(Direction.east));

    final dogState = controller.state.npcStates['snow_crazy_dog'];
    expect(controller.state.worldTurn, 2);
    expect(dogState?.roomId, 'snow_official_road');
    expect(dogState?.patrolStep, 1);
  });

  test('npc engaged in combat does not patrol away', () {
    final initial = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initial.copyWith(
        currentRoomId: 'snow_stone_road',
        worldTurn: 1,
        visitedRoomIds: {...initial.visitedRoomIds, 'snow_stone_road'},
      ),
    );

    controller.dispatch(const GameAction.startCombat('snow_crazy_dog'));
    controller.dispatch(const GameAction.attack());

    final dogState = controller.state.npcStates['snow_crazy_dog'];
    expect(controller.state.worldTurn, 2);
    expect(dogState?.roomId, 'snow_stone_road');
    expect(dogState?.patrolStep, 0);
  });

  test('npc patrol progress remains backward compatible in saves', () {
    const state = NpcRuntimeState(
      roomId: 'snow_main_street3',
      currentHp: 1,
      isDefeated: false,
      patrolStep: 3,
    );

    expect(NpcRuntimeState.fromJson(state.toJson()).patrolStep, 3);
    expect(
      NpcRuntimeState.fromJson({
        'roomId': 'snow_main_street3',
        'currentHp': 1,
        'isDefeated': false,
      }).patrolStep,
      0,
    );
    expect(
      NpcRuntimeState.fromJson({
        'roomId': 'snow_main_street3',
        'currentHp': 1,
        'isDefeated': false,
      }).stateValues,
      isEmpty,
    );
    final legacyState = NpcRuntimeState.fromJson({
      'roomId': 'snow_main_street3',
      'currentHp': 1,
      'isDefeated': false,
      'isFollowing': true,
    });
    expect(legacyState.followUntilTurn, isNull);
    expect(legacyState.followReturnRoomId, isNull);
  });

  test('npc private state supports requirements, assignment, and counters', () {
    const state = NpcRuntimeState(
      roomId: 'snow_east_path2',
      currentHp: 18,
      isDefeated: false,
      stateValues: {'trust': 1},
    );

    expect(state.matchesStateValues({'trust': 1, 'warned': 0}), isTrue);
    final changed = state.applyStateChanges(
      setValues: {'mood': 2},
      incrementValues: {'trust': 2, 'visits': 1},
    );

    expect(changed.stateValues, {'trust': 3, 'mood': 2, 'visits': 1});
  });

  test('visible npc cycles original ambient messages on world turns', () {
    final initial = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initial.copyWith(
        currentRoomId: 'snow_main_street3',
        worldTurn: 3,
        visitedRoomIds: {...initial.visitedRoomIds, 'snow_main_street3'},
      ),
    );

    controller.dispatch(const GameAction.move(Direction.south));

    expect(controller.state.currentRoomId, 'snow_main_street2');
    expect(controller.state.worldTurn, 4);
    expect(controller.state.log.last, contains('收——破——烂——哪'));
  });

  test('original inn waiter greets the player on room entry', () {
    final controller = GameController(repository: repository);

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.west));

    expect(controller.state.currentRoomId, 'snow_inn');
    expect(controller.state.log.last, contains('店小二'));
    expect(controller.state.log.last, contains('请进请进'));
  });

  test('aggressive npc starts combat on entry and prevents movement', () {
    final initial = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initial.copyWith(
        currentRoomId: 'snow_official_road',
        visitedRoomIds: {...initial.visitedRoomIds, 'snow_official_road'},
      ),
    );

    controller.dispatch(const GameAction.move(Direction.west));

    expect(controller.state.currentRoomId, 'snow_stone_road');
    expect(controller.state.combat?.npcId, 'snow_crazy_dog');
    expect(controller.state.log, contains(contains('狂吠着扑了过来')));

    controller.dispatch(const GameAction.move(Direction.east));

    expect(controller.state.currentRoomId, 'snow_stone_road');
    expect(controller.state.worldTurn, 1);
    expect(controller.state.log.last, contains('必须先击败对手'));
  });
}
