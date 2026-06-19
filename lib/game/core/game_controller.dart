import 'package:flutter/foundation.dart';

import '../models/direction.dart';
import '../models/game_state.dart';
import '../models/npc_definition.dart';
import '../models/quest_definition.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'game_action.dart';

class GameController extends ChangeNotifier {
  GameController({
    required GameDefinitionRepository repository,
    GameState? initialState,
  }) : _repository = repository,
       _state =
           initialState ??
           GameState.initial(startingRoomId: repository.startingRoomId);

  final GameDefinitionRepository _repository;
  GameState _state;

  GameDefinitionRepository get repository => _repository;

  GameState get state => _state;

  void replaceState(GameState state) {
    _state = state;
    notifyListeners();
  }

  void reset() {
    _state = GameState.initial(startingRoomId: _repository.startingRoomId);
    notifyListeners();
  }

  void dispatch(GameAction action) {
    switch (action) {
      case MoveAction(:final direction):
        _move(direction);
      case LookAction():
        _look();
      case PerformRoomAction(:final actionId):
        _performRoomAction(actionId);
      case TalkAction(:final npcId):
        _talk(npcId);
      case SelectDialogueAction(:final npcId, :final optionId):
        _selectDialogue(npcId, optionId);
      case PickUpAction(:final itemId):
        _pickUp(itemId);
      case EquipItemAction(:final itemId):
        _equipItem(itemId);
      case StudyItemAction(:final itemId):
        _studyItem(itemId);
      case UseItemAction(:final itemId):
        _useItem(itemId);
      case StartCombatAction(:final npcId):
        _startCombat(npcId);
      case AttackAction():
        _attack();
      case FleeCombatAction():
        _fleeCombat();
    }
  }

  List<QuestView> questViews() {
    return [
      for (final quest in _repository.quests)
        QuestView(
          definition: quest,
          status: _questStatus(quest.id),
          isReadyToComplete: _isQuestReady(quest),
          steps: _questStepViews(quest),
        ),
    ];
  }

  List<DialogueOption> dialogueOptionsFor(String npcId) {
    final npc = _repository.npc(npcId);
    return [
      for (final option in npc.dialogueOptions)
        if (_canShowDialogueOption(option)) option,
    ];
  }

  List<SkillDefinition> learnedSkills() {
    return [
      for (final skillId in _state.learnedSkillIds) _repository.skill(skillId),
    ];
  }

  void _move(Direction direction) {
    final room = _repository.room(_state.currentRoomId);
    final nextRoomId = room.exits[direction];
    if (nextRoomId == null) {
      _appendLog('这个方向没有路。');
      return;
    }

    final nextRoom = _repository.room(nextRoomId);
    _state = _state.copyWith(
      currentRoomId: nextRoomId,
      visitedRoomIds: {..._state.visitedRoomIds, nextRoomId},
      log: _state.logWith('你向${direction.label}走去，来到${nextRoom.name}。'),
    );
    notifyListeners();
  }

  void _look() {
    final room = _repository.room(_state.currentRoomId);
    _appendLog(room.description);
  }

  void _performRoomAction(String actionId) {
    final room = _repository.room(_state.currentRoomId);
    final action =
        room.actions.where((item) => item.id == actionId).firstOrNull;
    if (action == null) {
      _appendLog('这里暂时不能这样做。');
      return;
    }

    final nextRoom = _repository.room(action.resultRoomId);
    _state = _state.copyWith(
      currentRoomId: nextRoom.id,
      visitedRoomIds: {..._state.visitedRoomIds, nextRoom.id},
      log: _state.logWith(action.log),
    );
    notifyListeners();
  }

  void _talk(String npcId) {
    final npc = _repository.npc(npcId);
    _appendLog('${npc.name}说道：“${npc.greeting}”');
  }

