import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/game_state.dart';
import '../../game/models/npc_definition.dart';
import '../../game/models/room_definition.dart';
import 'shared/panel.dart';
import 'shop_sheet.dart';

class LocationInfoPanel extends StatelessWidget {
  const LocationInfoPanel({
    super.key,
    required this.areaName,
    required this.room,
    required this.controller,
    required this.state,
  });

  final String areaName;
  final RoomDefinition room;
  final GameController controller;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final npcs =
        controller.repository.visibleNpcsInRoom(state, room.id).toList();
    final items =
        controller.repository.visibleItemsInRoom(state, room.id).toList();
    final exits = room.availableExits(state);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$areaName · ${room.name}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(room.description),
          const SizedBox(height: 12),
          _ChipRow(
            label: '出口',
            emptyText: '无路可走',
            children: [
              for (final exit in exits.entries)
                ActionChip(
                  avatar: const Icon(Icons.directions, size: 18),
                  label: Text(
                    _exitLabel(controller, room, exit.key.label, exit.value),
                  ),
                  onPressed:
                      () => controller.dispatch(GameAction.move(exit.key)),
                ),
            ],
          ),
          const SizedBox(height: 8),
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
              for (final action in room.availableActions(state))
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

  String _exitLabel(
    GameController controller,
    RoomDefinition currentRoom,
    String direction,
    String destinationRoomId,
  ) {
    final destination = controller.repository.room(destinationRoomId);
    if (destination.areaId == currentRoom.areaId) {
      return '$direction · ${destination.name}';
    }
    final destinationArea = controller.repository.area(destination.areaId);
    return '$direction · ${destinationArea.name} · ${destination.name}';
  }

  void _showDialogue(
    BuildContext context,
    GameController controller,
    NpcDefinition npc,
  ) {
    controller.dispatch(GameAction.talk(npc.id));
    final options = controller.dialogueOptionsFor(npc.id);
    final giveItemOptions = controller.giveItemOptionsFor(npc.id);
    final teachingSkills = controller.teachingSkillsFor(npc.id);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                npc.name,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
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
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              if (giveItemOptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('给予', style: Theme.of(sheetContext).textTheme.labelLarge),
                for (final option in giveItemOptions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.redeem_outlined),
                    title: Text(option.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      controller.dispatch(
                        GameAction.giveItem(npc.id, option.itemId),
                      );
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
              if (teachingSkills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('请教', style: Theme.of(sheetContext).textTheme.labelLarge),
                for (final teaching in teachingSkills)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.school_outlined),
                    title: Text(
                      controller.repository.skill(teaching.skillId).name,
                    ),
                    subtitle: Text('可传授至 Lv.${teaching.maxLevel}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      controller.dispatch(
                        GameAction.learnFromNpc(npc.id, teaching.skillId),
                      );
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
              if (npc.combat != null) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    controller.dispatch(GameAction.startCombat(npc.id));
                    Navigator.of(sheetContext).pop();
                  },
                  icon: const Icon(Icons.local_fire_department),
                  label: const Text('迎战'),
                ),
              ],
              if (npc.shop != null) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Future<void>.delayed(Duration.zero, () {
                      if (!context.mounted) {
                        return;
                      }
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder:
                            (_) => ShopSheet(
                              controller: controller,
                              merchant: npc,
                            ),
                      );
                    });
                  },
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('买卖'),
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
