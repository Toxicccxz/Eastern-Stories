import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/game_state.dart';
import '../../game/models/npc_definition.dart';
import '../../game/models/quest_definition.dart';
import '../../game/models/room_definition.dart';

class MainGameScreen extends StatelessWidget {
  const MainGameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final room = controller.repository.room(state.currentRoomId);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _PlayerStatusBar(state: state),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    children: [
                      _AreaMapView(
                        rooms: controller.repository.rooms.toList(),
                        state: state,
                      ),
                      const SizedBox(height: 12),
                      _LocationInfoPanel(
                        room: room,
                        controller: controller,
                        state: state,
                      ),
                      const SizedBox(height: 12),
                      if (state.combat != null) ...[
                        _CombatPanel(controller: controller, state: state),
                        const SizedBox(height: 12),
                      ],
                      _EventLogPanel(messages: state.log),
                    ],
                  ),
                ),
                _ActionBar(room: room, controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayerStatusBar extends StatelessWidget {
  const _PlayerStatusBar({required this.state});

  final GameState state;

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
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatusMeter(
                  label: '气血',
                  value: player.hp,
                  maxValue: player.maxHp,
                  color: const Color(0xFFB64B3C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusMeter(
                  label: '内力',
                  value: player.innerPower,
                  maxValue: player.maxInnerPower,
                  color: const Color(0xFF3E6E8F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StatusMeter(
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

class _StatusMeter extends StatelessWidget {
  const _StatusMeter({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label $value/$maxValue',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value / maxValue,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _AreaMapView extends StatelessWidget {
  const _AreaMapView({required this.rooms, required this.state});

  final List<RoomDefinition> rooms;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final columns =
        rooms.map((room) => room.mapX).reduce((a, b) => a > b ? a : b) + 1;
    final rows =
        rooms.map((room) => room.mapY).reduce((a, b) => a > b ? a : b) + 1;
    final roomByPoint = {
      for (final room in rooms) '${room.mapX},${room.mapY}': room,
    };

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('小村', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.8,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: columns * rows,
              itemBuilder: (context, index) {
                final x = index % columns;
                final y = index ~/ columns;
                final room = roomByPoint['$x,$y'];
                final isCurrent = room?.id == state.currentRoomId;
                final isVisited =
                    room != null && state.visitedRoomIds.contains(room.id);

                return _MapCell(
                  label: room?.name ?? '',
                  isCurrent: isCurrent,
                  isVisited: isVisited,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCell extends StatelessWidget {
  const _MapCell({
    required this.label,
    required this.isCurrent,
    required this.isVisited,
  });

  final String label;
  final bool isCurrent;
  final bool isVisited;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background =
        isCurrent
            ? colorScheme.primary
            : isVisited
            ? const Color(0xFFE7DECB)
            : const Color(0xFFF0ECE2);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4C8B5)),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrent ? colorScheme.onPrimary : const Color(0xFF433D33),
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _LocationInfoPanel extends StatelessWidget {
  const _LocationInfoPanel({
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

    return _Panel(
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

class _CombatPanel extends StatelessWidget {
  const _CombatPanel({required this.controller, required this.state});

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

    return _Panel(
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
          _StatusMeter(
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

class _EventLogPanel extends StatelessWidget {
  const _EventLogPanel({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final recentMessages = messages.reversed.take(5).toList().reversed;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('江湖回响', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final message in recentMessages)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('· $message'),
            ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.room, required this.controller});

  final RoomDefinition room;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      for (final entry in room.exits.entries)
        _ActionButton(
          label: entry.key.label,
          icon: Icons.navigation,
          onPressed: () => controller.dispatch(GameAction.move(entry.key)),
        ),
      _ActionButton(
        label: '查看',
        icon: Icons.search,
        onPressed: () => controller.dispatch(const GameAction.look()),
      ),
      _ActionButton(
        label: '背包',
        icon: Icons.inventory_2_outlined,
        onPressed: () => _showInventory(context, controller),
      ),
      _ActionButton(
        label: '委托',
        icon: Icons.assignment_outlined,
        onPressed: () => _showQuests(context, controller),
      ),
      _ActionButton(
        label: '武学',
        icon: Icons.menu_book_outlined,
        onPressed: () => _showSkills(context, controller),
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF6),
        border: Border(top: BorderSide(color: Color(0xFFE0D8C8))),
      ),
      child: SafeArea(
        top: false,
        child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
      ),
    );
  }

  void _showInventory(BuildContext context, GameController controller) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final itemIds = controller.state.inventoryItemIds;
        final equippedWeaponId = controller.state.equippedWeaponId;
        final learnedSkillIds = controller.state.learnedSkillIds;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('背包', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (itemIds.isEmpty)
                const Text('背包里还没有东西。')
              else
                for (final itemId in itemIds)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(controller.repository.item(itemId).name),
                    subtitle: Text(
                      controller.repository.item(itemId).description,
                    ),
                    trailing: _InventoryAction(
                      itemId: itemId,
                      controller: controller,
                      equippedWeaponId: equippedWeaponId,
                      learnedSkillIds: learnedSkillIds,
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  void _showQuests(BuildContext context, GameController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final quests = controller.questViews();
        final visibleQuests =
            quests
                .where((quest) => quest.status != QuestStatus.notStarted)
                .toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('委托', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (visibleQuests.isEmpty)
                const Text('还没有接到委托。')
              else
                for (final quest in visibleQuests) _QuestTile(quest: quest),
            ],
          ),
        );
      },
    );
  }

  void _showSkills(BuildContext context, GameController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final skills = controller.learnedSkills();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('武学', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (skills.isEmpty)
                const Text('还没有领会武学。')
              else
                for (final skill in skills)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(skill.name),
                    subtitle: Text(skill.description),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({required this.quest});

  final QuestView quest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quest.definition.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(_statusText, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final step in quest.steps) _QuestStepRow(step: step),
        ],
      ),
    );
  }

  String get _statusText {
    return switch (quest.status) {
      QuestStatus.completed => '已完成',
      QuestStatus.active when quest.isReadyToComplete => '可回报',
      QuestStatus.active => '进行中',
      QuestStatus.notStarted => '未接取',
    };
  }
}

class _QuestStepRow extends StatelessWidget {
  const _QuestStepRow({required this.step});

  final QuestStepView step;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (step.status) {
      QuestStepStatus.completed => (Icons.check_circle, colorScheme.primary),
      QuestStepStatus.current => (
        Icons.radio_button_checked,
        colorScheme.tertiary,
      ),
      QuestStepStatus.pending => (
        Icons.radio_button_unchecked,
        colorScheme.outline,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(step.description)),
        ],
      ),
    );
  }
}

class _InventoryAction extends StatelessWidget {
  const _InventoryAction({
    required this.itemId,
    required this.controller,
    required this.equippedWeaponId,
    required this.learnedSkillIds,
  });

  final String itemId;
  final GameController controller;
  final String? equippedWeaponId;
  final Set<String> learnedSkillIds;

  @override
  Widget build(BuildContext context) {
    final item = controller.repository.item(itemId);
    if (item.canEquip) {
      return FilledButton(
        onPressed:
            equippedWeaponId == itemId
                ? null
                : () {
                  controller.dispatch(GameAction.equipItem(itemId));
                  Navigator.of(context).pop();
                },
        child: Text(equippedWeaponId == itemId ? '已装备' : '装备'),
      );
    }

    final skillId = item.studySkillId;
    if (skillId != null) {
      return FilledButton(
        onPressed:
            learnedSkillIds.contains(skillId)
                ? null
                : () {
                  controller.dispatch(GameAction.studyItem(itemId));
                  Navigator.of(context).pop();
                },
        child: Text(learnedSkillIds.contains(skillId) ? '已领会' : '研读'),
      );
    }

    if (item.canUse) {
      return FilledButton(
        onPressed: () {
          controller.dispatch(GameAction.useItem(itemId));
          Navigator.of(context).pop();
        },
        child: const Text('使用'),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0D8C8)),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}
