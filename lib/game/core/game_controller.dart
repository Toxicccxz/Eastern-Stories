import 'package:flutter/foundation.dart';

import '../models/direction.dart';
import '../models/game_state.dart';
import '../models/npc_definition.dart';
import '../models/quest_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'game_action.dart';

class GameController extends ChangeNotifier {
  GameController({required GameDefinitionRepository repository})
    : _repository = repository,
      _state = GameState.initial(startingRoomId: repository.startingRoomId);

  final GameDefinitionRepository _repository;
  GameState _state;

  GameDefinitionRepository get repository => _repository;

  GameState get state => _state;

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
      _completeQuest(completesQuestId);
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
      _state = _state.copyWith(
        combat: null,
        player: _state.player.copyWith(
          silver: _state.player.silver + combat.rewardSilver,
        ),
        log: _state.logWith('你击退了${npc.name}。获得银两 +${combat.rewardSilver}。'),
      );
      notifyListeners();
      return;
    }

    final enemyDamage = (combat.attack - 2).clamp(1, 999);
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

  void _completeQuest(String questId) {
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
