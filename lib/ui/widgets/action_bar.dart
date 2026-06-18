import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/quest_definition.dart';
import '../../game/models/room_definition.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.room, required this.controller});

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
