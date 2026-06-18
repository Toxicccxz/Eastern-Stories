import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/game_state.dart';
import '../../game/models/npc_definition.dart';
import '../../game/models/room_definition.dart';
import 'shared/panel.dart';

class LocationInfoPanel extends StatelessWidget {
  const LocationInfoPanel({
    super.key,
    required this.room,
    required this.controller,
    required this.state,
  });

  final RoomDefinition room;
  final GameController controller;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final npcs = room.npcIds.map(controller.repository.npc).toList();
    final items =
        room.visibleItemIds(state).map(controller.repository.item).toList();

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${room.areaName} · ${room.name}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(room.description),
          const SizedBox(height: 12),
          _ChipRow(
            label: '人物',
            emptyText: '无人',
            children: [
              for (final npc in npcs)
                ActionChip(
                  label: Text(npc.name),
                  onPressed: () => _showDialogue(context, controller, npc),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _ChipRow(
            label: '物品',
            emptyText: '无',
            children: [
              for (final item in items)
                ActionChip(
                  label: Text(item.name),
                  onPressed:
                      () => controller.dispatch(GameAction.pickUp(item.id)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _ChipRow(
            label: '行动',
            emptyText: '无',
            children: [
              for (final action in room.actions)
                ActionChip(
                  avatar: const Icon(Icons.touch_app, size: 18),
                  label: Text(action.label),
                  onPressed:
                      () => controller.dispatch(
                        GameAction.performRoomAction(action.id),
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDialogue(
    BuildContext context,
    GameController controller,
    NpcDefinition npc,
  ) {
    controller.dispatch(GameAction.talk(npc.id));
    final options = controller.dialogueOptionsFor(npc.id);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(npc.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(npc.description),
              const SizedBox(height: 12),
              if (options.isEmpty)
                const Text('暂时没有更多话可说。')
              else
                for (final option in options)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      controller.dispatch(
                        GameAction.selectDialogue(npc.id, option.id),
                      );
                      Navigator.of(context).pop();
                    },
                  ),
              if (npc.combat != null) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    controller.dispatch(GameAction.startCombat(npc.id));
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.local_fire_department),
                  label: const Text('迎战'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.label,
    required this.emptyText,
    required this.children,
  });

  final String label;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        if (children.isEmpty)
          Text(emptyText, style: Theme.of(context).textTheme.bodySmall)
        else
          Wrap(spacing: 8, runSpacing: 4, children: children),
      ],
    );
  }
}