  void _selectDialogue(String npcId, String optionId) {
    final npc = _repository.npc(npcId);
    final option =
        npc.dialogueOptions.where((item) => item.id == optionId).firstOrNull;
    if (option == null || !_canShowDialogueOption(option)) {
      _appendLog('${npc.name}没有回应。');
      return;
    }

    var nextState = _state.copyWith(
      log: _state.logWith('${npc.name}说道：“${option.response}”'),
    );
    final startsQuestId = option.startsQuestId;
    if (startsQuestId != null &&
        _questStatus(startsQuestId) == QuestStatus.notStarted) {
      final quest = _repository.quest(startsQuestId);
      nextState = nextState.copyWith(
        questStatuses: {
          ...nextState.questStatuses,
          startsQuestId: QuestStatus.active,
        },
        log: nextState.logWith('接到委托：${quest.title}'),
      );
    }

    final setsQuestFlag = option.setsQuestFlag;
    if (setsQuestFlag != null) {
      nextState = nextState.copyWith(
        questFlags: {...nextState.questFlags, setsQuestFlag},
      );
    }

    _state = nextState;

    final completesQuestId = option.completesQuestId;
    if (completesQuestId != null) {
      _completeQuestWithExperience(completesQuestId);
      return;
    }

    notifyListeners();
  }

  void _pickUp(String itemId) {
    final room = _repository.room(_state.currentRoomId);
    if (!room.itemIds.contains(itemId) ||
        _state.inventoryItemIds.contains(itemId)) {
      _appendLog('这里没有这个东西。');
      return;
    }

    final item = _repository.item(itemId);
    _state = _state.copyWith(
      roomItemOverrides: {
        ..._state.roomItemOverrides,
        room.id:
            room.visibleItemIds(_state).where((id) => id != itemId).toList(),
      },
      inventoryItemIds: [..._state.inventoryItemIds, itemId],
      log: _state.logWith('你拾起了${item.name}。'),
    );
    notifyListeners();
  }

  void _equipItem(String itemId) {
    if (!_state.inventoryItemIds.contains(itemId)) {
      _appendLog('你还没有这个东西。');
      return;
    }

    final item = _repository.item(itemId);
    if (!item.canEquip) {
      _appendLog('${item.name}不能装备。');
      return;
    }

    _state = _state.copyWith(
      equippedWeaponId: itemId,
      log: _state.logWith('你装备了${item.name}。'),
    );
    notifyListeners();
  }

  void _studyItem(String itemId) {
    if (!_state.inventoryItemIds.contains(itemId)) {
      _appendLog('你还没有这个东西。');
      return;
    }

    final item = _repository.item(itemId);
    final skillId = item.studySkillId;
    if (skillId == null) {
      _appendLog('${item.name}无法研读。');
      return;
    }
    if (_state.learnedSkillIds.contains(skillId)) {
      _appendLog('你已经领会了${_repository.skill(skillId).name}。');
      return;
    }

    final skill = _repository.skill(skillId);
    _state = _state.copyWith(
      learnedSkillIds: {..._state.learnedSkillIds, skillId},
      log: _state.logWith('你研读${item.name}，领会了${skill.name}。'),
    );
    notifyListeners();
  }

  void _useItem(String itemId) {
    if (!_state.inventoryItemIds.contains(itemId)) {
      _appendLog('你还没有这个东西。');
      return;
    }

    final item = _repository.item(itemId);
    if (!item.canUse) {
      _appendLog('${item.name}现在不能使用。');
      return;
    }

    final nextHp = (_state.player.hp + item.restoreHp).clamp(
      0,
      _state.player.maxHp,
    );
    final nextInnerPower = (_state.player.innerPower + item.restoreInnerPower)
        .clamp(0, _state.player.maxInnerPower);
    final inventory = [..._state.inventoryItemIds];
    inventory.remove(itemId);

    _state = _state.copyWith(
      player: _state.player.copyWith(hp: nextHp, innerPower: nextInnerPower),
      inventoryItemIds: inventory,
      log: _state.logWith('你用了${item.name}，精神稍振。'),
    );
    notifyListeners();
  }

