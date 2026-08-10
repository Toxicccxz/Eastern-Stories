import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/skill_progress.dart';
import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDefinitionRepository repository;

  setUpAll(() async {
    repository = await GameDefinitionRepository.loadDemo();
  });

  test('meditation converts spirit into mana with original formula', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        skillProgress: const {
          'spells': SkillProgress(level: 120, experience: 0),
        },
        player: initialState.player.copyWith(
          hp: 100,
          maxHp: 100,
          spirit: 100,
          maxSpirit: 100,
          mana: 100,
          maxMana: 200,
        ),
      ),
    );

    controller.dispatch(const GameAction.meditateForMana());

    expect(controller.state.player.spirit, 70);
    expect(controller.state.player.mana, 113);
    expect(controller.state.player.maxMana, 200);
    expect(controller.state.worldTurn, 1);
    expect(controller.state.log.last, contains('凝聚为13点法力'));
  });

  test('overcharged mana raises its maximum within the spells limit', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        skillProgress: const {
          'spells': SkillProgress(level: 100, experience: 0),
        },
        player: initialState.player.copyWith(
          hp: 100,
          maxHp: 100,
          spirit: 100,
          maxSpirit: 100,
          mana: 401,
          maxMana: 200,
        ),
      ),
    );

    controller.dispatch(const GameAction.meditateForMana());

    expect(controller.state.player.mana, 201);
    expect(controller.state.player.maxMana, 201);
    expect(controller.state.log.last, contains('法力上限提升到了201'));
  });

  test('poor health prevents mana meditation without advancing time', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        player: initialState.player.copyWith(
          hp: 69,
          maxHp: 100,
          spirit: 100,
          maxSpirit: 100,
        ),
      ),
    );

    controller.dispatch(const GameAction.meditateForMana());

    expect(controller.state.player.spirit, 100);
    expect(controller.state.worldTurn, 0);
    expect(controller.state.log.last, contains('身体状况太差'));
  });

  test('atman cultivation converts energy and opens its first level', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        skillProgress: const {'magic': SkillProgress(level: 50, experience: 0)},
        player: initialState.player.copyWith(
          hp: 100,
          maxHp: 100,
          spirit: 100,
          maxSpirit: 100,
          energy: 100,
          maxEnergy: 100,
          atman: 0,
          maxAtman: 0,
        ),
      ),
    );

    controller.dispatch(const GameAction.cultivateAtman());

    expect(controller.state.player.energy, 70);
    expect(controller.state.player.atman, 1);
    expect(controller.state.player.maxAtman, 1);
    expect(controller.state.worldTurn, 1);
    expect(controller.state.log.last, contains('灵力上限提升到了1'));
  });

  test('low spirit prevents atman cultivation without spending energy', () {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        player: initialState.player.copyWith(
          hp: 100,
          maxHp: 100,
          spirit: 69,
          maxSpirit: 100,
          energy: 100,
          maxEnergy: 100,
        ),
      ),
    );

    controller.dispatch(const GameAction.cultivateAtman());

    expect(controller.state.player.energy, 100);
    expect(controller.state.worldTurn, 0);
    expect(controller.state.log.last, contains('精神状况太差'));
  });
}
