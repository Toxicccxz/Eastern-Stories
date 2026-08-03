import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';
import 'player_condition_system.dart';

class WorldSystem {
  const WorldSystem(this._repository, this._playerConditionSystem);

  final GameDefinitionRepository _repository;
  final PlayerConditionSystem _playerConditionSystem;

  RoomEntryResult resolveRoomEntry(GameState state) {
    if (state.combat != null) {
      return RoomEntryResult(state);
    }

    var nextState = state;
    String? hostileNpcId;
    for (final npc in _repository.visibleNpcsInRoom(
      nextState,
      nextState.currentRoomId,
    )) {
      for (final reaction in npc.entryReactions) {
        if (!(reaction.conditions?.isSatisfiedBy(nextState) ?? true)) {
          continue;
        }
        if (reaction.messages.isNotEmpty) {
          final message =
              reaction.messages[nextState.worldTurn % reaction.messages.length];
          nextState = nextState.copyWith(log: nextState.logWith(message));
        }
        if (reaction.setsFlag != null) {
          nextState = nextState.copyWith(
            questFlags: {...nextState.questFlags, reaction.setsFlag!},
          );
        }
        if (reaction.startsCombat) {
          hostileNpcId = npc.id;
        }
        break;
      }
      if (hostileNpcId != null) {
        break;
      }
    }
    return RoomEntryResult(nextState, hostileNpcId: hostileNpcId);
  }

  GameState advance(
    GameState previous,
    GameState next,
    WorldActionType actionType,
  ) {
    final worldTurn = previous.worldTurn + 1;
    final npcStates = <String, NpcRuntimeState>{};
    final worldMessages = <String>[];
    final activeCombatNpcId = previous.combat?.npcId ?? next.combat?.npcId;
    for (final entry in next.npcStates.entries) {
      final result = _advanceNpc(
        entry.key,
        entry.value,
        worldTurn,
        next.currentRoomId,
        activeCombatNpcId,
      );
      npcStates[entry.key] = result.state;
      if (result.message != null) {
        worldMessages.add(result.message!);
      }
    }
    var advancedState = next.copyWith(
      worldTurn: worldTurn,
      npcStates: npcStates,
    );
    for (final message in worldMessages) {
      advancedState = advancedState.copyWith(
        log: advancedState.logWith(message),
      );
    }
    if (advancedState.combat == null) {
      for (final message in _ambientMessages(advancedState, worldTurn)) {
        advancedState = advancedState.copyWith(
          log: advancedState.logWith(message),
        );
      }
    }
    if (actionType == WorldActionType.travel) {
      advancedState = advancedState.copyWith(
        player: advancedState.player.copyWith(
          spirit: (advancedState.player.spirit + 2).clamp(
            0,
            advancedState.player.maxSpirit,
          ),
        ),
      );
    }
    final tickedState =
        actionType == WorldActionType.combat
            ? advancedState
            : _playerConditionSystem.advance(advancedState).state;
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
      log: tickedState.logWith(
        actionType == WorldActionType.travel
            ? '你在途中伤势发作昏倒，醒来时已经回到饮风客栈。'
            : '你在行功时伤势发作昏倒，醒来时已经回到饮风客栈。',
      ),
    );
  }

  Iterable<String> _ambientMessages(GameState state, int worldTurn) sync* {
    for (final npc in _repository.visibleNpcsInRoom(
      state,
      state.currentRoomId,
    )) {
      final ambient = npc.ambient;
      if (ambient == null ||
          ambient.messages.isEmpty ||
          ambient.intervalTurns <= 0 ||
          worldTurn % ambient.intervalTurns != 0) {
        continue;
      }
      final messageIndex =
          (worldTurn ~/ ambient.intervalTurns - 1) % ambient.messages.length;
      yield ambient.messages[messageIndex];
    }
  }

  _NpcAdvanceResult _advanceNpc(
    String npcId,
    NpcRuntimeState state,
    int worldTurn,
    String playerRoomId,
    String? activeCombatNpcId,
  ) {
    if (state.isRemoved) {
      return _NpcAdvanceResult(state);
    }

    var nextState = state;
    var justRespawned = false;
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
      justRespawned = true;
    }

    if (nextState.isFollowing) {
      return _NpcAdvanceResult(nextState.copyWith(roomId: playerRoomId));
    }
    if (nextState.isDefeated || justRespawned || npcId == activeCombatNpcId) {
      return _NpcAdvanceResult(nextState);
    }

    final npc = _repository.npc(npcId);
    final patrol = npc.patrol;
    if (patrol == null ||
        patrol.roomIds.length < 2 ||
        patrol.intervalTurns <= 0 ||
        worldTurn % patrol.intervalTurns != 0) {
      return _NpcAdvanceResult(nextState);
    }

    var currentStep = nextState.patrolStep;
    if (currentStep >= patrol.roomIds.length ||
        patrol.roomIds[currentStep] != nextState.roomId) {
      currentStep = patrol.roomIds.indexOf(nextState.roomId);
      if (currentStep < 0) {
        return _NpcAdvanceResult(nextState);
      }
    }
    final nextStep = (currentStep + 1) % patrol.roomIds.length;
    final targetRoomId = patrol.roomIds[nextStep];
    final movedState = nextState.copyWith(
      roomId: targetRoomId,
      patrolStep: nextStep,
    );
    final message =
        nextState.roomId == playerRoomId
            ? '${npc.name}离开了这里。'
            : targetRoomId == playerRoomId
            ? '${npc.name}来到了这里。'
            : null;
    return _NpcAdvanceResult(movedState, message: message);
  }
}

enum WorldActionType { travel, activity, combat }

class RoomEntryResult {
  const RoomEntryResult(this.state, {this.hostileNpcId});

  final GameState state;
  final String? hostileNpcId;
}

class _NpcAdvanceResult {
  const _NpcAdvanceResult(this.state, {this.message});

  final NpcRuntimeState state;
  final String? message;
}
