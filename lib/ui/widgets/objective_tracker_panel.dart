import 'package:flutter/material.dart';

import '../../game/core/game_controller.dart';
import '../../game/models/family_definition.dart';
import '../../game/models/game_state.dart';
import '../../game/models/quest_definition.dart';
import 'area_map_view.dart';
import 'shared/panel.dart';

class ObjectiveTrackerPanel extends StatelessWidget {
  const ObjectiveTrackerPanel({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final objectives = _ObjectiveSnapshot.from(controller);
        if (!objectives.hasVisibleContent) {
          return const SizedBox.shrink();
        }

        return Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '当前目标',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => showObjectiveTrackerSheet(context, controller),
                    child: const Text('详情'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (objectives.activeFamilyTask != null &&
                  objectives.familyTaskProgress != null)
                _CompactFamilyTask(
                  task: objectives.activeFamilyTask!,
                  progress: objectives.familyTaskProgress!,
                  controller: controller,
                ),
              for (final quest in objectives.activeQuests.take(2)) ...[
                if (objectives.activeFamilyTask != null ||
                    quest != objectives.activeQuests.first)
                  const SizedBox(height: 8),
                _CompactQuest(quest: quest, controller: controller),
              ],
              if (objectives.activeQuests.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '还有 ${objectives.activeQuests.length - 2} 项委托在进行。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (objectives.activeQuests.isEmpty &&
                  objectives.activeFamilyTask == null &&
                  objectives.nextRank != null)
                _CompactPromotion(objectives: objectives),
            ],
          ),
        );
      },
    );
  }
}

void showObjectiveTrackerSheet(
  BuildContext context,
  GameController controller,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ObjectiveTrackerSheet(controller: controller),
  );
}

