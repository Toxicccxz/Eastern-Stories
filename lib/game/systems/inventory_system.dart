import '../models/game_state.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'equipment_system.dart';
import 'skill_progression_system.dart';

class InventorySystem {
  const InventorySystem(
    this._repository,
    this._equipmentSystem,
    this._skillProgressionSystem,
  );

  final GameDefinitionRepository _repository;
  final EquipmentSystem _equipmentSystem;
  final SkillProgressionSystem _skillProgressionSystem;

  List<SkillDefinition> learnedSkills(GameState state) {
    return [
      for (final skillId in state.learnedSkillIds) _repository.skill(skillId),
    ];
  }

  GameState pickUp(GameState state, String itemId) {
    final room = _repository.room(state.currentRoomId);
    if (!_repository
            .visibleItemsInRoom(state, room.id)
            .any((item) => item.id == itemId) ||
        state.inventoryItemIds.contains(itemId)) {
      return _withLog(state, '这里没有这个东西。');
    }

    final item = _repository.item(itemId);
    return state.copyWith(
      roomItemOverrides: {
        ...state.roomItemOverrides,
        room.id:
            room.visibleItemIds(state).where((id) => id != itemId).toList(),
      },
      inventoryItemIds: [...state.inventoryItemIds, itemId],
      log: state.logWith('你捡起了${item.name}。'),
    );
  }

  GameState studyItem(GameState state, String itemId) {
    if (!state.inventoryItemIds.contains(itemId)) {
      return _withLog(state, '你还没有这个东西。');
    }

    final item = _repository.item(itemId);
    final skillId = item.studySkillId;
    if (skillId == null) {
      return _withLog(state, '${item.name}无法研读。');
    }
    return _skillProgressionSystem.study(
      state,
      skillId: skillId,
      itemName: item.name,
      experience: item.studyExperience,
      studyLevelLimit: item.studyMaxSkillLevel,
    );
  }

  GameState useItem(GameState state, String itemId) {
    if (!state.inventoryItemIds.contains(itemId)) {
      return _withLog(state, '你还没有这个东西。');
    }

    final item = _repository.item(itemId);
    if (!item.canUse) {
      return _withLog(state, '${item.name}现在不能使用。');
    }

    final inventory = [...state.inventoryItemIds]..remove(itemId);
    final stats = _equipmentSystem.statsFor(state);
    return state.copyWith(
      player: state.player.copyWith(
        hp: (state.player.hp + item.restoreHp).clamp(0, stats.maxHp),
        innerPower: (state.player.innerPower + item.restoreInnerPower).clamp(
          0,
          stats.maxInnerPower,
        ),
      ),
      inventoryItemIds: inventory,
      log: state.logWith('你用了${item.name}，精神稍振。'),
    );
  }

  GameState dropItem(GameState state, String itemId) {
    if (!state.inventoryItemIds.contains(itemId)) {
      return _withLog(state, '你还没有这个东西。');
    }

    final room = _repository.room(state.currentRoomId);
    final item = _repository.item(itemId);
    final inventory = [...state.inventoryItemIds]..remove(itemId);
    final unequippedState = _equipmentSystem.removeItemFromEquipment(
      state,
      itemId,
    );
    return unequippedState.copyWith(
      inventoryItemIds: inventory,
      roomItemOverrides: {
        ...unequippedState.roomItemOverrides,
        room.id: [...room.visibleItemIds(unequippedState), itemId],
      },
      log: unequippedState.logWith('你放下了${item.name}。'),
    );
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
