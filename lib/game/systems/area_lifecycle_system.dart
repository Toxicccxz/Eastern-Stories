import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';

class AreaLifecycleSystem {
  const AreaLifecycleSystem(this._repository);

  final GameDefinitionRepository _repository;

  GameState advance(
    GameState previous,
    GameState next, {
    required int worldTurn,
  }) {
    final previousAreaId = _repository.room(previous.currentRoomId).areaId;
    final currentAreaId = _repository.room(next.currentRoomId).areaId;
    final resetAtTurns = {...next.areaResetAtTurns}..remove(currentAreaId);

    if (previousAreaId != currentAreaId) {
      final resetAfterTurns = _repository.area(previousAreaId).resetAfterTurns;
      if (resetAfterTurns != null) {
        resetAtTurns[previousAreaId] = worldTurn + resetAfterTurns;
      }
    }

    var state = next.copyWith(areaResetAtTurns: resetAtTurns);
    final dueAreaIds = [
      for (final entry in resetAtTurns.entries)
        if (entry.value <= worldTurn && entry.key != currentAreaId) entry.key,
    ];
    for (final areaId in dueAreaIds) {
      state = _resetArea(state, areaId);
    }
    return state;
  }

  GameState _resetArea(GameState state, String areaId) {
    final rooms = _repository.roomsInArea(areaId).toList(growable: false);
    final roomIds = rooms.map((room) => room.id).toSet();
    final initialNpcStates = _repository.initialAreaResetNpcStatesInArea(
      areaId,
    );
    final npcStates = {...state.npcStates};
    final removedDynamicNpcIds = <String>{};

    npcStates.removeWhere((npcId, npcState) {
      final shouldRemove =
          npcState.definitionId != null && roomIds.contains(npcState.roomId);
      if (shouldRemove) {
        removedDynamicNpcIds.add(npcId);
      }
      return shouldRemove;
    });
    npcStates.addAll(initialNpcStates);

    final roomItemOverrides = {...state.roomItemOverrides}
      ..removeWhere((roomId, _) => roomIds.contains(roomId));
    final blockedRoomExits = {
      for (final entry in state.blockedRoomExits.entries)
        entry.key: {...entry.value},
    };
    for (final room in rooms) {
      blockedRoomExits.remove(room.id);
      final event = room.entryEvent;
      if (event == null || !event.resetsWithArea) {
        continue;
      }
      for (final exit in event.blockedExits) {
        final directions = blockedRoomExits[exit.roomId];
        directions?.remove(exit.direction);
        if (directions?.isEmpty ?? false) {
          blockedRoomExits.remove(exit.roomId);
        }
      }
    }

    final resettableFlags = {
      for (final room in rooms)
        if (room.entryEvent case final event? when event.resetsWithArea)
          event.onceFlag,
    };
    final questFlags = {...state.questFlags}..removeAll(resettableFlags);
    final shopStates =
        {...state.shopStates}
          ..removeWhere((npcId, _) => removedDynamicNpcIds.contains(npcId))
          ..addAll(_repository.initialShopStatesInArea(areaId));
    final areaResetAtTurns = {...state.areaResetAtTurns}..remove(areaId);

    return state.copyWith(
      roomItemOverrides: roomItemOverrides,
      blockedRoomExits: blockedRoomExits,
      areaResetAtTurns: areaResetAtTurns,
      npcStates: npcStates,
      shopStates: shopStates,
      questFlags: questFlags,
    );
  }
}
