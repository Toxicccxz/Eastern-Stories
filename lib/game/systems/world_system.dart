import '../models/game_state.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'player_condition_system.dart';
import 'npc_instance_system.dart';
import 'area_lifecycle_system.dart';

class WorldSystem {
  WorldSystem(this._repository, this._playerConditionSystem)
    : _npcInstanceSystem = NpcInstanceSystem(_repository),
      _areaLifecycleSystem = AreaLifecycleSystem(_repository);

  final GameDefinitionRepository _repository;
  final PlayerConditionSystem _playerConditionSystem;
  final NpcInstanceSystem _npcInstanceSystem;
  final AreaLifecycleSystem _areaLifecycleSystem;

  RoomEntryResult resolveRoomEntry(GameState state, {String? previousRoomId}) {
    if (state.combat != null) {
      return RoomEntryResult(state);
    }

    var nextState = _applyRoomEntryEvent(state, previousRoomId);
    String? hostileNpcId;
    for (final npc in _repository.visibleNpcsInRoom(
      nextState,
      nextState.currentRoomId,
    )) {
      for (final reaction in npc.entryReactions) {
        if (!(reaction.conditions?.isSatisfiedBy(nextState) ?? true)) {
          continue;
        }
        final npcState = nextState.npcStates[npc.id];
        if (!(npcState?.matchesStateValues(reaction.requiredNpcStateValues) ??
            reaction.requiredNpcStateValues.isEmpty)) {
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
        if (npcState != null &&
            (reaction.setNpcStateValues.isNotEmpty ||
                reaction.incrementNpcStateValues.isNotEmpty)) {
          nextState = nextState.copyWith(
            npcStates: {
              ...nextState.npcStates,
              npc.id: npcState.applyStateChanges(
                setValues: reaction.setNpcStateValues,
                incrementValues: reaction.incrementNpcStateValues,
              ),
            },
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

  GameState _applyRoomEntryEvent(GameState state, String? previousRoomId) {
    final event = _repository.room(state.currentRoomId).entryEvent;
    if (event == null ||
        state.questFlags.contains(event.onceFlag) ||
        (event.previousRoomId != null &&
            event.previousRoomId != previousRoomId)) {
      return state;
    }

    final blockedRoomExits = {
      for (final entry in state.blockedRoomExits.entries)
        entry.key: {...entry.value},
    };
    for (final exit in event.blockedExits) {
      blockedRoomExits.putIfAbsent(exit.roomId, () => {}).add(exit.direction);
    }
    var nextState = state.copyWith(
      blockedRoomExits: blockedRoomExits,
      questFlags: {...state.questFlags, event.onceFlag},
      log: state.logWith(event.log),
    );
    for (final spawn in event.spawns) {
      nextState = _npcInstanceSystem.spawn(
        nextState,
        definitionId: spawn.definitionId,
        roomId: spawn.roomId,
        count: spawn.count,
        instancePrefix: spawn.instancePrefix,
      );
    }
    return nextState;
  }

  GameState advance(
    GameState previous,
    GameState next,
    WorldActionType actionType,
  ) {
    final worldTurn = previous.worldTurn + 1;
    next = _areaLifecycleSystem.advance(previous, next, worldTurn: worldTurn);
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
    for (final corpse in advancedState.corpses.values) {
      if (corpse.roomId != advancedState.currentRoomId) {
        continue;
      }
      if (corpse.rottensAtTurn == worldTurn) {
        advancedState = advancedState.copyWith(
          log: advancedState.logWith('${corpse.victimName}的尸体开始腐烂，发出一股难闻的恶臭。'),
        );
      } else if (corpse.skeletonizesAtTurn == worldTurn) {
        advancedState = advancedState.copyWith(
          log: advancedState.logWith('腐烂的尸体被风吹干，变成了一具骸骨。'),
        );
      }
    }
    final decayedCorpses =
        advancedState.corpses.values
            .where((corpse) => corpse.decaysAtTurn <= worldTurn)
            .toList();
    if (decayedCorpses.isNotEmpty) {
      final corpses = {...advancedState.corpses};
      final droppedItemsByRoom = <String, List<String>>{};
      for (final corpse in decayedCorpses) {
        corpses.remove(corpse.id);
        final droppedItems = droppedItemsByRoom.putIfAbsent(
          corpse.roomId,
          () => [],
        );
        for (final entry in corpse.itemCounts.entries) {
          for (var index = 0; index < entry.value; index++) {
            droppedItems.add(entry.key);
          }
        }
      }
      final roomItemOverrides = {...advancedState.roomItemOverrides};
      for (final entry in droppedItemsByRoom.entries) {
        if (entry.value.isEmpty) {
          continue;
        }
        roomItemOverrides[entry.key] = [
          ..._repository.room(entry.key).visibleItemIds(advancedState),
          ...entry.value,
        ];
      }
      advancedState = advancedState.copyWith(
        corpses: corpses,
        roomItemOverrides: roomItemOverrides,
      );
      for (final corpse in decayedCorpses) {
        if (corpse.roomId == advancedState.currentRoomId) {
          advancedState = advancedState.copyWith(
            log: advancedState.logWith('一阵风吹过，把一具枯干的骸骨化成骨灰吹散了。'),
          );
        }
      }
    }
    final companion = advancedState.undeadCompanion;
    if (companion != null) {
      if (companion.remainingTurns <= 1) {
        final combat = advancedState.combat;
        advancedState = advancedState.copyWith(
          undeadCompanion: null,
          combat:
              combat?.ally?.persistent ?? false
                  ? combat?.copyWith(ally: null)
                  : combat,
          log: advancedState.logWith('${companion.name}忽然一阵抽搐，倒在地上化为一滩血水。'),
        );
      } else {
        advancedState = advancedState.copyWith(
          undeadCompanion: companion.copyWith(
            remainingTurns: companion.remainingTurns - 1,
          ),
        );
      }
    }
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
          energy: (advancedState.player.energy + 2).clamp(
            0,
            advancedState.player.maxEnergy,
          ),
          atman:
              advancedState.player.atman < advancedState.player.maxAtman
                  ? (advancedState.player.atman + _atmanRecovery(advancedState))
                      .clamp(0, advancedState.player.maxAtman)
                  : advancedState.player.atman,
          mana:
              advancedState.player.mana < advancedState.player.maxMana
                  ? (advancedState.player.mana + 2).clamp(
                    0,
                    advancedState.player.maxMana,
                  )
                  : advancedState.player.mana,
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
        mana: (tickedState.player.maxMana ~/ 2).clamp(
          0,
          tickedState.player.maxMana,
        ),
        energy: (tickedState.player.maxEnergy ~/ 2).clamp(
          0,
          tickedState.player.maxEnergy,
        ),
        atman: (tickedState.player.maxAtman ~/ 2).clamp(
          0,
          tickedState.player.maxAtman,
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

  int _atmanRecovery(GameState state) {
    final skillId = _repository.basicSkillFor(SkillUsage.magic)?.id;
    if (skillId == null) {
      return 0;
    }
    return (state.skillProgress[skillId]?.level ?? 0) ~/ 2;
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
    final definitionId = state.definitionId ?? npcId;
    final npc = _repository.npc(definitionId);
    var justRespawned = false;
    final respawnAtTurn = state.respawnAtTurn;
    if (state.isDefeated &&
        respawnAtTurn != null &&
        respawnAtTurn <= worldTurn) {
      final combat = npc.combat;
      nextState = state.copyWith(
        currentHp: combat?.maxHp ?? 0,
        currentEnergy: combat?.maxEnergy ?? 0,
        currentSpirit: combat?.maxSpirit ?? 0,
        currentMana: combat?.maxMana ?? 0,
        isDefeated: false,
        respawnAtTurn: null,
        hasDroppedLoot: false,
        itemCounts: _repository.initialNpcItemCounts(definitionId),
        equippedItemIds: _repository.initialNpcEquippedItemIds(definitionId),
        inventoryInitialized: true,
      );
      justRespawned = true;
    }

    final followUntilTurn = nextState.followUntilTurn;
    if (nextState.isFollowing &&
        followUntilTurn != null &&
        followUntilTurn <= worldTurn) {
      return _NpcAdvanceResult(
        nextState
            .copyWith(
              roomId: nextState.followReturnRoomId ?? nextState.roomId,
              isFollowing: false,
              followUntilTurn: null,
              followReturnRoomId: null,
            )
            .applyStateChanges(setValues: npc.followEndStateValues),
        message: npc.followEndMessage ?? '${npc.name}向你告辞，转身离开了。',
      );
    }
    if (nextState.isFollowing) {
      return _NpcAdvanceResult(nextState.copyWith(roomId: playerRoomId));
    }
    if (nextState.isDefeated || justRespawned || npcId == activeCombatNpcId) {
      return _NpcAdvanceResult(nextState);
    }

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
