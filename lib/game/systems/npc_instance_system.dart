import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';

class NpcInstanceSystem {
  const NpcInstanceSystem(this._repository);

  final GameDefinitionRepository _repository;

  GameState spawn(
    GameState state, {
    required String definitionId,
    required String roomId,
    required int count,
    required String instancePrefix,
  }) {
    return spawnWithResult(
      state,
      definitionId: definitionId,
      roomId: roomId,
      count: count,
      instancePrefix: instancePrefix,
    ).state;
  }

  NpcInstanceSpawnResult spawnWithResult(
    GameState state, {
    required String definitionId,
    required String roomId,
    required int count,
    required String instancePrefix,
  }) {
    if (count <= 0) {
      return NpcInstanceSpawnResult(state: state, instanceIds: const []);
    }
    _repository.room(roomId);
    _repository.npc(definitionId);

    final npcStates = {...state.npcStates};
    final instanceIds = <String>[];
    var nextIndex = 1;
    for (var spawned = 0; spawned < count; spawned++) {
      while (npcStates.containsKey('${instancePrefix}_$nextIndex')) {
        nextIndex++;
      }
      final instanceId = '${instancePrefix}_$nextIndex';
      npcStates[instanceId] = _repository.createNpcInstanceState(
        definitionId,
        roomId,
      );
      instanceIds.add(instanceId);
      nextIndex++;
    }
    return NpcInstanceSpawnResult(
      state: state.copyWith(npcStates: npcStates),
      instanceIds: instanceIds,
    );
  }
}

class NpcInstanceSpawnResult {
  const NpcInstanceSpawnResult({
    required this.state,
    required this.instanceIds,
  });

  final GameState state;
  final List<String> instanceIds;
}