class _ObjectiveTrackerSheet extends StatelessWidget {
  const _ObjectiveTrackerSheet({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final objectives = _ObjectiveSnapshot.from(controller);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('目标', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _SectionTitle(
                  icon: Icons.assignment_outlined,
                  label: '委托',
                  count: objectives.visibleQuests.length,
                ),
                const SizedBox(height: 8),
                if (objectives.visibleQuests.isEmpty)
                  const Text('还没有接到委托。')
                else
                  for (final quest in objectives.visibleQuests)
                    _QuestDetail(quest: quest, controller: controller),
                const Divider(height: 28),
                _SectionTitle(
                  icon: Icons.account_tree_outlined,
                  label: '师门',
                  count: objectives.apprenticeship == null ? 0 : 1,
                ),
                const SizedBox(height: 8),
                if (objectives.apprenticeship == null)
                  const Text('尚未拜入师门。')
                else ...[
                  _FamilyOverview(objectives: objectives),
                  const SizedBox(height: 12),
                  if (objectives.activeFamilyTask != null &&
                      objectives.familyTaskProgress != null)
                    _FamilyTaskDetail(
                      task: objectives.activeFamilyTask!,
                      progress: objectives.familyTaskProgress!,
                      controller: controller,
                    )
                  else
                    const Text('当前没有领取师门差事。'),
                  if (objectives.nextRank != null) ...[
                    const SizedBox(height: 12),
                    _PromotionDetail(objectives: objectives),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ObjectiveSnapshot {
  _ObjectiveSnapshot({
    required this.controller,
    required this.visibleQuests,
    required this.activeQuests,
    required this.apprenticeship,
    required this.activeFamilyTask,
    required this.familyTaskProgress,
    required this.nextRank,
  });

  factory _ObjectiveSnapshot.from(GameController controller) {
    final quests =
        controller
            .questViews()
            .where((quest) => quest.status != QuestStatus.notStarted)
            .toList();
    final activeQuests =
        quests.where((quest) => quest.status == QuestStatus.active).toList();
    final apprenticeship = controller.state.apprenticeship;
    final nextRank =
        apprenticeship == null
            ? null
            : controller.nextFamilyRankFor(apprenticeship.masterNpcId);
    return _ObjectiveSnapshot(
      controller: controller,
      visibleQuests: quests,
      activeQuests: activeQuests,
      apprenticeship: apprenticeship,
      activeFamilyTask: controller.activeFamilyTask(),
      familyTaskProgress: apprenticeship?.activeTask,
      nextRank: nextRank,
    );
  }

  final GameController controller;
  final List<QuestView> visibleQuests;
  final List<QuestView> activeQuests;
  final ApprenticeshipState? apprenticeship;
  final FamilyTaskDefinition? activeFamilyTask;
  final FamilyTaskProgress? familyTaskProgress;
  final FamilyRankDefinition? nextRank;

  bool get hasVisibleContent {
    return activeQuests.isNotEmpty ||
        activeFamilyTask != null ||
        apprenticeship != null;
  }
}

class _CompactQuest extends StatelessWidget {
  const _CompactQuest({required this.quest, required this.controller});

  final QuestView quest;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStepText(quest);
    return _ObjectiveLine(
      icon: Icons.assignment_outlined,
      title: quest.definition.title,
      subtitle: currentStep,
      isComplete: quest.status == QuestStatus.completed,
      onLocate:
          _currentQuestTargetRoomId(controller, quest) == null
              ? null
              : () => _showTargetMap(
                context,
                controller,
                _currentQuestTargetRoomId(controller, quest)!,
              ),
    );
  }
}

class _CompactFamilyTask extends StatelessWidget {
  const _CompactFamilyTask({
    required this.task,
    required this.progress,
    required this.controller,
  });

  final FamilyTaskDefinition task;
  final FamilyTaskProgress progress;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final targetRoomId = _familyTaskTargetRoomId(controller, task);
    return _ObjectiveLine(
      icon: Icons.account_tree_outlined,
      title: '师门差事：${task.title}',
      subtitle:
          progress.isObjectiveComplete
              ? '回去向${controller.repository.npc(task.issuerNpcId).name}复命。'
              : _familyTaskActionText(task),
      isComplete: progress.isObjectiveComplete,
      onLocate:
          targetRoomId == null
              ? null
              : () => _showTargetMap(context, controller, targetRoomId),
    );
  }
}

class _CompactPromotion extends StatelessWidget {
  const _CompactPromotion({required this.objectives});

  final _ObjectiveSnapshot objectives;

  @override
  Widget build(BuildContext context) {
    final masterRoomId = _npcRoomId(
      objectives.controller,
      objectives.apprenticeship!.masterNpcId,
    );
    return _ObjectiveLine(
      icon: Icons.military_tech_outlined,
      title: '门内晋升',
      subtitle: '下一阶：${objectives.nextRank!.title}',
      isComplete: _promotionReady(objectives),
      onLocate:
          masterRoomId == null
              ? null
              : () =>
                  _showTargetMap(context, objectives.controller, masterRoomId),
    );
  }
}

class _QuestDetail extends StatelessWidget {
  const _QuestDetail({required this.quest, required this.controller});

  final QuestView quest;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quest.definition.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusPill(label: _questStatusLabel(quest.status)),
            ],
          ),
          const SizedBox(height: 6),
          Text(quest.definition.description),
          const SizedBox(height: 10),
          for (final step in quest.steps)
            _ProgressRow(
              label: step.description,
              status: switch (step.status) {
                QuestStepStatus.completed => _ProgressStatus.complete,
                QuestStepStatus.current => _ProgressStatus.current,
                QuestStepStatus.pending => _ProgressStatus.pending,
              },
              onLocate:
                  _questStepTargetRoomId(controller, step) == null
                      ? null
                      : () => _showTargetMap(
                        context,
                        controller,
                        _questStepTargetRoomId(controller, step)!,
                      ),
            ),
          if (quest.isReadyToComplete && quest.status == QuestStatus.active)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '事情已经办妥，回去找相关人物交代。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FamilyOverview extends StatelessWidget {
  const _FamilyOverview({required this.objectives});

  final _ObjectiveSnapshot objectives;

  @override
  Widget build(BuildContext context) {
    final apprenticeship = objectives.apprenticeship!;
    final family = objectives.controller.repository.family(
      apprenticeship.familyId,
    );
    final master = objectives.controller.repository.npc(
      apprenticeship.masterNpcId,
    );
    return _CardBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${family.name} · ${apprenticeship.title}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('师父：${master.name}'),
          Text('贡献：${apprenticeship.contribution}'),
          Text('已完成师门差事：${apprenticeship.completedTaskCount} 次'),
        ],
      ),
    );
  }
}

class _FamilyTaskDetail extends StatelessWidget {
  const _FamilyTaskDetail({
    required this.task,
    required this.progress,
    required this.controller,
  });

