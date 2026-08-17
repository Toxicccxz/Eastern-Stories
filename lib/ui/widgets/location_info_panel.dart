import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/game_state.dart';
import '../../game/models/family_definition.dart';
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
    final corpses =
        state.corpses.values
            .where((corpse) => corpse.roomId == room.id)
            .toList();
    final exits = room.availableExits(state);
    final contextualExits =
        exits.entries.where((entry) => !entry.key.isPrimaryMovement).toList();

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
            label: '去处',
            emptyText: '无特殊去处',
            children: [
              for (final exit in contextualExits)
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
            label: '遗留',
            emptyText: '无',
            children: [
              for (final corpse in corpses)
                ActionChip(
                  avatar: const Icon(Icons.person_off_outlined, size: 18),
                  label: Text(corpse.nameAt(state.worldTurn)),
                  onPressed: () => _showCorpse(context, controller, corpse.id),
                ),
            ],
          ),
          if (state.undeadCompanion case final companion?) ...[
            const SizedBox(height: 8),
            _ChipRow(
              label: '随行',
              emptyText: '无',
              children: [
                Chip(
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: Text(
                    '${companion.name}  ${companion.hp}/${companion.maxHp}',
                  ),
                ),
              ],
            ),
          ],
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

  void _showCorpse(
    BuildContext context,
    GameController controller,
    String corpseId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CorpseSheet(controller: controller, corpseId: corpseId),
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
    final familyTasks = controller.familyTasksFor(npc.id);
    final activeFamilyTask = controller.activeFamilyTask();
    final activeTaskProgress = controller.state.apprenticeship?.activeTask;
    final nextFamilyRank = controller.nextFamilyRankFor(npc.id);
    final npcEquipment =
        controller.state.npcStates[npc.id]?.equippedItemIds.values ??
        const <String>[];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                if (npcEquipment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '穿戴',
                    style: Theme.of(sheetContext).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final itemId in npcEquipment)
                        Chip(
                          avatar: const Icon(
                            Icons.checkroom_outlined,
                            size: 18,
                          ),
                          label: Text(controller.repository.item(itemId).name),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (options.isEmpty)
                  const Text('暂时没有更多话可说。')
                else
                  for (final option in options)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(option.label),
                      subtitle:
                          option.silverCost > 0
                              ? Text('花费 ${option.silverCost} 两银子')
                              : null,
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
                  Text(
                    '给予',
                    style: Theme.of(sheetContext).textTheme.labelLarge,
                  ),
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
                if (!controller.state.inventory.isEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
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
                              (_) => _NpcGiveSheet(
                                controller: controller,
                                npc: npc,
                              ),
                        );
                      });
                    },
                    icon: const Icon(Icons.redeem_outlined),
                    label: const Text('给予物品'),
                  ),
                ],
                if (teachingSkills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '请教',
                    style: Theme.of(sheetContext).textTheme.labelLarge,
                  ),
                  for (final teaching in teachingSkills)
                    _TeachingTile(
                      controller: controller,
                      npc: npc,
                      teaching: teaching,
                      onTap: () {
                        controller.dispatch(
                          GameAction.learnFromNpc(npc.id, teaching.skillId),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
                if (npc.canAcceptApprentices) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      controller.dispatch(GameAction.apprenticeTo(npc.id));
                      Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: Text(
                      controller.state.apprenticeship?.masterNpcId == npc.id
                          ? '向师父请安'
                          : '拜师',
                    ),
                  ),
                ],
                if (activeFamilyTask?.issuerNpcId == npc.id) ...[
                  const SizedBox(height: 12),
                  Text(
                    '师门差事',
                    style: Theme.of(sheetContext).textTheme.labelLarge,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(activeFamilyTask!.title),
                    subtitle: Text(
                      activeTaskProgress?.isObjectiveComplete ?? false
                          ? '差事已经办妥，可以复命。'
                          : activeFamilyTask.description,
                    ),
                    trailing:
                        activeTaskProgress?.isObjectiveComplete ?? false
                            ? const Icon(Icons.chevron_right)
                            : null,
                    onTap:
                        activeTaskProgress?.isObjectiveComplete ?? false
                            ? () {
                              controller.dispatch(
                                GameAction.turnInFamilyTask(npc.id),
                              );
                              Navigator.of(sheetContext).pop();
                            }
                            : null,
                  ),
                ] else if (familyTasks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '师门差事',
                    style: Theme.of(sheetContext).textTheme.labelLarge,
                  ),
                  for (final task in familyTasks)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.assignment_add),
                      title: Text(task.title),
                      subtitle: Text(task.description),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        controller.dispatch(
                          GameAction.acceptFamilyTask(npc.id, task.id),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
                if (nextFamilyRank != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.dispatch(
                        GameAction.requestFamilyPromotion(npc.id),
                      );
                      Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.military_tech_outlined),
                    label: Text('申请晋为${nextFamilyRank.title}'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _rankRequirements(controller, nextFamilyRank),
                    style: Theme.of(sheetContext).textTheme.bodySmall,
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
          ),
        );
      },
    );
  }

  String _rankRequirements(
    GameController controller,
    FamilyRankDefinition rank,
  ) {
    final requirements = <String>[
      '贡献 ${rank.minimumContribution}',
      '师门差事 ${rank.minimumCompletedTasks} 次',
      for (final skill in rank.requiredSkillLevels.entries)
        '${controller.repository.skill(skill.key).name} Lv.${skill.value}',
    ];
    return '晋升条件：${requirements.join(' · ')}';
  }
}

class _CorpseSheet extends StatelessWidget {
  const _CorpseSheet({required this.controller, required this.corpseId});

