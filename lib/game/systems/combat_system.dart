import '../models/game_state.dart';
import '../models/npc_definition.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'equipment_system.dart';
import 'progression_system.dart';
import 'skill_progression_system.dart';
import 'skill_mapping_system.dart';

class CombatSystem {
  const CombatSystem(
    this._repository,
    this._progressionSystem,
    this._equipmentSystem,
    this._skillProgressionSystem,
    this._skillMappingSystem,
  );

  final GameDefinitionRepository _repository;
  final ProgressionSystem _progressionSystem;
  final EquipmentSystem _equipmentSystem;
  final SkillProgressionSystem _skillProgressionSystem;
  final SkillMappingSystem _skillMappingSystem;

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

  GameState useMove(GameState state, String skillId, String moveId) {
    if (state.combat == null) {
      return _withLog(state, '现在没有敌人。');
    }
    if (!state.learnedSkillIds.contains(skillId)) {
      return _withLog(state, '你还没有领会这门武功。');
    }

    final skill = _repository.skill(skillId);
    final skillLevel = state.skillProgress[skillId]?.level ?? 1;
    if (!skill.isBasic && !state.enabledSkillIds.containsValue(skillId)) {
      return _withLog(state, '你尚未启用${skill.name}。');
    }
    final move = skill.moves.where((move) => move.id == moveId).firstOrNull;
    if (move == null) {
      return _withLog(state, '${skill.name}中没有这个招式。');
    }
    if (skillLevel < move.minimumSkillLevel) {
      return _withLog(state, '${skill.name}需要达到 Lv.${move.minimumSkillLevel}。');
    }

    final requiredSlot =
        move.requiredEquipmentSlot ?? skill.requiredEquipmentSlot;
    if (requiredSlot != null &&
        !state.equippedItemIds.containsKey(requiredSlot)) {
      return _withLog(state, '施展${move.name}需要合适的兵器。');
    }
    final innerPowerCost = move.innerPowerCostAtLevel(skillLevel);
    if (state.player.innerPower < innerPowerCost) {
      return _withLog(state, '内力不足，无法施展${move.name}。');
    }

    final preparedState = state.copyWith(
      player: state.player.copyWith(
        innerPower: state.player.innerPower - innerPowerCost,
      ),
    );
    final result = switch (move.effectType) {
      SkillEffectType.damage => _performPlayerAttack(
        preparedState,
        damageBonus: move.damageBonusAtLevel(skillLevel),
        skill: skill,
        move: move,
      ),
      SkillEffectType.defend => _performDefensiveSkill(
        preparedState,
        move,
        skillLevel,
      ),
      SkillEffectType.heal => _performHealingSkill(
        preparedState,
        move,
        skillLevel,
      ),
    };
    return _skillProgressionSystem.gainExperience(
      result,
      skillId: skillId,
      experience: skill.practiceExperience,
    );
  }

