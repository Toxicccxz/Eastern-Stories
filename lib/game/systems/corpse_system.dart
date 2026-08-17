import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';

class CorpseSystem {
  const CorpseSystem(this._repository);

  final GameDefinitionRepository _repository;

  GameState takeItem(GameState state, String corpseId, String itemId) {
    if (state.combat != null) {
      return _withLog(state, '战斗中无暇翻找尸体。');
    }
    final corpse = state.corpses[corpseId];
    if (corpse == null || corpse.roomId != state.currentRoomId) {
      return _withLog(state, '这里没有这具尸体。');
    }
    final quantity = corpse.itemCounts[itemId] ?? 0;
    if (quantity <= 0) {
      return _withLog(state, '尸体上没有这个东西。');
    }

    final itemCounts = {...corpse.itemCounts};
    if (quantity == 1) {
      itemCounts.remove(itemId);
    } else {
      itemCounts[itemId] = quantity - 1;
    }
    final item = _repository.item(itemId);
    return state.copyWith(
      corpses: {
        ...state.corpses,
        corpseId: corpse.copyWith(itemCounts: itemCounts),
      },
      inventory: state.inventory.add(itemId),
      log: state.logWith(
        '你从${corpse.nameAt(state.worldTurn)}上取下了${item.name}。',
      ),
    );
  }

  GameState dissolve(GameState state, String corpseId, String itemId) {
    if (state.combat != null) {
      return _withLog(state, '战斗中无暇处理尸体。');
    }
    final corpse = state.corpses[corpseId];
    if (corpse == null || corpse.roomId != state.currentRoomId) {
      return _withLog(state, '这里没有这具尸体。');
    }
    if (!state.inventory.contains(itemId)) {
      return _withLog(state, '你身上没有化尸之物。');
    }
    final item = _repository.item(itemId);
    if (!item.dissolvesCorpse) {
      return _withLog(state, '${item.name}不能用来处理尸体。');
    }

    final corpses = {...state.corpses}..remove(corpseId);
    return state.copyWith(
      corpses: corpses,
      inventory: state.inventory.remove(itemId),
      log: state.logWith(
        '你在${corpse.nameAt(state.worldTurn)}上撒了一点${item.name}，'
        '嗤嗤声中只剩下一滩黄水。',
      ),
    );
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
