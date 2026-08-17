import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';
import 'equipment_system.dart';

class NpcInventorySystem {
  const NpcInventorySystem(this._repository, this._equipmentSystem);

  final GameDefinitionRepository _repository;
  final EquipmentSystem _equipmentSystem;

  GameState giveItem(GameState state, String npcId, String itemId) {
    if (state.combat != null) {
      return _withLog(state, '战斗中无法从容交付物品。');
    }
    final npcState = state.npcStates[npcId];
    if (npcState == null ||
        npcState.roomId != state.currentRoomId ||
        npcState.isDefeated ||
        npcState.isRemoved) {
      return _withLog(state, '这里没有这个人。');
    }
    if (!state.inventory.contains(itemId)) {
      return _withLog(state, '你身上没有这个东西。');
    }

    final isEquipped = state.equippedItemIds.values.contains(itemId);
    final shouldUnequip = isEquipped && state.inventory.countOf(itemId) == 1;
    final unequippedState =
        shouldUnequip
            ? _equipmentSystem.removeItemFromEquipment(state, itemId)
            : state;
    final itemCounts = {...npcState.itemCounts};
    itemCounts[itemId] = (itemCounts[itemId] ?? 0) + 1;
    final item = _repository.item(itemId);
    final npc = _repository.npcInstance(state, npcId);
    return unequippedState.copyWith(
      inventory: unequippedState.inventory.remove(itemId),
      npcStates: {
        ...unequippedState.npcStates,
        npcId: npcState.copyWith(
          itemCounts: itemCounts,
          inventoryInitialized: true,
        ),
      },
      log: unequippedState.logWith('你把${item.name}交给了${npc.name}。'),
    );
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
