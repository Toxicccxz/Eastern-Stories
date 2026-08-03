import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';
import 'player_condition_system.dart';

class WorldSystem {
  const WorldSystem(this._repository, this._playerConditionSystem);

  final GameDefinitionRepository _repository;
  final PlayerConditionSystem _playerConditionSystem;

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
    final advancedState = next.copyWith(
      worldTurn: worldTurn,
      npcStates: npcStates,
      player: next.player.copyWith(
        spirit: (next.player.spirit + 2).clamp(0, next.player.maxSpirit),
      ),
    );
    final tickedState = _playerConditionSystem.advance(advancedState).state;
    if (tickedState.player.hp > 0) {
      return tickedState;
    }
    final startingRoomId = _repository.startingRoomId;
    return tickedState.copyWith(
      currentRoomId: startingRoomId,
      visitedRoomIds: {...tickedState.visitedRoomIds, startingRoomId},
      player: tickedState.player.copyWith(
        hp: (tickedState.player.maxHp ~/ 2).clamp(1, tickedState.player.maxHp),
        innerPower: (tickedState.player.maxInnerPower ~/ 2).clamp(
          0,
          tickedState.player.maxInnerPower,
        ),
      ),
      playerStatusEffects: const [],
      combat: null,
      log: tickedState.logWith('你在途中毒发昏倒，醒来时已经回到饮风客栈。'),
    );
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
