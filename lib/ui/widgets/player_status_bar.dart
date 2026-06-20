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
              Text('银两 ${player.silver}'),
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
          StatusMeter(
            label: '经验',
            value: player.experience,
            maxValue: player.nextLevelExperience,
            color: const Color(0xFF6F7F3F),
          ),
        ],
      ),
    );
  }
}