  GameState _performPlayerAttack(
    GameState state, {
    int damageBonus = 0,
    SkillDefinition? skill,
    CombatMoveDefinition? move,
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
    final usage = _currentAttackUsage(state);
    final effectiveSkillBonus =
        _skillMappingSystem.effectiveLevel(state, usage) ~/ 5;
    final playerDamage = (stats.attack +
            effectiveSkillBonus +
            damageBonus -
            combat.defense)
        .clamp(1, 999);
    final nextEnemyHp = activeCombat.enemyHp - playerDamage;
    final attackState = _appendAttackLog(
      state,
      npc.name,
      playerDamage,
      skill,
      move,
      usage,
    );

    if (nextEnemyHp <= 0) {
      return _defeatNpc(attackState, npc.id, npcState, combat);
    }
    return _performEnemyTurn(attackState, enemyHp: nextEnemyHp);
  }

  GameState _performDefensiveSkill(
    GameState state,
    CombatMoveDefinition move,
    int skillLevel,
  ) {
    final message = move.combatMessage ?? '你凝神守住门户，准备化解来势。';
    return _performEnemyTurn(
      _withLog(state, message),
      defenseBonus: move.defenseBonusAtLevel(skillLevel),
    );
  }

  GameState _performHealingSkill(
    GameState state,
    CombatMoveDefinition move,
    int skillLevel,
  ) {
    final stats = _equipmentSystem.statsFor(state);
    final healAmount = move.healAmountAtLevel(skillLevel);
    final recoveredHp = (state.player.hp + healAmount).clamp(0, stats.maxHp);
    final message = move.combatMessage ?? '你调匀呼吸，恢复了$healAmount点气血。';
    return _performEnemyTurn(
      state.copyWith(
        player: state.player.copyWith(hp: recoveredHp),
        log: state.logWith(message),
      ),
    );
  }

  GameState _performEnemyTurn(
    GameState state, {
    int? enemyHp,
    int defenseBonus = 0,
  }) {
    final activeCombat = state.combat;
    if (activeCombat == null) {
      return state;
    }
    final npc = _repository.npc(activeCombat.npcId);
    final combat = npc.combat;
    final npcState = state.npcStates[activeCombat.npcId];
    if (combat == null || npcState == null || npcState.isDefeated) {
      return state.copyWith(combat: null);
    }

    final nextRound = activeCombat.round + 1;
    final specialMove = combat.specialMove;
    final usesSpecialMove =
        specialMove != null &&
        specialMove.interval > 0 &&
        nextRound % specialMove.interval == 0;
    final attackBonus = usesSpecialMove ? specialMove.damageBonus : 0;
    final stats = _equipmentSystem.statsFor(state);
    final enemyDamage = (combat.attack +
            attackBonus -
            stats.defense -
            _damageReduction(state) -
            defenseBonus)
        .clamp(0, 999);
    final nextPlayerHp = (state.player.hp - enemyDamage).clamp(0, stats.maxHp);
    final nextEnemyHp = enemyHp ?? activeCombat.enemyHp;
    final attackMessage =
        usesSpecialMove
            ? '【${specialMove.name}】${specialMove.message} '
                '你受到$enemyDamage点伤害。'
            : enemyDamage == 0
            ? '你挡下了${npc.name}的攻势，没有受到伤害。'
            : '${npc.name}反击，你受到$enemyDamage点伤害。';
    final nextState = state.copyWith(
      player: state.player.copyWith(hp: nextPlayerHp),
      npcStates: {
        ...state.npcStates,
        npc.id: npcState.copyWith(currentHp: nextEnemyHp),
      },
      combat: activeCombat.copyWith(enemyHp: nextEnemyHp, round: nextRound),
      log: state.logWith(attackMessage),
    );

    if (nextPlayerHp > 0) {
      return nextState;
    }
    return _recoverFromDefeat(nextState, npc.name);
  }

  GameState _recoverFromDefeat(GameState state, String enemyName) {
    final stats = _equipmentSystem.statsFor(state);
    final startingRoomId = _repository.startingRoomId;
    final npcStates = {...state.npcStates};
    for (final entry in npcStates.entries) {
      if (entry.value.isFollowing) {
        npcStates[entry.key] = entry.value.copyWith(roomId: startingRoomId);
      }
    }
    return state.copyWith(
      currentRoomId: startingRoomId,
      visitedRoomIds: {...state.visitedRoomIds, startingRoomId},
      player: state.player.copyWith(
        hp: (stats.maxHp ~/ 2).clamp(1, stats.maxHp),
        innerPower: (stats.maxInnerPower ~/ 2).clamp(0, stats.maxInnerPower),
      ),
      npcStates: npcStates,
      combat: null,
      log: state.logWith('你不敌$enemyName，昏迷后被人送回刘家小房。'),
    );
  }

  GameState _appendAttackLog(
    GameState state,
    String enemyName,
    int damage,
    SkillDefinition? skill,
    CombatMoveDefinition? move,
    SkillUsage usage,
  ) {
    final skillMessage = move?.combatMessage?.replaceAll('{enemy}', enemyName);
    final mappedSkillId = state.enabledSkillIds[usage];
    final mappedSkill =
        mappedSkillId == null ? null : _repository.skill(mappedSkillId);
    final attackMessages = mappedSkill?.attackMessages ?? const <String>[];
    final ordinaryMessage =
        attackMessages.isEmpty
            ? null
            : attackMessages[state.combat!.round % attackMessages.length]
                .replaceAll('{enemy}', enemyName);
    final message =
        skillMessage != null
            ? '$skillMessage 造成$damage点伤害。'
            : ordinaryMessage != null
            ? '$ordinaryMessage 造成$damage点伤害。'
            : '你向$enemyName出手，造成$damage点伤害。';
    return _withLog(state, message);
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
    final skills = <String>{
      for (final usage in const [SkillUsage.parry, SkillUsage.dodge]) ...[
        if (_repository.basicSkillFor(usage) case final basic?) basic.id,
        if (state.enabledSkillIds[usage] case final mapped?) mapped,
      ],
    }.where(state.skillProgress.containsKey);
    return skills.fold(0, (total, skillId) {
      final level = state.skillProgress[skillId]?.level ?? 0;
      return total + _repository.skill(skillId).damageReductionAtLevel(level);
    });
  }

  SkillUsage _currentAttackUsage(GameState state) {
    final weaponId = state.equippedWeaponId;
    if (weaponId == null) {
      return SkillUsage.unarmed;
    }
    return _repository.item(weaponId).weaponSkillUsage ?? SkillUsage.unarmed;
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
