import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';

class TradeSystem {
  const TradeSystem(this._repository);

  final GameDefinitionRepository _repository;

  GameState buyItem(GameState state, String npcId, String itemId) {
    if (!_isMerchantPresent(state, npcId)) {
      return _withLog(state, '这里没有这位商人。');
    }

    final npc = _repository.npc(npcId);
    final product = npc.shop?.product(itemId);
    final shopState = state.shopStates[npcId];
    if (product == null || shopState == null) {
      return _withLog(state, '${npc.name}不卖这个东西。');
    }

    final stock = shopState.stockByItemId[itemId] ?? 0;
    if (stock == 0) {
      return _withLog(state, '${_repository.item(itemId).name}已经卖完了。');
    }

    final item = _repository.item(itemId);
    if (item.buyPrice <= 0) {
      return _withLog(state, '${item.name}暂时不能购买。');
    }
    if (state.player.silver < item.buyPrice) {
      return _withLog(state, '银两不足，还差${item.buyPrice - state.player.silver}。');
    }

    return state.copyWith(
      player: state.player.copyWith(
        silver: state.player.silver - item.buyPrice,
      ),
      inventoryItemIds: [...state.inventoryItemIds, itemId],
      shopStates: {
        ...state.shopStates,
        npcId: shopState.copyWith(
          stockByItemId: {
            ...shopState.stockByItemId,
            itemId: stock < 0 ? stock : stock - 1,
          },
        ),
      },
      log: state.logWith('你花费${item.buyPrice}两银子买下了${item.name}。'),
    );
  }

  GameState sellItem(GameState state, String npcId, String itemId) {
    if (!_isMerchantPresent(state, npcId)) {
      return _withLog(state, '这里没有这位商人。');
    }
    if (!state.inventoryItemIds.contains(itemId)) {
      return _withLog(state, '你还没有这个东西。');
    }

    final item = _repository.item(itemId);
    if (item.sellPrice <= 0) {
      return _withLog(state, '${item.name}不能出售。');
    }

    final inventory = [...state.inventoryItemIds]..remove(itemId);
    final shopState = state.shopStates[npcId];
    final stock = shopState?.stockByItemId[itemId];
    final nextShopState =
        shopState == null || stock == null || stock < 0
            ? shopState
            : shopState.copyWith(
              stockByItemId: {...shopState.stockByItemId, itemId: stock + 1},
            );

    return state.copyWith(
      player: state.player.copyWith(
        silver: state.player.silver + item.sellPrice,
      ),
      inventoryItemIds: inventory,
      equippedWeaponId:
          state.equippedWeaponId == itemId ? null : state.equippedWeaponId,
      shopStates:
          nextShopState == null
              ? state.shopStates
              : {...state.shopStates, npcId: nextShopState},
      log: state.logWith('你把${item.name}卖给商人，得到${item.sellPrice}两银子。'),
    );
  }

  bool _isMerchantPresent(GameState state, String npcId) {
    return _repository
        .visibleNpcsInRoom(state, state.currentRoomId)
        .any((npc) => npc.id == npcId && npc.shop != null);
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
