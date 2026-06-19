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
        if (_canShowDialogueOption(state, option)) option,
    ];
  }

  GameState talk(GameState state, String npcId) {
    final npc = _repository.npc(npcId);
    return _withLog(state, '${npc.name}说道：“${npc.greeting}”');
  }

  GameState selectDialogue(GameState state, String npcId, String optionId) {
    final npc = _repository.npc(npcId);
    final option =
        npc.dialogueOptions.where((item) => item.id == optionId).firstOrNull;
    if (option == null || !_canShowDialogueOption(state, option)) {
      return _withLog(state, '${npc.name}没有回应。');
    }

    var nextState = state.copyWith(
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

    final completesQuestId = option.completesQuestId;
    if (completesQuestId != null) {
      return _completeQuestWithExperience(nextState, completesQuestId);
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
    ].join('，');

    return state.copyWith(
      player: state.player.copyWith(
        silver: state.player.silver + quest.rewardSilver,
      ),
      inventoryItemIds: [...state.inventoryItemIds, ...quest.rewardItemIds],
      questStatuses: {...state.questStatuses, questId: QuestStatus.completed},
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

    final nextState = state.copyWith(
      inventoryItemIds: [...state.inventoryItemIds, ...quest.rewardItemIds],
      questStatuses: {...state.questStatuses, questId: QuestStatus.completed},
    );
    return _progressionSystem.awardRewards(
      nextState,
      silver: quest.rewardSilver,
      experience: quest.rewardExperience,
      itemIds: quest.rewardItemIds,
      logPrefix: '完成委托：${quest.title}',
    );
  }

  bool _canShowDialogueOption(GameState state, DialogueOption option) {
    final requiredQuestId = option.requiredQuestId;
    final requiredQuestStatus = option.requiredQuestStatus;
    if (requiredQuestId == null || requiredQuestStatus == null) {
      return true;
    }
    return _questStatus(state, requiredQuestId) == requiredQuestStatus;
  }

  QuestStatus _questStatus(GameState state, String questId) {
    return state.questStatuses[questId] ?? QuestStatus.notStarted;
  }

  bool _isQuestReady(GameState state, QuestDefinition quest) {
    return quest.requiredFlags.every(state.questFlags.contains);
  }

  List<QuestStepView> _questStepViews(GameState state, QuestDefinition quest) {
    final status = _questStatus(state, quest.id);
    if (status == QuestStatus.completed) {
      return [
        for (final step in quest.steps)
          QuestStepView(
            description: step.description,
            status: QuestStepStatus.completed,
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
        QuestStepView(description: step.description, status: stepStatus),
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

    final requiredFlag = step.requiredFlag;
    if (requiredFlag == null || state.questFlags.contains(requiredFlag)) {
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
