import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/equipment_slot.dart';

class CharacterSheet extends StatelessWidget {
  const CharacterSheet({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final stats = controller.characterStats();
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('角色', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _Stat(
                      label: '攻击',
                      value: stats.attack,
                      bonus: stats.attackBonus,
                    ),
                    _Stat(
                      label: '防御',
                      value: stats.defense,
                      bonus: stats.defenseBonus,
                    ),
                    _Stat(
                      label: '气血上限',
                      value: stats.maxHp,
                      bonus: stats.maxHpBonus,
                    ),
                    _Stat(
                      label: '内力上限',
                      value: stats.maxInnerPower,
                      bonus: stats.maxInnerPowerBonus,
                    ),
                  ],
                ),
                const Divider(height: 28),
                for (final slot in EquipmentSlot.values)
                  _EquipmentRow(
                    slot: slot,
                    itemId: state.equippedItemIds[slot],
                    controller: controller,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.bonus});

  final String label;
  final int value;
  final int bonus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            bonus > 0 ? '$value  (+$bonus)' : '$value',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _EquipmentRow extends StatelessWidget {
  const _EquipmentRow({
    required this.slot,
    required this.itemId,
    required this.controller,
  });

  final EquipmentSlot slot;
  final String? itemId;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final item = itemId == null ? null : controller.repository.item(itemId!);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_slotIcon(slot)),
      title: Text(slot.label),
      subtitle: Text(item?.name ?? '未装备'),
      trailing:
          item == null
              ? null
              : IconButton(
                tooltip: '卸下${item.name}',
                onPressed:
                    () => controller.dispatch(GameAction.unequipItem(slot)),
                icon: const Icon(Icons.remove_circle_outline),
              ),
    );
  }
}

IconData _slotIcon(EquipmentSlot slot) {
  return switch (slot) {
    EquipmentSlot.weapon => Icons.gavel,
    EquipmentSlot.head => Icons.face,
    EquipmentSlot.body => Icons.checkroom,
    EquipmentSlot.feet => Icons.directions_walk,
    EquipmentSlot.accessory => Icons.auto_awesome,
  };
}
