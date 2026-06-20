import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/game_state.dart';
import '../../game/models/skill_definition.dart';
import 'shared/panel.dart';
import 'shared/status_meter.dart';

class CombatPanel extends StatelessWidget {
  const CombatPanel({super.key, required this.controller, required this.state});

  final GameController controller;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final combat = state.combat;
    if (combat == null) {
      return const SizedBox.shrink();
    }

    final npc = controller.repository.npc(combat.npcId);
    final combatDefinition = npc.combat;
    if (combatDefinition == null) {
      return const SizedBox.shrink();
    }
    final activeSkills = controller.activeCombatSkills();

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('战斗', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(
            npc.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          StatusMeter(
            label: '敌方气血',
            value: combat.enemyHp,
            maxValue: combatDefinition.maxHp,
            color: const Color(0xFF7B5FA4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => controller.dispatch(const GameAction.attack()),
                icon: const Icon(Icons.flash_on, size: 18),
                label: const Text('普通攻击'),
              ),
              OutlinedButton.icon(
                onPressed:
                    () => controller.dispatch(const GameAction.fleeCombat()),
                icon: const Icon(Icons.directions_run, size: 18),
                label: const Text('退避'),
              ),
            ],
          ),
          if (activeSkills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('武功招式', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in activeSkills)
                  _SkillButton(
                    skill: skill,
                    state: state,
                    onPressed:
                        () => controller.dispatch(
                          GameAction.useCombatSkill(skill.id),
                        ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SkillButton extends StatelessWidget {
  const _SkillButton({
    required this.skill,
    required this.state,
    required this.onPressed,
  });

  final SkillDefinition skill;
  final GameState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final requiredSlot = skill.requiredEquipmentSlot;
    final hasEquipment =
        requiredSlot == null || state.equippedItemIds.containsKey(requiredSlot);
    final hasInnerPower = state.player.innerPower >= skill.innerPowerCost;
    final enabled = hasEquipment && hasInnerPower;
    final reason =
        !hasEquipment
            ? '需要装备兵器'
            : !hasInnerPower
            ? '内力不足'
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonalIcon(
          onPressed: enabled ? onPressed : null,
          icon: const Icon(Icons.auto_fix_high, size: 18),
          label: Text(
            '${skill.moveName ?? skill.name}  ${skill.innerPowerCost}内力',
          ),
        ),
        if (reason != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              reason,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
