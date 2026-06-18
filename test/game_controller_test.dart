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

    controller.dispatch(const GameAction.move(Direction.north));

    expect(controller.state.currentRoomId, 'north_gate');
    expect(controller.state.visitedRoomIds, contains('north_gate'));
    expect(controller.state.log.last, contains('北门'));
  });

  test('picking up an item moves it into inventory', () {
    final controller = GameController(
      repository: GameDefinitionRepository.demo(),
    );

    controller.dispatch(const GameAction.pickUp('notice'));

    expect(controller.state.inventoryItemIds, contains('notice'));
    expect(
      controller.repository
          .room(controller.state.currentRoomId)
          .visibleItemIds(controller.state),
      isNot(contains('notice')),
    );
  });
}
