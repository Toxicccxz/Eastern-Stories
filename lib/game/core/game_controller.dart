import 'package:flutter/foundation.dart';

import '../models/direction.dart';
import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';
import 'game_action.dart';

class GameController extends ChangeNotifier {
  GameController({required GameDefinitionRepository repository})
    : _repository = repository,
      _state = GameState.initial(startingRoomId: repository.startingRoomId);

  final GameDefinitionRepository _repository;
  GameState _state;

  GameDefinitionRepository get repository => _repository;

  GameState get state => _state;

  void dispatch(GameAction action) {
    switch (action) {
      case MoveAction(:final direction):
        _move(direction);
      case LookAction():
        _look();
      case TalkAction(:final npcId):
        _talk(npcId);
      case PickUpAction(:final itemId):
        _pickUp(itemId);
    }
  }

  void _move(Direction direction) {
    final room = _repository.room(_state.currentRoomId);
    final nextRoomId = room.exits[direction];
    if (nextRoomId == null) {
      _appendLog('这个方向没有路。');
      return;
    }

    final nextRoom = _repository.room(nextRoomId);
    _state = _state.copyWith(
      currentRoomId: nextRoomId,
      visitedRoomIds: {..._state.visitedRoomIds, nextRoomId},
      log: _state.logWith('你向${direction.label}走去，来到${nextRoom.name}。'),
    );
    notifyListeners();
  }

  void _look() {
    final room = _repository.room(_state.currentRoomId);
    _appendLog(room.description);
  }

  void _talk(String npcId) {
    final npc = _repository.npc(npcId);
    _appendLog('${npc.name}说道：“${npc.greeting}”');
  }

  void _pickUp(String itemId) {
    final room = _repository.room(_state.currentRoomId);
    if (!room.itemIds.contains(itemId) ||
        _state.inventoryItemIds.contains(itemId)) {
      _appendLog('这里没有这个东西。');
      return;
    }

    final item = _repository.item(itemId);
    _state = _state.copyWith(
      roomItemOverrides: {
        ..._state.roomItemOverrides,
        room.id:
            room.visibleItemIds(_state).where((id) => id != itemId).toList(),
      },
      inventoryItemIds: [..._state.inventoryItemIds, itemId],
      log: _state.logWith('你拾起了${item.name}。'),
    );
    notifyListeners();
  }

  void _appendLog(String message) {
    _state = _state.copyWith(log: _state.logWith(message));
    notifyListeners();
  }
}