  final GameController controller;
  final String corpseId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final corpse = state.corpses[corpseId];
        if (corpse == null) {
          return const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text('这里已经没有这具尸体了。'),
            ),
          );
        }
        final corpseMove = controller.activeCorpseMove();
        final canAnimate =
            corpseMove != null &&
            corpse.canAnimateAt(state.worldTurn) &&
            state.undeadCompanion == null;
        final corpseDissolverItemId = _findCorpseDissolverItemId(controller);

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  corpse.nameAt(state.worldTurn),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(corpse.descriptionAt(state.worldTurn)),
                const SizedBox(height: 16),
                Text('随身物品', style: Theme.of(context).textTheme.labelLarge),
                if (corpse.itemCounts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('没有留下可取走的东西。'),
                  )
                else
                  for (final entry in corpse.itemCounts.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(controller.repository.item(entry.key).name),
                      subtitle:
                          entry.value > 1 ? Text('数量：${entry.value}') : null,
                      trailing: IconButton(
                        tooltip: '取走',
                        icon: const Icon(Icons.download_outlined),
                        onPressed:
                            () => controller.dispatch(
                              GameAction.takeCorpseItem(corpse.id, entry.key),
                            ),
                      ),
                    ),
                if (corpseMove != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed:
                        canAnimate
                            ? () {
                              controller.dispatch(
                                GameAction.animateCorpse(
                                  corpseMove.skill.id,
                                  corpseMove.move.id,
                                  corpse.id,
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                            : null,
                    icon: const Icon(Icons.person_off_outlined),
                    label: Text(
                      !corpse.canAnimateAt(state.worldTurn)
                          ? '骸骨无法驱动'
                          : state.undeadCompanion != null
                          ? '已有僵尸随行'
                          : corpseMove.move.name,
                    ),
                  ),
                ],
                if (corpseDissolverItemId != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.dispatch(
                        GameAction.dissolveCorpse(
                          corpse.id,
                          corpseDissolverItemId,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.science_outlined),
                    label: Text(
                      '使用${controller.repository.item(corpseDissolverItemId).name}',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

String? _findCorpseDissolverItemId(GameController controller) {
  for (final entry in controller.state.inventory.entries) {
    if (controller.repository.item(entry.key).dissolvesCorpse) {
      return entry.key;
    }
  }
  return null;
}

class _NpcGiveSheet extends StatelessWidget {
  const _NpcGiveSheet({required this.controller, required this.npc});

  final GameController controller;
  final NpcDefinition npc;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final entries = controller.state.inventory.entries.toList();
        final contextualOptions = controller.giveItemOptionsFor(npc.id);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '给予${npc.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  const Text('身上已经没有可给予的物品。')
                else
                  for (final entry in entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(controller.repository.item(entry.key).name),
                      subtitle:
                          entry.value > 1 ? Text('数量：${entry.value}') : null,
                      trailing: IconButton(
                        tooltip: '给予',
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          GiveItemOption? contextualOption;
                          for (final option in contextualOptions) {
                            if (option.itemId == entry.key) {
                              contextualOption = option;
                              break;
                            }
                          }
                          if (contextualOption != null) {
                            controller.dispatch(
                              GameAction.giveItem(npc.id, entry.key),
                            );
                            Navigator.of(context).pop();
                          } else {
                            controller.dispatch(
                              GameAction.giveInventoryItem(npc.id, entry.key),
                            );
                          }
                        },
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TeachingTile extends StatelessWidget {
  const _TeachingTile({
    required this.controller,
    required this.npc,
    required this.teaching,
    required this.onTap,
  });

  final GameController controller;
  final NpcDefinition npc;
  final TeachingSkillDefinition teaching;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skill = controller.repository.skill(teaching.skillId);
    final failureReason = controller.teachingFailureReasonFor(
      npc.id,
      teaching.skillId,
    );
    final requirements = _teachingRequirements(controller, npc, teaching);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        failureReason == null ? Icons.school_outlined : Icons.lock_outline,
      ),
      title: Text(skill.name),
      subtitle: Text(
        [
          '${_teachingAccessLabel(teaching.access)} · 可传授至 Lv.${teaching.maxLevel}',
          if (requirements.isNotEmpty) requirements,
          if (failureReason != null) failureReason,
        ].join('\n'),
      ),
      trailing: Icon(
        failureReason == null ? Icons.chevron_right : Icons.info_outline,
      ),
      onTap: onTap,
    );
  }

  String _teachingRequirements(
    GameController controller,
    NpcDefinition npc,
    TeachingSkillDefinition teaching,
  ) {
    final requirements = <String>[];
    final requiredRankId = teaching.requiredRankId;
    final familyId = npc.familyId;
    if (requiredRankId != null && familyId != null) {
      final rank = controller.repository.family(familyId).rank(requiredRankId);
      requirements.add('需${rank?.title ?? requiredRankId}');
    }
    if (teaching.requiredContribution > 0) {
      requirements.add('贡献 ${teaching.requiredContribution}');
    }
    if (teaching.contributionCost > 0) {
      requirements.add('每次耗贡献 ${teaching.contributionCost}');
    }
    for (final skill in teaching.requiredSkillLevels.entries) {
      requirements.add(
        '${controller.repository.skill(skill.key).name} Lv.${skill.value}',
      );
    }
    return requirements.isEmpty ? '' : '条件：${requirements.join(' · ')}';
  }

  String _teachingAccessLabel(TeachingAccess access) {
    return switch (access) {
      TeachingAccess.public => '公开传授',
      TeachingAccess.family => '同门可学',
      TeachingAccess.direct => '嫡传武学',
    };
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
