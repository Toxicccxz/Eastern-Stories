import '../models/game_state.dart';
import '../models/npc_definition.dart';
import '../models/quest_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'progression_system.dart';

class QuestSystem {
  const QuestSystem(this._repository, this._progressionSystem);

  final GameDefinitionRepository _repository;
  final ProgressionSystem _progressionSystem;

  List<QuestView> questViews(GameState state) {
    return [
      for (final quest in _repository.quests)
        QuestView(
          definition: quest,
          status: _questStatus(state, quest.id),
          isReadyToComplete: _isQuestReady(state, quest),
          steps: _questStepViews(state, quest),
        ),
    ];
  }

  List<DialogueOption> dialogueOptionsFor(GameState state, String npcId) {
    final npc = _repository.npc(npcId);
    return [
      for (final option in npc.dialogueOptions)
        if (_canShowDialogueOption(state, npcId, option)) option,
    ];
  }

  List<GiveItemOption> giveItemOptionsFor(GameState state, String npcId) {
    final npc = _repository.npc(npcId);
    final npcState = state.npcStates[npcId];
    final options = <GiveItemOption>[];
    for (final option in npc.giveItemOptions) {
      if (!(option.conditions?.isSatisfiedBy(state) ?? true)) {
        continue;
      }
      if (!(npcState?.matchesStateValues(option.requiredNpcStateValues) ??
          option.requiredNpcStateValues.isEmpty)) {
        continue;
      }
      if (option.acceptsAnyItem) {
        for (final itemId in state.inventory.itemIds) {
          final item = _repository.item(itemId);
          options.add(
            option.copyWith(
              itemId: itemId,
              label: '${option.label}${item.name}',
            ),
          );
        }
        continue;
      }
      if (state.inventory.contains(option.itemId)) {
        options.add(option);
      }
    }
    return options;
  }

  GameState talk(GameState state, String npcId) {
    final npc = _repository.npc(npcId);
    return _withLog(state, '${npc.name}说道：“${npc.greetingFor(state)}”');
  }

  GameState selectDialogue(GameState state, String npcId, String optionId) {
    final npc = _repository.npc(npcId);
    final option =
        npc.dialogueOptions.where((item) => item.id == optionId).firstOrNull;
    if (option == null || !_canShowDialogueOption(state, npcId, option)) {
      return _withLog(state, '${npc.name}没有回应。');
    }
    if (state.player.silver < option.silverCost) {
      return _withLog(
        state,
        '${npc.name}说道：“${option.insufficientSilverResponse ?? '你带的银两不够。'}”',
      );
    }

    var nextState = state.copyWith(
      player: state.player.copyWith(
        silver: state.player.silver - option.silverCost,
      ),
      inventory: state.inventory.addAll(option.givesItemIds),
      log: state.logWith('${npc.name}说道：“${option.response}”'),
    );
    final startsQuestId = option.startsQuestId;
    if (startsQuestId != null &&
        _questStatus(state, startsQuestId) == QuestStatus.notStarted) {
      final quest = _repository.quest(startsQuestId);
      nextState = nextState.copyWith(
        questStatuses: {
          ...nextState.questStatuses,
          startsQuestId: QuestStatus.active,
        },
        log: nextState.logWith('接到委托：${quest.title}'),
      );
    }

    final questFlag = option.setsQuestFlag;
    if (questFlag != null) {
      nextState = nextState.copyWith(
        questFlags: {...nextState.questFlags, questFlag},
      );
    }

    nextState = _applyNpcStateChanges(
      nextState,
      npcId,
      setValues: option.setNpcStateValues,
      incrementValues: option.incrementNpcStateValues,
    );

    final destinationRoomId = option.movesNpcToRoomId;
    final npcState = nextState.npcStates[npcId];
    if (destinationRoomId != null && npcState != null) {
      nextState = nextState.copyWith(
        npcStates: {
          ...nextState.npcStates,
          npcId: npcState.copyWith(roomId: destinationRoomId),
        },
      );
    }

    if (option.startsFollowing && npcState != null) {
      nextState = nextState.copyWith(
        npcStates: {
          ...nextState.npcStates,
          npcId: npcState.copyWith(
            roomId: nextState.currentRoomId,
            isFollowing: true,
            followUntilTurn:
                option.followingDurationTurns == null
                    ? null
                    : nextState.worldTurn + option.followingDurationTurns!,
            followReturnRoomId:
                option.followingDurationTurns == null ? null : npcState.roomId,
          ),
        },
      );
    }

    if (option.despawnNpcIds.isNotEmpty) {
      final npcStates = {...nextState.npcStates};
      for (final removedNpcId in option.despawnNpcIds) {
        final removedNpcState = npcStates[removedNpcId];
        if (removedNpcState != null) {
          npcStates[removedNpcId] = removedNpcState.copyWith(
            isFollowing: false,
            isRemoved: true,
          );
        }
      }
      nextState = nextState.copyWith(npcStates: npcStates);
    }

    final completesQuestId = option.completesQuestId;
    if (completesQuestId != null) {
      return _completeQuestWithExperience(nextState, completesQuestId);
    }
    return nextState;
  }

