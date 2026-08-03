import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/models/direction.dart';
import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDefinitionRepository repository;

  setUpAll(() async {
    repository = await GameDefinitionRepository.loadDemo();
  });

  test('blocking status consumes the turn and damages multiple resources', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'latemoon_entrance',
        visitedRoomIds: {...initialState.visitedRoomIds, 'latemoon_entrance'},
        combat: const CombatState(
          npcId: 'latemoon_guard',
          enemyHp: 48,
          playerStatusEffects: [
            StatusEffectState(
              id: 'slumber_drug',
              name: '蒙汗药',
              remainingRounds: 2,
              spiritDamagePerRound: 3,
              innerPowerDamagePerRound: 2,
              blocksAction: true,
            ),
          ],
        ),
      ),
    );

    controller.dispatch(const GameAction.attack());

    expect(controller.state.combat?.enemyHp, 48);
    expect(controller.state.combat?.round, 1);
    expect(controller.state.player.spirit, initialState.player.spirit - 3);
    expect(
      controller.state.player.innerPower,
      initialState.player.innerPower - 2,
    );
    expect(controller.state.playerStatusEffects.single.remainingRounds, 1);
    expect(controller.state.log, contains(contains('未能及时出手')));
  });

  test('status effect save data remains backward compatible', () {
    final legacy = StatusEffectState.fromJson({
      'id': 'legacy_poison',
      'name': '旧毒',
      'remainingRounds': 2,
      'damagePerRound': 1,
    });

    expect(legacy.spiritDamagePerRound, 0);
    expect(legacy.innerPowerDamagePerRound, 0);
    expect(legacy.hpRecoveryPerRound, 0);
    expect(legacy.blocksAction, isFalse);

    final restored = StatusEffectState.fromJson(legacy.toJson());
    expect(restored.damagePerRound, 1);
    expect(restored.blocksAction, isFalse);
  });

  test('snake poison persists during travel and snake medicine reduces it', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        inventoryItemIds: [...initialState.inventoryItemIds, 'snow_snake_drug'],
        playerStatusEffects: const [
          StatusEffectState(
            id: 'snake_poison',
            name: '蛇毒',
            remainingRounds: 4,
            damagePerRound: 4,
            spiritDamagePerRound: 3,
          ),
        ],
      ),
    );

    controller.dispatch(const GameAction.move(Direction.east));

    expect(controller.state.currentRoomId, 'snow_square');
    expect(controller.state.player.hp, initialState.player.hp - 4);
    expect(controller.state.playerStatusEffects.single.remainingRounds, 3);

    controller.dispatch(const GameAction.useItem('snow_snake_drug'));

    expect(
      controller.state.inventoryItemIds,
      isNot(contains('snow_snake_drug')),
    );
    expect(controller.state.playerStatusEffects.single.remainingRounds, 2);
    expect(controller.state.log, contains(contains('蛇毒减轻')));
  });

  test('original old pine venom snake applies persistent snake poison', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'oldpine_deep_passage',
        visitedRoomIds: {
          ...initialState.visitedRoomIds,
          'oldpine_deep_passage',
        },
        player: initialState.player.copyWith(hp: 400, maxHp: 400),
      ),
    );

    controller.dispatch(const GameAction.startCombat('oldpine_venom_snake'));
    for (var turn = 0; turn < 3; turn++) {
      controller.dispatch(const GameAction.attack());
    }

    expect(
      controller.state.playerStatusEffects.map((effect) => effect.id),
      contains('snake_poison'),
    );
  });
}
