import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
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

  test('meditation raises inner power within the force skill limit', () {
    final controller = _controllerWithForce(repository);

    controller.dispatch(const GameAction.meditate());

    expect(controller.innerPowerCultivationLimit(), 50);
    expect(controller.state.player.maxInnerPower, 32);
    expect(controller.state.player.innerPower, 34);
    expect(controller.state.player.spirit, 48);
  });

  test('meditation requires a quiet cultivation room', () {
    final controller = _controllerWithForce(repository);
    controller.replaceState(
      controller.state.copyWith(currentRoomId: 'village_road'),
    );

    controller.dispatch(const GameAction.meditate());

    expect(controller.state.log.last, contains('不适合静坐'));
    expect(controller.state.player.maxInnerPower, 30);
  });

  test('regulated breathing converts inner power into health', () {
    final controller = _controllerWithForce(repository);
    controller.replaceState(
      controller.state.copyWith(
        player: controller.state.player.copyWith(hp: 40, innerPower: 30),
      ),
    );

    controller.dispatch(const GameAction.recoverWithInnerPower());

    expect(controller.state.player.hp, 51);
    expect(controller.state.player.innerPower, 10);
  });

  test('Fengshan healing consumes overcharged inner power', () {
    final controller = _controllerWithForce(repository);
    controller.replaceState(
      controller.state.copyWith(
        player: controller.state.player.copyWith(
          hp: 40,
          maxInnerPower: 50,
          innerPower: 100,
        ),
      ),
    );

    controller.dispatch(const GameAction.healWithInnerPower());

    expect(controller.state.player.hp, 61);
    expect(controller.state.player.innerPower, 50);
    expect(controller.state.skillProgress['fonxan_force']?.experience, 5);
  });
}

GameController _controllerWithForce(GameDefinitionRepository repository) {
  final initial = repository.createInitialState();
  return GameController(
    repository: repository,
    initialState: initial.copyWith(
      currentRoomId: 'liu_home',
      skillProgress: {
        ...initial.skillProgress,
        'basic_force': const SkillProgress(level: 5, experience: 0),
        'fonxan_force': const SkillProgress(level: 1, experience: 0),
      },
      enabledSkillIds: const {SkillUsage.force: 'fonxan_force'},
    ),
  );
}