  GameState giveItem(GameState state, String npcId, String itemId) {
    final npc = _repository.npc(npcId);
    final isPresent = _repository
        .visibleNpcsInRoom(state, state.currentRoomId)
        .any((item) => item.id == npcId);
    if (!isPresent) {
      return _withLog(state, '这里没有${npc.name}。');
    }
    final option =
        giveItemOptionsFor(
          state,
          npcId,
        ).where((item) => item.itemId == itemId).firstOrNull;
    if (option == null) {
      return _withLog(state, '${npc.name}不肯收下这个东西。');
    }

    var inventory = state.inventory;
    if (option.consumesItem) {
      inventory = inventory.remove(itemId);
    }
    inventory = inventory.addAll(option.givesItemIds);
    var nextState = state.copyWith(
      inventory: inventory,
      questFlags:
          option.setsQuestFlag == null
              ? state.questFlags
              : {...state.questFlags, option.setsQuestFlag!},
      log: state.logWith('${npc.name}说道：“${option.response}”'),
    );
    nextState = _applyNpcStateChanges(
      nextState,
      npcId,
      setValues: option.setNpcStateValues,
      incrementValues: option.incrementNpcStateValues,
    );
    if (option.startsFollowing) {
      final npcState = nextState.npcStates[npcId];
      if (npcState != null) {
        nextState = nextState.copyWith(
          npcStates: {
            ...nextState.npcStates,
            npcId: npcState.copyWith(
              roomId: nextState.currentRoomId,
              isFollowing: true,
            ),
          },
        );
      }
    }
    final completesQuestId = option.completesQuestId;
    if (completesQuestId != null) {
      nextState = _completeQuestWithExperience(nextState, completesQuestId);
    }
    return nextState;
  }

  GameState completeQuestLegacy(GameState state, String questId) {
    final quest = _repository.quest(questId);
    if (_questStatus(state, questId) != QuestStatus.active) {
      return _withLog(state, '现在还没有这项委托。');
    }
    if (!_isQuestReady(state, quest)) {
      return _withLog(state, '这件事还没办妥。');
    }

    final rewardNames = quest.rewardItemIds
        .map(_repository.item)
        .map((item) => item.name)
        .join('、');
    final rewardText = [
      if (quest.rewardSilver > 0) '银两 +${quest.rewardSilver}',
      if (rewardNames.isNotEmpty) rewardNames,
      if (_earnsFamilyContribution(state, quest))
        '师门贡献 +${quest.rewardFamilyContribution}',
    ].join('，');

    return state.copyWith(
      player: state.player.copyWith(
        silver: state.player.silver + quest.rewardSilver,
      ),
      inventory: state.inventory.addAll(quest.rewardItemIds),
      questStatuses: {...state.questStatuses, questId: QuestStatus.completed},
      apprenticeship: _rewardApprenticeship(state, quest),
      log: state.logWith(
        rewardText.isEmpty
            ? '完成委托：${quest.title}'
            : '完成委托：${quest.title}。获得$rewardText。',
      ),
    );
  }

  GameState _completeQuestWithExperience(GameState state, String questId) {
    final quest = _repository.quest(questId);
    if (_questStatus(state, questId) != QuestStatus.active) {
      return _withLog(state, '现在还没有这项委托。');
    }
    if (!_isQuestReady(state, quest)) {
      return _withLog(state, '这件事还没办妥。');
    }

    final earnsContribution = _earnsFamilyContribution(state, quest);
    final nextState = state.copyWith(
      inventory: state.inventory.addAll(quest.rewardItemIds),
      questStatuses: {...state.questStatuses, questId: QuestStatus.completed},
      apprenticeship: _rewardApprenticeship(state, quest),
      log:
          earnsContribution
              ? state.logWith('你为师门立下功劳，贡献 +${quest.rewardFamilyContribution}。')
              : state.log,
    );
    return _progressionSystem.awardRewards(
      nextState,
      silver: quest.rewardSilver,
      experience: quest.rewardExperience,
      itemIds: quest.rewardItemIds,
      logPrefix: '完成委托：${quest.title}',
    );
  }