  void _startCombat(String npcId) {
    if (_state.combat != null) {
      _appendLog('你已经在战斗中。');
      return;
    }

    final room = _repository.room(_state.currentRoomId);
    if (!room.npcIds.contains(npcId)) {
      _appendLog('这里没有这个目标。');
      return;
    }

    final npc = _repository.npc(npcId);
    final combat = npc.combat;
    if (combat == null) {
      _appendLog('${npc.name}并无敌意。');
      return;
    }

    _state = _state.copyWith(
      combat: CombatState(npcId: npcId, enemyHp: combat.maxHp),
      log: _state.logWith('${npc.name}逼近过来，战斗开始。'),
    );
    notifyListeners();
  }

  void _attack() {
    final activeCombat = _state.combat;
    if (activeCombat == null) {
      _appendLog('现在没有敌人。');
      return;
    }

    final npc = _repository.npc(activeCombat.npcId);
    final combat = npc.combat;
    if (combat == null) {
      _state = _state.copyWith(combat: null);
      notifyListeners();
      return;
    }

    final weaponId = _state.equippedWeaponId;
    final weaponPower =
        weaponId == null ? 0 : _repository.item(weaponId).attackPower;
    final playerDamage = (8 + weaponPower - combat.defense).clamp(1, 999);
    final nextEnemyHp = activeCombat.enemyHp - playerDamage;

    if (nextEnemyHp <= 0) {
      _state = _state.copyWith(combat: null);
      _awardRewards(
        silver: combat.rewardSilver,
        experience: combat.rewardExperience,
        logPrefix: '你击退了${npc.name}',
      );
      notifyListeners();
      return;
    }

    final enemyDamage = (combat.attack - 2 - _damageReduction()).clamp(1, 999);
    final nextPlayerHp = (_state.player.hp - enemyDamage).clamp(
      1,
      _state.player.maxHp,
    );
    final wasDefeated = nextPlayerHp == 1;
    final log = [
      ..._state.logWith('你向${npc.name}出手，造成$playerDamage点伤害。'),
      '${npc.name}反击，你受到$enemyDamage点伤害。',
    ];

    _state = _state.copyWith(
      player: _state.player.copyWith(hp: nextPlayerHp),
      combat: wasDefeated ? null : activeCombat.copyWith(enemyHp: nextEnemyHp),
      log: wasDefeated ? [...log, '你勉强脱离战斗，气血只剩一线。'] : log,
    );
    notifyListeners();
  }

  void _fleeCombat() {
    final activeCombat = _state.combat;
    if (activeCombat == null) {
      _appendLog('现在没有敌人。');
      return;
    }

    final npc = _repository.npc(activeCombat.npcId);
    _state = _state.copyWith(
      combat: null,
      log: _state.logWith('你避开${npc.name}，暂时退到一旁。'),
    );
    notifyListeners();
  }

  int _damageReduction() {
    return _state.learnedSkillIds
        .map((skillId) => _repository.skill(skillId).damageReduction)
        .fold(0, (total, reduction) => total + reduction);
  }

  void _appendLog(String message) {
    _state = _state.copyWith(log: _state.logWith(message));
    notifyListeners();
  }

  bool _canShowDialogueOption(DialogueOption option) {
    final requiredQuestId = option.requiredQuestId;
    final requiredQuestStatus = option.requiredQuestStatus;
    if (requiredQuestId == null || requiredQuestStatus == null) {
      return true;
    }
    return _questStatus(requiredQuestId) == requiredQuestStatus;
  }

  QuestStatus _questStatus(String questId) {
    return _state.questStatuses[questId] ?? QuestStatus.notStarted;
  }

  bool _isQuestReady(QuestDefinition quest) {
    return quest.requiredFlags.every(_state.questFlags.contains);
  }

  List<QuestStepView> _questStepViews(QuestDefinition quest) {
    final status = _questStatus(quest.id);
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
          status == QuestStatus.active && _isQuestReady(quest) && isLastStep
              ? QuestStepStatus.current
              : _stepStatus(step, status, foundCurrentStep);
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
    QuestStepDefinition step,
    QuestStatus questStatus,
    bool hasCurrentStep,
  ) {
    if (questStatus == QuestStatus.notStarted) {
      return QuestStepStatus.pending;
    }

    final requiredFlag = step.requiredFlag;
    if (requiredFlag == null || _state.questFlags.contains(requiredFlag)) {
      return QuestStepStatus.completed;
    }
    return hasCurrentStep ? QuestStepStatus.pending : QuestStepStatus.current;
  }

