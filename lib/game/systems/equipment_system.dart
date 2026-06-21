import '../models/equipment_slot.dart';
import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';

class EquipmentSystem {
  const EquipmentSystem(this._repository);

  final GameDefinitionRepository _repository;

  CharacterStats statsFor(GameState state) {
    var attackBonus = 0;
    var defenseBonus = 0;
    var maxHpBonus = 0;
    var maxInnerPowerBonus = 0;
    for (final itemId in state.equippedItemIds.values) {
      final item = _repository.item(itemId);
      attackBonus += item.attackPower;
      defenseBonus += item.defensePower;
      maxHpBonus += item.maxHpBonus;
      maxInnerPowerBonus += item.maxInnerPowerBonus;
    }

    return CharacterStats(
      attack: 2 + state.player.attributes.strength ~/ 3 + attackBonus,
      defense: state.player.attributes.composure ~/ 10 + defenseBonus,
      maxHp: state.player.maxHp + maxHpBonus,
      maxInnerPower: state.player.maxInnerPower + maxInnerPowerBonus,
      attackBonus: attackBonus,
      defenseBonus: defenseBonus,
      maxHpBonus: maxHpBonus,
      maxInnerPowerBonus: maxInnerPowerBonus,
    );
  }

  GameState equipItem(GameState state, String itemId) {
    if (!state.inventoryItemIds.contains(itemId)) {
      return _withLog(state, '你还没有这个东西。');
    }

    final item = _repository.item(itemId);
    final slot = item.equipmentSlot;
    if (slot == null) {
      return _withLog(state, '${item.name}不能装备。');
    }
    if (state.equippedItemIds[slot] == itemId) {
      return _withLog(state, '你已经装备了${item.name}。');
    }

    final replacedItemId = state.equippedItemIds[slot];
    final replacedText =
        replacedItemId == null
            ? ''
            : '，替换了${_repository.item(replacedItemId).name}';
    return state.copyWith(
      equippedItemIds: {...state.equippedItemIds, slot: itemId},
      log: state.logWith('你装备了${item.name}$replacedText。'),
    );
  }

  GameState unequipItem(GameState state, EquipmentSlot slot) {
    final itemId = state.equippedItemIds[slot];
    if (itemId == null) {
      return _withLog(state, '${slot.label}栏没有装备。');
    }

    final equipment = {...state.equippedItemIds}..remove(slot);
    final nextState = _clampVitals(state.copyWith(equippedItemIds: equipment));
    return nextState.copyWith(
      log: nextState.logWith('你卸下了${_repository.item(itemId).name}。'),
    );
  }

  GameState removeItemFromEquipment(GameState state, String itemId) {
    final equipment = Map<EquipmentSlot, String>.fromEntries(
      state.equippedItemIds.entries.where((entry) => entry.value != itemId),
    );
    if (equipment.length == state.equippedItemIds.length) {
      return state;
    }
    return _clampVitals(state.copyWith(equippedItemIds: equipment));
  }

  GameState _clampVitals(GameState state) {
    final stats = statsFor(state);
    return state.copyWith(
      player: state.player.copyWith(
        hp: state.player.hp.clamp(0, stats.maxHp),
        innerPower: state.player.innerPower.clamp(0, stats.maxInnerPower),
      ),
    );
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}

class CharacterStats {
  const CharacterStats({
    required this.attack,
    required this.defense,
    required this.maxHp,
    required this.maxInnerPower,
    required this.attackBonus,
    required this.defenseBonus,
    required this.maxHpBonus,
    required this.maxInnerPowerBonus,
  });

  final int attack;
  final int defense;
  final int maxHp;
  final int maxInnerPower;
  final int attackBonus;
  final int defenseBonus;
  final int maxHpBonus;
  final int maxInnerPowerBonus;
}
