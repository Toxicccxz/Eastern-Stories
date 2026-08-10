import 'package:flutter/material.dart';

import '../../game/models/game_state.dart';
import '../../game/systems/equipment_system.dart';
import 'shared/status_meter.dart';

class PlayerStatusBar extends StatelessWidget {
  const PlayerStatusBar({
    super.key,
    required this.state,
    required this.stats,
    this.onSave,
  });

  final GameState state;
  final CharacterStats stats;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final player = state.player;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(bottom: BorderSide(color: Color(0xFFE0D8C8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${player.name}  Lv.${player.level}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text('潜能 ${player.potential}  银两 ${player.silver}'),
              if (onSave != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '保存',
                  onPressed: onSave,
                  icon: const Icon(Icons.save_outlined),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatusMeter(
                  label: '气血',
                  value: player.hp,
                  maxValue: stats.maxHp,
                  color: const Color(0xFFB64B3C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatusMeter(
                  label: '内力',
                  value: player.innerPower,
                  maxValue: stats.maxInnerPower,
                  color: const Color(0xFF3E6E8F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatusMeter(
                  label: '精神',
                  value: player.spirit,
                  maxValue: player.maxSpirit,
                  color: const Color(0xFF8A6D3B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatusMeter(
                  label: '法力',
                  value: player.mana,
                  maxValue: player.maxMana,
                  color: const Color(0xFF665C8E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatusMeter(
                  label: '精力',
                  value: player.energy,
                  maxValue: player.maxEnergy,
                  color: const Color(0xFF3F7D65),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatusMeter(
                  label: '灵力',
                  value: player.atman,
                  maxValue: player.maxAtman,
                  color: const Color(0xFF8A4E72),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StatusMeter(
            label: '经验',
            value: player.experience,
            maxValue: player.nextLevelExperience,
            color: const Color(0xFF6F7F3F),
          ),
          if (state.playerStatusEffects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final effect in state.playerStatusEffects)
                  _ConditionChip(effect: effect),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({required this.effect});

  final StatusEffectState effect;

  @override
  Widget build(BuildContext context) {
    final isRecovery = effect.hpRecoveryPerRound > 0;
    final color =
        isRecovery
            ? const Color(0xFF39724E)
            : Theme.of(context).colorScheme.error;
    final icon =
        effect.blocksAction
            ? Icons.bedtime_outlined
            : isRecovery
            ? Icons.healing_outlined
            : Icons.warning_amber_rounded;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              '${effect.name} ${effect.remainingRounds}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
