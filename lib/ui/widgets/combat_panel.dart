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
    final activeMoves = controller.activeCombatMoves();
    final npcState = state.npcStates[npc.id];

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
          _StatusEffectRow(label: '自身状态', effects: state.playerStatusEffects),
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
              const SizedBox(width: 10),
              Expanded(
                child: StatusMeter(
                  label: '法力',
                  value: state.player.mana,
                  maxValue: state.player.maxMana,
                  color: const Color(0xFF665C8E),
                ),
              ),
            ],
          ),
          if (combat.ally case final ally?) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('护法：${ally.name}')),
                        Text(
                          ally.lastsForCombat
                              ? '本场战斗'
                              : '${ally.remainingRounds} 回合',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: ally.hp / ally.maxHp,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${ally.hp}/${ally.maxHp}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          StatusMeter(
            label: '敌方气血',
            value: combat.enemyHp,
            maxValue: combatDefinition.maxHp,
            color: const Color(0xFF7B5FA4),
          ),
          if (npcState != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: StatusMeter(
                    label: '敌方精力',
                    value: npcState.currentEnergy,
                    maxValue: combatDefinition.maxEnergy,
                    color: const Color(0xFF3F7D65),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatusMeter(
                    label: '敌方精神',
                    value: npcState.currentSpirit,
                    maxValue: combatDefinition.maxSpirit,
                    color: const Color(0xFF8A6D3B),
                  ),
                ),
                if (combatDefinition.maxMana > 0) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatusMeter(
                      label: '敌方法力',
                      value: npcState.currentMana,
                      maxValue: combatDefinition.maxMana,
                      color: const Color(0xFF665C8E),
                    ),
                  ),
                ],
              ],
            ),
          ],
          _StatusEffectRow(label: '敌方状态', effects: combat.enemyStatusEffects),
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
          if (activeMoves.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('武功招式', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in activeMoves)
                  _MoveButton(
                    option: option,
                    state: state,
                    onPressed:
                        () => controller.dispatch(
                          GameAction.useCombatMove(
                            option.skill.id,
                            option.move.id,
                          ),
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

class _StatusEffectRow extends StatelessWidget {
  const _StatusEffectRow({required this.label, required this.effects});

  final String label;
  final List<StatusEffectState> effects;

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final effect in effects) _StatusEffectChip(effect: effect),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusEffectChip extends StatelessWidget {
  const _StatusEffectChip({required this.effect});

  final StatusEffectState effect;

  @override
  Widget build(BuildContext context) {
    final visual = _StatusEffectVisual.fromEffect(context, effect);
    final details = <String>[
      if (effect.damagePerRound > 0) '每回合气血 -${effect.damagePerRound}',
      if (effect.spiritDamagePerRound > 0)
        '每回合精神 -${effect.spiritDamagePerRound}',
      if (effect.innerPowerDamagePerRound > 0)
        '每回合内力 -${effect.innerPowerDamagePerRound}',
      if (effect.hpRecoveryPerRound > 0) '每回合气血 +${effect.hpRecoveryPerRound}',
      if (effect.attackPenalty > 0) '攻 -${effect.attackPenalty}',
      if (effect.defensePenalty > 0) '防 -${effect.defensePenalty}',
      if (effect.blocksAction) '无法行动',
    ].join(' / ');

    return Tooltip(
      message: details.isEmpty ? effect.name : details,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: visual.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(visual.icon, size: 13, color: visual.foreground),
              const SizedBox(width: 4),
              Text(
                '${effect.name} ${effect.remainingRounds}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: visual.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusEffectVisual {
  const _StatusEffectVisual({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final Color border;

  factory _StatusEffectVisual.fromEffect(
    BuildContext context,
    StatusEffectState effect,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final id = effect.id.toLowerCase();

    if (id.contains('ice')) {
      const color = Color(0xFF2E6F9E);
      return _StatusEffectVisual(
        icon: Icons.ac_unit,
        background: color.withValues(alpha: 0.13),
        foreground: color,
        border: color.withValues(alpha: 0.35),
      );
    }

    if (id.contains('poison')) {
      const color = Color(0xFF8B3A62);
      return _StatusEffectVisual(
        icon: Icons.local_florist,
        background: color.withValues(alpha: 0.13),
        foreground: color,
        border: color.withValues(alpha: 0.35),
      );
    }

    if (effect.blocksAction) {
      const color = Color(0xFF665C8E);
      return _StatusEffectVisual(
        icon: Icons.bedtime_outlined,
        background: color.withValues(alpha: 0.13),
        foreground: color,
        border: color.withValues(alpha: 0.35),
      );
    }

    if (effect.hpRecoveryPerRound > 0) {
      const color = Color(0xFF39724E);
      return _StatusEffectVisual(
        icon: Icons.healing_outlined,
        background: color.withValues(alpha: 0.13),
        foreground: color,
        border: color.withValues(alpha: 0.35),
      );
    }

    if (effect.damagePerRound > 0) {
      const color = Color(0xFFB04535);
      return _StatusEffectVisual(
        icon: Icons.local_fire_department,
        background: color.withValues(alpha: 0.12),
        foreground: color,
        border: color.withValues(alpha: 0.34),
      );
    }

    if (effect.attackPenalty > 0) {
      const color = Color(0xFF9A5B16);
      return _StatusEffectVisual(
        icon: Icons.trending_down,
        background: color.withValues(alpha: 0.12),
        foreground: color,
        border: color.withValues(alpha: 0.34),
      );
    }

    if (effect.defensePenalty > 0) {
      const color = Color(0xFF6E5F20);
      return _StatusEffectVisual(
        icon: Icons.shield_outlined,
        background: color.withValues(alpha: 0.12),
        foreground: color,
        border: color.withValues(alpha: 0.34),
      );
    }

    return _StatusEffectVisual(
      icon: Icons.auto_awesome,
      background: colorScheme.tertiaryContainer,
      foreground: colorScheme.onTertiaryContainer,
      border: colorScheme.tertiary.withValues(alpha: 0.32),
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.option,
    required this.state,
    required this.onPressed,
  });

  final CombatMoveOption option;
  final GameState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final skill = option.skill;
    final move = option.move;
    final requiredSlot =
        move.requiredEquipmentSlot ?? skill.requiredEquipmentSlot;
    final skillLevel = state.skillProgress[skill.id]?.level ?? 1;
    final innerPowerCost = move.innerPowerCostAtLevel(skillLevel);
    final hasEquipment =
        requiredSlot == null || state.equippedItemIds.containsKey(requiredSlot);
    final hasInnerPower = state.player.innerPower >= innerPowerCost;
    final hasMana = state.player.mana >= move.manaCost;
    final hasSpirit = state.player.spirit >= move.spiritCost;
    final hasRequiredLevel = skillLevel >= move.minimumSkillLevel;
    final enabled =
        hasEquipment &&
        hasInnerPower &&
        hasMana &&
        hasSpirit &&
        hasRequiredLevel;
    final reason =
        !hasEquipment
            ? '需要装备兵器'
            : !hasInnerPower
            ? '内力不足'
            : !hasMana
            ? '法力不足'
            : !hasSpirit
            ? '精神不足'
            : !hasRequiredLevel
            ? '需要 Lv.${move.minimumSkillLevel}'
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonalIcon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(_icon, size: 18),
          label: Text(
            '${move.name} Lv.$skillLevel'
            '${_costLabel(innerPowerCost, move.manaCost, move.spiritCost)}',
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
    return switch (option.move.effectType) {
      SkillEffectType.damage => Icons.auto_fix_high,
      SkillEffectType.defend => Icons.shield_outlined,
      SkillEffectType.heal => Icons.favorite_outline,
      SkillEffectType.summon => Icons.person_add_alt_1,
      SkillEffectType.escape => Icons.blur_on,
      SkillEffectType.resourceDamage => Icons.bolt_outlined,
      SkillEffectType.selfStatus => Icons.visibility_outlined,
    };
  }

  String _costLabel(int innerPowerCost, int manaCost, int spiritCost) {
    final costs = [
      if (innerPowerCost > 0) '$innerPowerCost内力',
      if (manaCost > 0) '$manaCost法力',
      if (spiritCost > 0) '$spiritCost精神',
    ];
    return costs.isEmpty ? '' : '  ${costs.join(' / ')}';
  }
}
