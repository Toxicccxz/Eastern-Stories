import '../models/direction.dart';
import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';

class MovementSystem {
  const MovementSystem(this._repository);

  final GameDefinitionRepository _repository;

  GameState move(GameState state, Direction direction) {
    final room = _repository.room(state.currentRoomId);
    final nextRoomId = room.availableExits(state)[direction];
    if (nextRoomId == null) {
      return _withLog(state, '这个方向没有路。');
    }

    final nextRoom = _repository.room(nextRoomId);
    return state.copyWith(
      currentRoomId: nextRoomId,
      visitedRoomIds: {...state.visitedRoomIds, nextRoomId},
      log: state.logWith('你向${direction.label}走去，来到${nextRoom.name}。'),
    );
  }

  GameState look(GameState state) {
    final room = _repository.room(state.currentRoomId);
    return _withLog(state, room.description);
  }

  GameState performRoomAction(GameState state, String actionId) {
    final room = _repository.room(state.currentRoomId);
    final action =
        room
            .availableActions(state)
            .where((item) => item.id == actionId)
            .firstOrNull;
    if (action == null) {
      return _withLog(state, '这里暂时不能这样做。');
    }

    final nextRoom = _repository.room(action.resultRoomId);
    return state.copyWith(
      currentRoomId: nextRoom.id,
      visitedRoomIds: {...state.visitedRoomIds, nextRoom.id},
      questFlags:
          action.setsQuestFlag == null
              ? state.questFlags
              : {...state.questFlags, action.setsQuestFlag!},
      inventoryItemIds: [...state.inventoryItemIds, ...action.givesItemIds],
      log: state.logWith(action.log),
    );
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