  bool _canShowDialogueOption(
    GameState state,
    String npcId,
    DialogueOption option,
  ) {
    if (!(option.conditions?.isSatisfiedBy(state) ?? true)) {
      return false;
    }
    final npcState = state.npcStates[npcId];
    if (!(npcState?.matchesStateValues(option.requiredNpcStateValues) ??
        option.requiredNpcStateValues.isEmpty)) {
      return false;
    }
    final requiredQuestId = option.requiredQuestId;
    final requiredQuestStatus = option.requiredQuestStatus;
    if (requiredQuestId == null || requiredQuestStatus == null) {
      return true;
    }
    return _questStatus(state, requiredQuestId) == requiredQuestStatus;
  }

  GameState _applyNpcStateChanges(
    GameState state,
    String npcId, {
    required Map<String, int> setValues,
    required Map<String, int> incrementValues,
  }) {
    final npcState = state.npcStates[npcId];
    if (npcState == null || (setValues.isEmpty && incrementValues.isEmpty)) {
      return state;
    }
    return state.copyWith(
      npcStates: {
        ...state.npcStates,
        npcId: npcState.applyStateChanges(
          setValues: setValues,
          incrementValues: incrementValues,
        ),
      },
    );
  }

  ApprenticeshipState? _rewardApprenticeship(
    GameState state,
    QuestDefinition quest,
  ) {
    final apprenticeship = state.apprenticeship;
    if (apprenticeship == null ||
        apprenticeship.familyId != quest.rewardFamilyId ||
        quest.rewardFamilyContribution == 0) {
      return apprenticeship;
    }
    return apprenticeship.copyWith(
      contribution:
          apprenticeship.contribution + quest.rewardFamilyContribution,
    );
  }

  bool _earnsFamilyContribution(GameState state, QuestDefinition quest) {
    return state.apprenticeship?.familyId == quest.rewardFamilyId &&
        quest.rewardFamilyContribution > 0;
  }

  QuestStatus _questStatus(GameState state, String questId) {
    return state.questStatuses[questId] ?? QuestStatus.notStarted;
  }

  bool _isQuestReady(GameState state, QuestDefinition quest) {
    return quest.requiredFlags.every(state.questFlags.contains) &&
        quest.requiredDefeatedNpcIds.every(
          (npcId) => state.npcStates[npcId]?.isDefeated ?? false,
        );
  }

  List<QuestStepView> _questStepViews(GameState state, QuestDefinition quest) {
    final status = _questStatus(state, quest.id);
    if (status == QuestStatus.completed) {
      return [
        for (final step in quest.steps)
          QuestStepView(
            description: step.description,
            status: QuestStepStatus.completed,
            targetRoomId: step.targetRoomId,
            targetNpcId: step.targetNpcId,
          ),
      ];
    }

    var foundCurrentStep = false;
    final views = <QuestStepView>[];
    for (var index = 0; index < quest.steps.length; index += 1) {
      final step = quest.steps[index];
      final isLastStep = index == quest.steps.length - 1;
      final stepStatus =
          status == QuestStatus.active &&
                  _isQuestReady(state, quest) &&
                  isLastStep
              ? QuestStepStatus.current
              : _stepStatus(state, step, status, foundCurrentStep);
      if (stepStatus == QuestStepStatus.current) {
        foundCurrentStep = true;
      }
      views.add(
        QuestStepView(
          description: step.description,
          status: stepStatus,
          targetRoomId: step.targetRoomId,
          targetNpcId: step.targetNpcId,
        ),
      );
    }
    return views;
  }

  QuestStepStatus _stepStatus(
    GameState state,
    QuestStepDefinition step,
    QuestStatus questStatus,
    bool hasCurrentStep,
  ) {
    if (questStatus == QuestStatus.notStarted) {
      return QuestStepStatus.pending;
    }

    final hasRequiredFlag =
        step.requiredFlag == null ||
        state.questFlags.contains(step.requiredFlag);
    final requiredNpcId = step.requiredDefeatedNpcId;
    final hasDefeatedRequiredNpc =
        requiredNpcId == null ||
        (state.npcStates[requiredNpcId]?.isDefeated ?? false);
    if (hasRequiredFlag && hasDefeatedRequiredNpc) {
      return QuestStepStatus.completed;
    }
    return hasCurrentStep ? QuestStepStatus.pending : QuestStepStatus.current;
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
