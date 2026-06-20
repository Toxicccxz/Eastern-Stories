import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';

class WorldSystem {
  const WorldSystem(this._repository);

  final GameDefinitionRepository _repository;

  GameState advanceAfterTravel(GameState previous, GameState next) {
    if (previous.currentRoomId == next.currentRoomId) {
      return next;
    }

    final worldTurn = previous.worldTurn + 1;
    final npcStates = {
      for (final entry in next.npcStates.entries)
        entry.key: _advanceNpc(
          entry.key,
          entry.value,
          worldTurn,
          next.currentRoomId,
        ),
    };
    return next.copyWith(worldTurn: worldTurn, npcStates: npcStates);
  }

  NpcRuntimeState _advanceNpc(
    String npcId,
    NpcRuntimeState state,
    int worldTurn,
    String playerRoomId,
  ) {
    if (state.isRemoved) {
      return state;
    }

    var nextState = state;
    final respawnAtTurn = state.respawnAtTurn;
    if (state.isDefeated &&
        respawnAtTurn != null &&
        respawnAtTurn <= worldTurn) {
      final maxHp = _repository.npc(npcId).combat?.maxHp ?? 0;
      nextState = state.copyWith(
        currentHp: maxHp,
        isDefeated: false,
        respawnAtTurn: null,
      );
    }

    return nextState.isFollowing
        ? nextState.copyWith(roomId: playerRoomId)
        : nextState;
  }
}
