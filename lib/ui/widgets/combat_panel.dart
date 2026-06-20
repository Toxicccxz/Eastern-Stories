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
          Row(
            children: [
              Expanded(
                child: Text(
                  '战斗',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '第 ${combat.round + 1} 回合',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            npc.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatusMeter(
                  label: '气血',
                  value: state.player.hp,
                  maxValue: controller.characterStats().maxHp,
                  color: const Color(0xFFB64B3C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatusMeter(
                  label: '内力',
                  value: state.player.innerPower,
                  maxValue: controller.characterStats().maxInnerPower,
                  color: const Color(0xFF3E6E8F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatusMeter(
            label: '敌方气血',
            value: combat.enemyHp,
            maxValue: combatDefinition.maxHp,
            color: const Color(0xFF7B5FA4),
          ),
          if (combatDefinition.specialMove case final specialMove?) ...[
            const SizedBox(height: 8),
            Text(
              '${specialMove.name}：每 ${specialMove.interval} 回合发动',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
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
    final skillLevel = state.skillProgress[skill.id]?.level ?? 1;
    final innerPowerCost = skill.innerPowerCostAtLevel(skillLevel);
    final hasEquipment =
        requiredSlot == null || state.equippedItemIds.containsKey(requiredSlot);
    final hasInnerPower = state.player.innerPower >= innerPowerCost;
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
          icon: Icon(_icon, size: 18),
          label: Text(
            '${skill.moveName ?? skill.name} Lv.$skillLevel'
            '${_costLabel(innerPowerCost)}',
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

  IconData get _icon {
    return switch (skill.effectType) {
      SkillEffectType.damage => Icons.auto_fix_high,
      SkillEffectType.defend => Icons.shield_outlined,
      SkillEffectType.heal => Icons.favorite_outline,
    };
  }

  String _costLabel(int innerPowerCost) {
    return innerPowerCost == 0 ? '' : '  $innerPowerCost内力';
  }
}
