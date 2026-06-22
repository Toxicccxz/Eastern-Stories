import '../models/family_definition.dart';
import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';
import 'progression_system.dart';

class FamilyTaskSystem {
  const FamilyTaskSystem(this._repository, this._progressionSystem);

  final GameDefinitionRepository _repository;
  final ProgressionSystem _progressionSystem;

  List<FamilyTaskDefinition> tasksFor(GameState state, String npcId) {
    final apprenticeship = state.apprenticeship;
    if (apprenticeship == null) {
      return const [];
    }
    final family = _repository.family(apprenticeship.familyId);
    return [
      for (final task in family.tasks)
        if (task.issuerNpcId == npcId &&
            (task.conditions?.isSatisfiedBy(state) ?? true))
          task,
    ];
  }

  FamilyTaskDefinition? activeTask(GameState state) {
    final apprenticeship = state.apprenticeship;
    final progress = apprenticeship?.activeTask;
    if (apprenticeship == null || progress == null) {
      return null;
    }
    final family = _repository.family(apprenticeship.familyId);
    for (final task in family.tasks) {
      if (task.id == progress.taskId) {
        return task;
      }
    }
    return null;
  }

  FamilyRankDefinition? nextRank(GameState state, String npcId) {
    final apprenticeship = state.apprenticeship;
    if (apprenticeship == null || apprenticeship.masterNpcId != npcId) {
      return null;
    }
    final family = _repository.family(apprenticeship.familyId);
    if (family.ranks.isEmpty) {
      return null;
    }
    final currentIndex = family.ranks.indexWhere(
      (rank) => rank.id == apprenticeship.rankId,
    );
    final nextIndex = currentIndex < 0 ? 1 : currentIndex + 1;
    return nextIndex < family.ranks.length ? family.ranks[nextIndex] : null;
  }

  GameState acceptTask(GameState state, String npcId, String taskId) {
    final apprenticeship = state.apprenticeship;
    if (apprenticeship == null) {
      return _withLog(state, '你尚无师门，不能领取师门差事。');
    }
    if (!_isNpcPresent(state, npcId)) {
      return _withLog(state, '发布差事的人不在这里。');
    }
    if (apprenticeship.activeTask != null) {
      return _withLog(state, '你手上已有一件师门差事，先将它办妥。');
    }
    final task =
        tasksFor(
          state,
          npcId,
        ).where((candidate) => candidate.id == taskId).firstOrNull;
    if (task == null) {
      return _withLog(state, '现在没有这项师门差事。');
    }

    var npcStates = state.npcStates;
    if (task.type == FamilyTaskType.defeatNpc) {
      final targetState = state.npcStates[task.targetId];
      final target = _repository.npc(task.targetId);
      if (targetState != null && target.combat != null) {
        npcStates = {
          ...state.npcStates,
          task.targetId: targetState.copyWith(
            currentHp: target.combat!.maxHp,
            isDefeated: false,
            respawnAtTurn: null,
          ),
        };
      }
    }

    return state.copyWith(
      npcStates: npcStates,
      apprenticeship: apprenticeship.copyWith(
        activeTask: FamilyTaskProgress(taskId: task.id),
      ),
      log: state.logWith('师门差事：${task.title}。${task.description}'),
    );
  }

  GameState advance(GameState previous, GameState next) {
    final apprenticeship = next.apprenticeship;
    final progress = apprenticeship?.activeTask;
    if (apprenticeship == null ||
        progress == null ||
        progress.isObjectiveComplete) {
      return next;
    }
    final task = activeTask(next);
    if (task == null) {
      return next;
    }
    final completed = switch (task.type) {
      FamilyTaskType.defeatNpc =>
        !(previous.npcStates[task.targetId]?.isDefeated ?? false) &&
            (next.npcStates[task.targetId]?.isDefeated ?? false),
      FamilyTaskType.visitRoom =>
        previous.currentRoomId != task.targetId &&
            next.currentRoomId == task.targetId,
    };
    if (!completed) {
      return next;
    }
    return next.copyWith(
      apprenticeship: apprenticeship.copyWith(
        activeTask: progress.copyWith(isObjectiveComplete: true),
      ),
      log: next.logWith('师门差事“${task.title}”已经办妥，可以回去复命。'),
    );
  }

  GameState turnInTask(GameState state, String npcId) {
    final apprenticeship = state.apprenticeship;
    final progress = apprenticeship?.activeTask;
    final task = activeTask(state);
    if (apprenticeship == null || progress == null || task == null) {
      return _withLog(state, '你现在没有需要复命的师门差事。');
    }
    if (task.issuerNpcId != npcId || !_isNpcPresent(state, npcId)) {
      return _withLog(state, '应当向发布差事的师长复命。');
    }
    if (!progress.isObjectiveComplete) {
      return _withLog(state, '这件师门差事还没有办妥。');
    }

    final prepared = state.copyWith(
      apprenticeship: apprenticeship.copyWith(
        contribution: apprenticeship.contribution + task.rewardContribution,
        completedTaskCount: apprenticeship.completedTaskCount + 1,
        activeTask: null,
      ),
    );
    final rewarded = _progressionSystem.awardRewards(
      prepared,
      silver: 0,
      experience: task.rewardExperience,
      potential: task.rewardPotential,
      logPrefix: '完成师门差事：${task.title}',
    );
    return rewarded.copyWith(
      log: rewarded.logWith('师门贡献 +${task.rewardContribution}。'),
    );
  }

  GameState requestPromotion(GameState state, String npcId) {
    final apprenticeship = state.apprenticeship;
    if (apprenticeship == null) {
      return _withLog(state, '你尚无师门，无从谈起晋升。');
    }
    if (apprenticeship.masterNpcId != npcId || !_isNpcPresent(state, npcId)) {
      return _withLog(state, '门内身份应当由你的师父考定。');
    }
    final rank = nextRank(state, npcId);
    if (rank == null) {
      return _withLog(state, '你目前的门内身份已经没有更高一级。');
    }
    if (apprenticeship.contribution < rank.minimumContribution) {
      return _withLog(state, '师门贡献不足，需要达到 ${rank.minimumContribution}。');
    }
    if (apprenticeship.completedTaskCount < rank.minimumCompletedTasks) {
      return _withLog(state, '历练尚浅，需要完成 ${rank.minimumCompletedTasks} 次师门差事。');
    }
    for (final requirement in rank.requiredSkillLevels.entries) {
      final currentLevel = state.skillProgress[requirement.key]?.level ?? 0;
      if (currentLevel < requirement.value) {
        final skill = _repository.skill(requirement.key);
        return _withLog(state, '${skill.name}不足，需要达到 Lv.${requirement.value}。');
      }
    }
    final family = _repository.family(apprenticeship.familyId);
    return state.copyWith(
      apprenticeship: apprenticeship.copyWith(
        rankId: rank.id,
        title: rank.title,
      ),
      log: state.logWith(
        '${_repository.npc(npcId).name}考校过你的武学与功劳，准你晋为${family.name}${rank.title}。',
      ),
    );
  }

  bool _isNpcPresent(GameState state, String npcId) {
    return _repository
        .visibleNpcsInRoom(state, state.currentRoomId)
        .any((npc) => npc.id == npcId);
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
