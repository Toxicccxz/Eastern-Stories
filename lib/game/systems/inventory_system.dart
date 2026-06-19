import '../models/game_state.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';

class InventorySystem {
  const InventorySystem(this._repository);

  final GameDefinitionRepository _repository;

  List<SkillDefinition> learnedSkills(GameState state) {
    return [
      for (final skillId in state.learnedSkillIds) _repository.skill(skillId),
    ];
  }

  GameState pickUp(GameState state, String itemId) {
    final room = _repository.room(state.currentRoomId);
    if (!room.visibleItemIds(state).contains(itemId) ||
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

  GameState equipItem(GameState state, String itemId) {
    if (!state.inventoryItemIds.contains(itemId)) {
      return _withLog(state, '你还没有这个东西。');
    }

    final item = _repository.item(itemId);
    if (!item.canEquip) {
      return _withLog(state, '${item.name}不能装备。');
    }

    return state.copyWith(
      equippedWeaponId: itemId,
      log: state.logWith('你装备了${item.name}。'),
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
    if (state.learnedSkillIds.contains(skillId)) {
      return _withLog(state, '你已经领会了${_repository.skill(skillId).name}。');
    }

    final skill = _repository.skill(skillId);
    return state.copyWith(
      learnedSkillIds: {...state.learnedSkillIds, skillId},
      log: state.logWith('你研读${item.name}，领会了${skill.name}。'),
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
    return state.copyWith(
      player: state.player.copyWith(
        hp: (state.player.hp + item.restoreHp).clamp(0, state.player.maxHp),
        innerPower: (state.player.innerPower + item.restoreInnerPower).clamp(
          0,
          state.player.maxInnerPower,
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
    return state.copyWith(
      inventoryItemIds: inventory,
      equippedWeaponId:
          state.equippedWeaponId == itemId ? null : state.equippedWeaponId,
      roomItemOverrides: {
        ...state.roomItemOverrides,
        room.id: [...room.visibleItemIds(state), itemId],
      },
      log: state.logWith('你放下了${item.name}。'),
    );
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