  void _completeQuestWithExperience(String questId) {
    final quest = _repository.quest(questId);
    if (_questStatus(questId) != QuestStatus.active) {
      _appendLog('现在还没有这项委托。');
      return;
    }
    if (!_isQuestReady(quest)) {
      _appendLog('这件事还没办妥。');
      return;
    }

    _state = _state.copyWith(
      inventoryItemIds: [..._state.inventoryItemIds, ...quest.rewardItemIds],
      questStatuses: {..._state.questStatuses, questId: QuestStatus.completed},
    );
    _awardRewards(
      silver: quest.rewardSilver,
      experience: quest.rewardExperience,
      itemIds: quest.rewardItemIds,
      logPrefix: '完成委托：${quest.title}',
    );
    notifyListeners();
  }

  void completeQuestLegacy(String questId) {
    final quest = _repository.quest(questId);
    if (_questStatus(questId) != QuestStatus.active) {
      _appendLog('现在还没有这项委托。');
      return;
    }
    if (!_isQuestReady(quest)) {
      _appendLog('这件事还没办妥。');
      return;
    }

    final rewards = quest.rewardItemIds.map(_repository.item).toList();
    final rewardNames = rewards.map((item) => item.name).join('、');
    final rewardText = [
      if (quest.rewardSilver > 0) '银两 +${quest.rewardSilver}',
      if (rewardNames.isNotEmpty) rewardNames,
    ].join('，');

    _state = _state.copyWith(
      player: _state.player.copyWith(
        silver: _state.player.silver + quest.rewardSilver,
      ),
      inventoryItemIds: [..._state.inventoryItemIds, ...quest.rewardItemIds],
      questStatuses: {..._state.questStatuses, questId: QuestStatus.completed},
      log: _state.logWith(
        rewardText.isEmpty
            ? '完成委托：${quest.title}'
            : '完成委托：${quest.title}。获得$rewardText。',
      ),
    );
    notifyListeners();
  }

  void _awardRewards({
    required int silver,
    required int experience,
    required String logPrefix,
    List<String> itemIds = const [],
  }) {
    final rewardNames = itemIds
        .map(_repository.item)
        .map((item) => item.name)
        .join('、');
    final rewardText = [
      if (silver > 0) '银两 +$silver',
      if (experience > 0) '经验 +$experience',
      if (rewardNames.isNotEmpty) rewardNames,
    ].join('，');

    final previousLevel = _state.player.level;
    final playerWithSilver = _state.player.copyWith(
      silver: _state.player.silver + silver,
    );
    final nextPlayer = _applyExperience(playerWithSilver, experience);
    final log = [
      ..._state.logWith(
        rewardText.isEmpty ? logPrefix : '$logPrefix。获得$rewardText。',
      ),
      if (nextPlayer.level > previousLevel)
        '你升到了 Lv.${nextPlayer.level}，气血和内力更加充沛。',
    ];

    _state = _state.copyWith(player: nextPlayer, log: log);
  }

  PlayerState _applyExperience(PlayerState player, int gainedExperience) {
    var level = player.level;
    var experience = player.experience + gainedExperience;
    var nextLevelExperience = player.nextLevelExperience;
    var maxHp = player.maxHp;
    var maxInnerPower = player.maxInnerPower;

    while (experience >= nextLevelExperience) {
      experience -= nextLevelExperience;
      level += 1;
      maxHp += 12;
      maxInnerPower += 6;
      nextLevelExperience += 60;
    }

    return player.copyWith(
      level: level,
      experience: experience,
      nextLevelExperience: nextLevelExperience,
      hp: maxHp,
      maxHp: maxHp,
      innerPower: maxInnerPower,
      maxInnerPower: maxInnerPower,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
