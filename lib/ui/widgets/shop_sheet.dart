import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/npc_definition.dart';

class ShopSheet extends StatelessWidget {
  const ShopSheet({
    super.key,
    required this.controller,
    required this.merchant,
  });

  final GameController controller;
  final NpcDefinition merchant;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return DefaultTabController(
          length: 2,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          merchant.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const Icon(Icons.payments_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text('${controller.state.player.silver} 两'),
                    ],
                  ),
                ),
                const TabBar(tabs: [Tab(text: '购买'), Tab(text: '出售')]),
                Expanded(
                  child: TabBarView(
                    children: [
                      _BuyList(controller: controller, merchant: merchant),
                      _SellList(controller: controller, merchant: merchant),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BuyList extends StatelessWidget {
  const _BuyList({required this.controller, required this.merchant});

  final GameController controller;
  final NpcDefinition merchant;

  @override
  Widget build(BuildContext context) {
    final shop = merchant.shop;
    if (shop == null || shop.products.isEmpty) {
      return const Center(child: Text('暂时没有货物。'));
    }

    final shopState = controller.state.shopStates[merchant.id];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: shop.products.length,
      separatorBuilder: (_, _) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final product = shop.products[index];
        final item = controller.repository.item(product.itemId);
        final stock = shopState?.stockByItemId[item.id] ?? 0;
        final canBuy =
            stock != 0 && controller.state.player.silver >= item.buyPrice;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.name),
          subtitle: Text(
            '${item.description}\n${stock < 0 ? '货源充足' : '剩余 $stock'}',
          ),
          isThreeLine: true,
          trailing: FilledButton(
            onPressed:
                canBuy
                    ? () => controller.dispatch(
                      GameAction.buyItem(merchant.id, item.id),
                    )
                    : null,
            child: Text('${item.buyPrice} 两'),
          ),
        );
      },
    );
  }
}

class _SellList extends StatelessWidget {
  const _SellList({required this.controller, required this.merchant});

  final GameController controller;
  final NpcDefinition merchant;

  @override
  Widget build(BuildContext context) {
    final quantities = <String, int>{};
    for (final itemId in controller.state.inventoryItemIds) {
      final item = controller.repository.item(itemId);
      if (item.sellPrice > 0) {
        quantities[itemId] = (quantities[itemId] ?? 0) + 1;
      }
    }
    if (quantities.isEmpty) {
      return const Center(child: Text('背包里没有可以出售的物品。'));
    }

    final entries = quantities.entries.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final item = controller.repository.item(entry.key);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${item.name} ×${entry.value}'),
          subtitle: Text(item.description),
          trailing: FilledButton.tonal(
            onPressed:
                () => controller.dispatch(
                  GameAction.sellItem(merchant.id, item.id),
                ),
            child: Text('${item.sellPrice} 两'),
          ),
        );
      },
    );
  }
}
