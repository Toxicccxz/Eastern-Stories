import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/equipment_slot.dart';
import '../../game/models/innate_attributes.dart';

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('角色', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('${state.player.name} · ${state.player.gender.label}'),
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
                    for (final attribute in InnateAttribute.values)
                      _Stat(
                        label: attribute.label,
                        value: state.player.attributes.valueFor(attribute),
                        bonus: 0,
                      ),
                    _Stat(label: '潜能', value: state.player.potential, bonus: 0),
                    _Stat(
                      label: '实战经验',
                      value: state.player.combatExperience,
                      bonus: 0,
                    ),
                  ],
                ),
                const Divider(height: 28),
                _ApprenticeshipSection(controller: controller),
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

class _ApprenticeshipSection extends StatelessWidget {
  const _ApprenticeshipSection({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final apprenticeship = state.apprenticeship;
    if (apprenticeship == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('师承', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            state.player.betrayalCount == 0
                ? '尚未拜入门下'
                : '尚无师承 · 背叛记录 ${state.player.betrayalCount}',
          ),
        ],
      );
    }
    final family = controller.repository.family(apprenticeship.familyId);
    final master = controller.repository.npc(apprenticeship.masterNpcId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('师承', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          '${family.name}第${apprenticeship.generation}代${apprenticeship.title}',
        ),
        Text('师父：${master.name}  ·  贡献：${apprenticeship.contribution}'),
        if (state.player.betrayalCount > 0)
          Text('背叛记录：${state.player.betrayalCount}'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _confirmLeave(context),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('离开师门'),
        ),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('离开师门'),
            content: const Text('离开师门会留下背叛记录，并使现有武学等级减半。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('确认离门'),
              ),
            ],
          ),
    );
    if (shouldLeave == true) {
      controller.dispatch(const GameAction.leaveFamily());
    }
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
