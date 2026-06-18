import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/direction.dart';
import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moving through an exit updates current room and log', () {
    final controller = GameController(
      repository: GameDefinitionRepository.demo(),
    );

    controller.dispatch(const GameAction.move(Direction.south));

    expect(controller.state.currentRoomId, 'little_garden');
    expect(controller.state.visitedRoomIds, contains('little_garden'));
    expect(controller.state.log.last, contains('花园'));
  });

  test('picking up an item moves it into inventory', () {
    final controller = GameController(
      repository: GameDefinitionRepository.demo(),
    );

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

  test('old liu quest can be started, progressed, and completed', () {
    final controller = GameController(
      repository: GameDefinitionRepository.demo(),
    );

    controller.dispatch(
      const GameAction.selectDialogue('old_liu', 'ask_daughter'),
    );
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(
      const GameAction.selectDialogue('flower_girl', 'found_girl'),
    );
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(
      const GameAction.selectDialogue('old_liu', 'report_daughter'),
    );

    expect(controller.state.inventoryItemIds, contains('hengbing_sword'));
    expect(controller.state.inventoryItemIds, contains('parry_book'));
    expect(controller.state.player.silver, 50);
    expect(controller.state.log.last, contains('完成委托'));
  });

  test('room actions can move the player through lake scenes', () {
    final controller = GameController(
      repository: GameDefinitionRepository.demo(),
    );

    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.performRoomAction('paddle_to_lake'));
    controller.dispatch(const GameAction.performRoomAction('dive_into_lake'));

    expect(controller.state.currentRoomId, 'underwater_cave');
    expect(controller.state.visitedRoomIds, contains('jade_snail_lake_center'));
    expect(controller.state.log.last, contains('岩洞'));
  });

  test('player can equip a weapon and defeat the ice dragon', () {
    final controller = GameController(
      repository: GameDefinitionRepository.demo(),
    );

    controller.dispatch(
      const GameAction.selectDialogue('old_liu', 'ask_daughter'),
    );
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(
      const GameAction.selectDialogue('flower_girl', 'found_girl'),
    );
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(
      const GameAction.selectDialogue('old_liu', 'report_daughter'),
    );
    controller.dispatch(const GameAction.equipItem('hengbing_sword'));

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
    expect(controller.state.combat, isNull);
    expect(controller.state.player.silver, 130);
    expect(controller.state.log.last, contains('白鳞冰龙'));
  });
}