  final FamilyTaskDefinition task;
  final FamilyTaskProgress progress;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '师门差事：${task.title}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusPill(label: progress.isObjectiveComplete ? '待复命' : '进行中'),
            ],
          ),
          const SizedBox(height: 6),
          Text(task.description),
          const SizedBox(height: 10),
          for (final targetId in task.objectiveIds)
            _ProgressRow(
              label: _familyTargetLabel(controller, task, targetId),
              status:
                  progress.isObjectiveComplete ||
                          progress.completedTargetIds.contains(targetId)
                      ? _ProgressStatus.complete
                      : _ProgressStatus.current,
              onLocate:
                  _familyTargetRoomId(controller, task, targetId) == null
                      ? null
                      : () => _showTargetMap(
                        context,
                        controller,
                        _familyTargetRoomId(controller, task, targetId)!,
                      ),
            ),
          const SizedBox(height: 8),
          Text(
            progress.isObjectiveComplete
                ? '下一步：向${controller.repository.npc(task.issuerNpcId).name}复命。'
                : '下一步：${_familyTaskActionText(task)}',
          ),
          const SizedBox(height: 6),
          Text(
            '奖励：经验 ${task.rewardExperience} · 潜能 ${task.rewardPotential} · 贡献 ${task.rewardContribution}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PromotionDetail extends StatelessWidget {
  const _PromotionDetail({required this.objectives});

  final _ObjectiveSnapshot objectives;

  @override
  Widget build(BuildContext context) {
    final rank = objectives.nextRank!;
    final apprenticeship = objectives.apprenticeship!;
    final controller = objectives.controller;
    return _CardBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '晋升目标：${rank.title}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                final roomId = _npcRoomId(
                  controller,
                  apprenticeship.masterNpcId,
                );
                if (roomId != null) {
                  _showTargetMap(context, controller, roomId);
                }
              },
              icon: const Icon(Icons.travel_explore, size: 18),
              label: Text(
                '定位师父：${controller.repository.npc(apprenticeship.masterNpcId).name}',
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ProgressRow(
            label:
                '师门贡献 ${apprenticeship.contribution}/${rank.minimumContribution}',
            status:
                apprenticeship.contribution >= rank.minimumContribution
                    ? _ProgressStatus.complete
                    : _ProgressStatus.current,
          ),
          _ProgressRow(
            label:
                '师门差事 ${apprenticeship.completedTaskCount}/${rank.minimumCompletedTasks}',
            status:
                apprenticeship.completedTaskCount >= rank.minimumCompletedTasks
                    ? _ProgressStatus.complete
                    : _ProgressStatus.current,
          ),
          for (final requirement in rank.requiredSkillLevels.entries)
            _ProgressRow(
              label:
                  '${controller.repository.skill(requirement.key).name} Lv.${controller.state.skillProgress[requirement.key]?.level ?? 0}/${requirement.value}',
              status:
                  (controller.state.skillProgress[requirement.key]?.level ??
                              0) >=
                          requirement.value
                      ? _ProgressStatus.complete
                      : _ProgressStatus.current,
            ),
        ],
      ),
    );
  }
}

