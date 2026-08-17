import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';

class NpcEquipmentSystem {
  const NpcEquipmentSystem(this._repository);

  final GameDefinitionRepository _repository;

  NpcCombatStats statsFor(GameState state, String npcId) {
    final npc = _repository.npcInstance(state, npcId);
    final combat = npc.combat;
    if (combat == null) {
      return const NpcCombatStats(attack: 0, defense: 0);
    }
    if (!combat.usesEquipmentStats) {
      return NpcCombatStats(attack: combat.attack, defense: combat.defense);
    }

    var attackBonus = 0;
    var defenseBonus = 0;
    final equipment = state.npcStates[npcId]?.equippedItemIds.values;
    for (final itemId in equipment ?? const <String>[]) {
      final item = _repository.item(itemId);
      attackBonus += item.attackPower;
      defenseBonus += item.defensePower;
    }
    return NpcCombatStats(
      attack: (combat.attack + attackBonus).clamp(0, 9999),
      defense: (combat.defense + defenseBonus).clamp(0, 9999),
    );
  }
}

class NpcCombatStats {
  const NpcCombatStats({required this.attack, required this.defense});

  final int attack;
  final int defense;
}
