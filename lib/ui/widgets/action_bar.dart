import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/room_definition.dart';
import '../../game/models/equipment_slot.dart';
import '../../game/models/skill_progress.dart';
import '../../game/models/skill_definition.dart';
import 'character_sheet.dart';
import 'objective_tracker_panel.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.room, required this.controller});

  final RoomDefinition room;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      for (final entry in room.availableExits(controller.state).entries)
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
        label: '角色',
        icon: Icons.person_outline,
        onPressed: () => _showCharacter(context, controller),
      ),
      _ActionButton(
        label: '背包',
        icon: Icons.inventory_2_outlined,
        onPressed: () => _showInventory(context, controller),
      ),
      _ActionButton(
        label: '目标',
        icon: Icons.assignment_outlined,
        onPressed: () => showObjectiveTrackerSheet(context, controller),
      ),
      _ActionButton(
        label: '武学',
        icon: Icons.menu_book_outlined,
        onPressed: () => _showSkills(context, controller),
      ),
      if (room.allowsCultivation &&
          controller.state.enabledSkillIds.containsKey(SkillUsage.force))
        _ActionButton(
          label: '运功',
          icon: Icons.self_improvement,
          onPressed: () => _showInnerPower(context, controller),
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
        final equippedItemIds = controller.state.equippedItemIds;
        final skillProgress = controller.state.skillProgress;

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
                      equippedItemIds: equippedItemIds,
                      skillProgress: skillProgress,
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  void _showCharacter(BuildContext context, GameController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CharacterSheet(controller: controller),
    );
  }

  void _showSkills(BuildContext context, GameController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SkillsSheet(controller: controller),
    );
  }

  void _showInnerPower(BuildContext context, GameController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _InnerPowerSheet(controller: controller),
    );
  }
}

class _InnerPowerSheet extends StatelessWidget {
  const _InnerPowerSheet({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final player = state.player;
        final forceSkillId = state.enabledSkillIds[SkillUsage.force];
        final forceSkill =
            forceSkillId == null
                ? null
                : controller.repository.skill(forceSkillId);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('运功', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('当前心法：${forceSkill?.name ?? '未启用'}'),
                Text(
                  '内力 ${player.innerPower}/${player.maxInnerPower}  ·  '
                  '修炼上限 ${controller.innerPowerCultivationLimit()}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed:
                          () =>
                              controller.dispatch(const GameAction.meditate()),
                      icon: const Icon(Icons.self_improvement),
                      label: const Text('打坐练功'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          () => controller.dispatch(
                            const GameAction.recoverWithInnerPower(),
                          ),
                      icon: const Icon(Icons.air),
                      label: const Text('调息'),
                    ),
                    if (forceSkillId == 'fonxan_force')
                      OutlinedButton.icon(
                        onPressed:
                            () => controller.dispatch(
                              const GameAction.healWithInnerPower(),
                            ),
                        icon: const Icon(Icons.healing_outlined),
                        label: const Text('运功疗伤'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.log.last,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkillsSheet extends StatelessWidget {
  const _SkillsSheet({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final skills = controller.learnedSkills();
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                    _SkillTile(skill: skill, controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.skill, required this.controller});

  final SkillDefinition skill;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.state.skillProgress[skill.id]!;
    final isMaxLevel = progress.level >= skill.maxLevel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${skill.name}  Lv.${progress.level}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(skill.isBasic ? '基本功' : '特殊武功'),
            ],
          ),
          const SizedBox(height: 4),
          Text(skill.description),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value:
                isMaxLevel
                    ? 1
                    : progress.experience / progress.experienceForNextLevel,
          ),
          const SizedBox(height: 3),
          Text(
            isMaxLevel
                ? '已臻上限'
                : '熟练度 ${progress.experience}/${progress.experienceForNextLevel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!skill.isBasic) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final usage in skill.usages)
                  _SkillUsageButton(
                    skill: skill,
                    usage: usage,
                    controller: controller,
                  ),
              ],
            ),
          ],
          if (skill.moves.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '招式：${skill.moves.map((move) => move.name).join('、')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _SkillUsageButton extends StatelessWidget {
  const _SkillUsageButton({
    required this.skill,
    required this.usage,
    required this.controller,
  });

  final SkillDefinition skill;
  final SkillUsage usage;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final isEnabled = controller.state.enabledSkillIds[usage] == skill.id;
    return isEnabled
        ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed:
                  () => controller.dispatch(GameAction.disableSkill(usage)),
              icon: const Icon(Icons.check, size: 18),
              label: Text('停用${usage.label}'),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed:
                  () => controller.dispatch(GameAction.practiceSkill(usage)),
              icon: const Icon(Icons.fitness_center, size: 18),
              label: const Text('练习'),
            ),
          ],
        )
        : FilledButton.tonal(
          onPressed:
              () =>
                  controller.dispatch(GameAction.enableSkill(skill.id, usage)),
          child: Text('用于${usage.label}'),
        );
  }
}

class _InventoryAction extends StatelessWidget {
  const _InventoryAction({
    required this.itemId,
    required this.controller,
    required this.equippedItemIds,
    required this.skillProgress,
  });

  final String itemId;
  final GameController controller;
  final Map<EquipmentSlot, String> equippedItemIds;
  final Map<String, SkillProgress> skillProgress;

  @override
  Widget build(BuildContext context) {
    final item = controller.repository.item(itemId);
    Widget? primaryAction;
    if (item.canEquip) {
      final isEquipped = equippedItemIds[item.equipmentSlot] == itemId;
      primaryAction = FilledButton(
        onPressed:
            isEquipped
                ? null
                : () {
                  controller.dispatch(GameAction.equipItem(itemId));
                  Navigator.of(context).pop();
                },
        child: Text(isEquipped ? '已装备' : '装备'),
      );
    } else if (item.studySkillId case final skillId?) {
      final progress = skillProgress[skillId];
      final skill = controller.repository.skill(skillId);
      final studyLimit =
          item.studyMaxSkillLevel < skill.maxLevel
              ? item.studyMaxSkillLevel
              : skill.maxLevel;
      final hasMasteredBook = progress != null && progress.level >= studyLimit;
      primaryAction = FilledButton(
        onPressed:
            hasMasteredBook
                ? null
                : () {
                  controller.dispatch(GameAction.studyItem(itemId));
                  Navigator.of(context).pop();
                },
        child: Text(
          hasMasteredBook
              ? '已参透'
              : progress == null
              ? '研读'
              : '研习',
        ),
      );
    } else if (item.canUse) {
      primaryAction = FilledButton(
        onPressed: () {
          controller.dispatch(GameAction.useItem(itemId));
          Navigator.of(context).pop();
        },
        child: const Text('使用'),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (primaryAction != null) primaryAction,
        PopupMenuButton<_InventoryMenuAction>(
          tooltip: '更多操作',
          icon: const Icon(Icons.more_vert),
          itemBuilder:
              (context) => const [
                PopupMenuItem(
                  value: _InventoryMenuAction.drop,
                  child: Text('丢弃'),
                ),
              ],
          onSelected: (_) {
            controller.dispatch(GameAction.dropItem(itemId));
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

enum _InventoryMenuAction { drop }

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