class _ObjectiveLine extends StatelessWidget {
  const _ObjectiveLine({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isComplete,
    this.onLocate,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isComplete;
  final VoidCallback? onLocate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isComplete ? Icons.check_circle : icon,
          size: 20,
          color: isComplete ? colorScheme.primary : colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (onLocate != null)
          IconButton(
            tooltip: '定位',
            onPressed: onLocate,
            icon: const Icon(Icons.travel_explore, size: 20),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 6),
        Text('($count)', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CardBlock extends StatelessWidget {
  const _CardBlock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        border: Border.all(color: const Color(0xFFE0D8C8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum _ProgressStatus { complete, current, pending }

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.status,
    this.onLocate,
  });

  final String label;
  final _ProgressStatus status;
  final VoidCallback? onLocate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (status) {
      _ProgressStatus.complete => Icons.check_circle,
      _ProgressStatus.current => Icons.radio_button_checked,
      _ProgressStatus.pending => Icons.radio_button_unchecked,
    };
    final color = switch (status) {
      _ProgressStatus.complete => colorScheme.primary,
      _ProgressStatus.current => colorScheme.secondary,
      _ProgressStatus.pending => colorScheme.outline,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          if (onLocate != null)
            IconButton(
              tooltip: '定位',
              visualDensity: VisualDensity.compact,
              onPressed: onLocate,
              icon: const Icon(Icons.travel_explore, size: 18),
            ),
        ],
      ),
    );
  }
}

String _currentStepText(QuestView quest) {
  if (quest.status == QuestStatus.completed) {
    return '已经完成。';
  }
  if (quest.isReadyToComplete) {
    return '事情已经办妥，回去交代。';
  }
  for (final step in quest.steps) {
    if (step.status == QuestStepStatus.current) {
      return step.description;
    }
  }
  return quest.definition.description;
}

String _questStatusLabel(QuestStatus status) {
  return switch (status) {
    QuestStatus.notStarted => '未接取',
    QuestStatus.active => '进行中',
    QuestStatus.completed => '已完成',
  };
}

String _familyTaskActionText(FamilyTaskDefinition task) {
  return switch (task.type) {
    FamilyTaskType.defeatNpc => '找到目标并取胜。',
    FamilyTaskType.visitRoom => '前往指定地点。',
    FamilyTaskType.talkToNpc => '拜访指定人物。',
    FamilyTaskType.patrolRooms => '巡查所有指定地点。',
  };
}

String _familyTargetLabel(
  GameController controller,
  FamilyTaskDefinition task,
  String targetId,
) {
  return switch (task.type) {
    FamilyTaskType.defeatNpc ||
    FamilyTaskType.talkToNpc => _npcTargetLabel(controller, targetId),
    FamilyTaskType.visitRoom ||
    FamilyTaskType.patrolRooms => _roomTargetLabel(controller, targetId),
  };
}

String _npcTargetLabel(GameController controller, String npcId) {
  final npc = controller.repository.npc(npcId);
  final npcState = controller.state.npcStates[npcId];
  if (npcState == null) {
    return npc.name;
  }
  return '${npc.name} · ${_roomTargetLabel(controller, npcState.roomId)}';
}

String _roomTargetLabel(GameController controller, String roomId) {
  final room = controller.repository.room(roomId);
  final area = controller.repository.area(room.areaId);
  return '${area.name} · ${room.name}';
}

bool _promotionReady(_ObjectiveSnapshot objectives) {
  final apprenticeship = objectives.apprenticeship;
  final rank = objectives.nextRank;
  if (apprenticeship == null || rank == null) {
    return false;
  }
  if (apprenticeship.contribution < rank.minimumContribution ||
      apprenticeship.completedTaskCount < rank.minimumCompletedTasks) {
    return false;
  }
  for (final requirement in rank.requiredSkillLevels.entries) {
    final currentLevel =
        objectives.controller.state.skillProgress[requirement.key]?.level ?? 0;
    if (currentLevel < requirement.value) {
      return false;
    }
  }
  return true;
}

String? _currentQuestTargetRoomId(GameController controller, QuestView quest) {
  for (final step in quest.steps) {
    if (step.status == QuestStepStatus.current) {
      return _questStepTargetRoomId(controller, step);
    }
  }
  for (final step in quest.steps.reversed) {
    final targetRoomId = _questStepTargetRoomId(controller, step);
    if (targetRoomId != null) {
      return targetRoomId;
    }
  }
  return null;
}

String? _questStepTargetRoomId(GameController controller, QuestStepView step) {
  if (step.targetRoomId != null) {
    return step.targetRoomId;
  }
  final npcId = step.targetNpcId;
  return npcId == null ? null : _npcRoomId(controller, npcId);
}

String? _familyTaskTargetRoomId(
  GameController controller,
  FamilyTaskDefinition task,
) {
  if (task.type == FamilyTaskType.patrolRooms) {
    final progress = controller.state.apprenticeship?.activeTask;
    for (final targetId in task.objectiveIds) {
      if (progress?.completedTargetIds.contains(targetId) ?? false) {
        continue;
      }
      return targetId;
    }
  }
  if (controller.state.apprenticeship?.activeTask?.isObjectiveComplete ??
      false) {
    return _npcRoomId(controller, task.issuerNpcId);
  }
  return _familyTargetRoomId(controller, task, task.objectiveIds.first);
}

String? _familyTargetRoomId(
  GameController controller,
  FamilyTaskDefinition task,
  String targetId,
) {
  return switch (task.type) {
    FamilyTaskType.defeatNpc ||
    FamilyTaskType.talkToNpc => _npcRoomId(controller, targetId),
    FamilyTaskType.visitRoom || FamilyTaskType.patrolRooms => targetId,
  };
}

String? _npcRoomId(GameController controller, String npcId) {
  return controller.state.npcStates[npcId]?.roomId;
}

void _showTargetMap(
  BuildContext context,
  GameController controller,
  String targetRoomId,
) {
  showWorldMapDialog(
    context: context,
    areas: controller.repository.areas.toList(),
    rooms: controller.repository.rooms.toList(),
    state: controller.state,
    currentColor: Theme.of(context).colorScheme.primary,
    initialRoomId: targetRoomId,
    targetRoomId: targetRoomId,
  );
}
