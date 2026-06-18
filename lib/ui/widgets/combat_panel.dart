import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/game_state.dart';
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
                label: const Text('攻击'),
              ),
              OutlinedButton.icon(
                onPressed:
                    () => controller.dispatch(const GameAction.fleeCombat()),
                icon: const Icon(Icons.directions_run, size: 18),
                label: const Text('退避'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
