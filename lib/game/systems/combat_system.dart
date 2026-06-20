import '../models/game_state.dart';
import '../models/npc_definition.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'equipment_system.dart';
import 'progression_system.dart';

class CombatSystem {
  const CombatSystem(
    this._repository,
    this._progressionSystem,
    this._equipmentSystem,
  );

  final GameDefinitionRepository _repository;
  final ProgressionSystem _progressionSystem;
  final EquipmentSystem _equipmentSystem;

  GameState startCombat(GameState state, String npcId) {
    if (state.combat != null) {
      return _withLog(state, '你已经在战斗中。');
    }

    final npcState = state.npcStates[npcId];
    if (npcState == null ||
        npcState.roomId != state.currentRoomId ||
        npcState.isDefeated) {
      return _withLog(state, '这里没有这个目标。');
    }

    final npc = _repository.npc(npcId);
    final combat = npc.combat;
    if (combat == null) {
      return _withLog(state, '${npc.name}并无敌意。');
    }

    final enemyHp = npcState.currentHp <= 0 ? combat.maxHp : npcState.currentHp;
    return state.copyWith(
      combat: CombatState(npcId: npcId, enemyHp: enemyHp),
      npcStates: {
        ...state.npcStates,
        npcId: npcState.copyWith(currentHp: enemyHp),
      },
      log: state.logWith('${npc.name}逼近过来，战斗开始。'),
    );
  }

  GameState attack(GameState state) {
    return _performPlayerAttack(state);
  }

  GameState useSkill(GameState state, String skillId) {
    if (state.combat == null) {
      return _withLog(state, '现在没有敌人。');
    }
    if (!state.learnedSkillIds.contains(skillId)) {
      return _withLog(state, '你还没有领会这门武功。');
    }

    final skill = _repository.skill(skillId);
    if (!skill.isActive) {
      return _withLog(state, '${skill.name}不是可以主动施展的招式。');
    }

    final requiredSlot = skill.requiredEquipmentSlot;
    if (requiredSlot != null &&
        !state.equippedItemIds.containsKey(requiredSlot)) {
      return _withLog(state, '施展${skill.moveName ?? skill.name}需要合适的兵器。');
    }
    if (state.player.innerPower < skill.innerPowerCost) {
      return _withLog(state, '内力不足，无法施展${skill.moveName ?? skill.name}。');
    }

    final preparedState = state.copyWith(
      player: state.player.copyWith(
        innerPower: state.player.innerPower - skill.innerPowerCost,
      ),
    );
    return _performPlayerAttack(
      preparedState,
      damageBonus: skill.damageBonus,
      skill: skill,
    );
  }

  GameState _performPlayerAttack(
    GameState state, {
    int damageBonus = 0,
    SkillDefinition? skill,
  }) {
    final activeCombat = state.combat;
    if (activeCombat == null) {
      return _withLog(state, '现在没有敌人。');
    }

    final npc = _repository.npc(activeCombat.npcId);
    final combat = npc.combat;
    final npcState = state.npcStates[activeCombat.npcId];
    if (combat == null || npcState == null || npcState.isDefeated) {
      return state.copyWith(combat: null);
    }

    final stats = _equipmentSystem.statsFor(state);
    final playerDamage = (stats.attack + damageBonus - combat.defense).clamp(
      1,
      999,
    );
    final nextEnemyHp = activeCombat.enemyHp - playerDamage;

    if (nextEnemyHp <= 0) {
      final attackState = _appendAttackLog(
        state,
        npc.name,
        playerDamage,
        skill,
      );
      return _defeatNpc(attackState, npc.id, npcState, combat);
    }

    final enemyDamage =
        (combat.attack - stats.defense - _damageReduction(state)).clamp(1, 999);
    final nextPlayerHp = (state.player.hp - enemyDamage).clamp(1, stats.maxHp);
    final wasPlayerDefeated = nextPlayerHp == 1;
    final attackState = _appendAttackLog(state, npc.name, playerDamage, skill);
    final log = [...attackState.log, '${npc.name}反击，你受到$enemyDamage点伤害。'];

    return attackState.copyWith(
      player: attackState.player.copyWith(hp: nextPlayerHp),
      npcStates: {
        ...attackState.npcStates,
        npc.id: npcState.copyWith(currentHp: nextEnemyHp),
      },
      combat:
          wasPlayerDefeated
              ? null
              : activeCombat.copyWith(enemyHp: nextEnemyHp),
      log: wasPlayerDefeated ? [...log, '你勉强脱离战斗，气血只剩一线。'] : log,
    );
  }

  GameState _appendAttackLog(
    GameState state,
    String enemyName,
    int damage,
    SkillDefinition? skill,
  ) {
    final skillMessage = skill?.combatMessage?.replaceAll('{enemy}', enemyName);
    final message =
        skillMessage == null
            ? '你向$enemyName出手，造成$damage点伤害。'
            : '$skillMessage 造成$damage点伤害。';
    return state.copyWith(log: state.logWith(message));
  }

  GameState fleeCombat(GameState state) {
    final activeCombat = state.combat;
    if (activeCombat == null) {
      return _withLog(state, '现在没有敌人。');
    }

    final npc = _repository.npc(activeCombat.npcId);
    return state.copyWith(
      combat: null,
      log: state.logWith('你避开${npc.name}，暂时退到一旁。'),
    );
  }

  GameState _defeatNpc(
    GameState state,
    String npcId,
    NpcRuntimeState npcState,
    CombatDefinition combat,
  ) {
    final npc = _repository.npc(npcId);
    final room = _repository.room(npcState.roomId);
    final currentItemIds = room.visibleItemIds(state);
    final droppedItemIds =
        npcState.hasDroppedLoot
            ? const <String>[]
            : [
              for (final itemId in combat.dropItemIds)
                if (!currentItemIds.contains(itemId) &&
                    !state.inventoryItemIds.contains(itemId))
                  itemId,
            ];
    final respawnAfterMoves = combat.respawnAfterMoves;

    var nextState = state.copyWith(
      combat: null,
      npcStates: {
        ...state.npcStates,
        npc.id: npcState.copyWith(
          currentHp: 0,
          isDefeated: true,
          respawnAtTurn:
              respawnAfterMoves == null
                  ? null
                  : state.worldTurn + respawnAfterMoves,
          hasDroppedLoot: npcState.hasDroppedLoot || droppedItemIds.isNotEmpty,
        ),
      },
      roomItemOverrides: {
        ...state.roomItemOverrides,
        room.id: [...currentItemIds, ...droppedItemIds],
      },
    );
    nextState = _progressionSystem.awardRewards(
      nextState,
      silver: combat.rewardSilver,
      experience: combat.rewardExperience,
      logPrefix: '你击退了${npc.name}',
    );

    if (droppedItemIds.isEmpty) {
      return nextState;
    }
    final dropNames = droppedItemIds
        .map(_repository.item)
        .map((item) => item.name)
        .join('、');
    return nextState.copyWith(
      log: nextState.logWith('${npc.name}留下了$dropNames。'),
    );
  }

  int _damageReduction(GameState state) {
    return state.learnedSkillIds
        .map((skillId) => _repository.skill(skillId).damageReduction)
        .fold(0, (total, reduction) => total + reduction);
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
