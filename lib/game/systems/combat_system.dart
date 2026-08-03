import '../models/game_state.dart';
import '../models/npc_definition.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'equipment_system.dart';
import 'player_condition_system.dart';
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
    this._playerConditionSystem,
  );

  final GameDefinitionRepository _repository;
  final ProgressionSystem _progressionSystem;
  final EquipmentSystem _equipmentSystem;
  final SkillProgressionSystem _skillProgressionSystem;
  final SkillMappingSystem _skillMappingSystem;
  final PlayerConditionSystem _playerConditionSystem;

  GameState startCombat(GameState state, String npcId) {
    if (state.combat != null) {
      return _withLog(state, '你已经在战斗中。');
    }

    final room = _repository.room(state.currentRoomId);
    if (!room.allowsCombat) {
      return _withLog(state, '这里不是动手的地方。');
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
    final preparation = _preparePlayerTurn(state);
    if (!preparation.canAct || preparation.state.combat == null) {
      return preparation.state;
    }
    return _performPlayerAttack(preparation.state);
  }

  GameState useMove(GameState state, String skillId, String moveId) {
    if (state.combat == null) {
      return _withLog(state, '现在没有敌人。');
    }
    final preparation = _preparePlayerTurn(state);
    state = preparation.state;
    if (!preparation.canAct || state.combat == null) {
      return state;
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
    final attackPenalty = _statusAttackPenalty(state.playerStatusEffects);
    final defensePenalty = _statusDefensePenalty(
      activeCombat.enemyStatusEffects,
    );
    final playerDamage = (stats.attack +
            effectiveSkillBonus +
            damageBonus -
            attackPenalty -
            (combat.defense - defensePenalty))
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
    return _performEnemyTurn(
      _applyStatusEffectToEnemy(
        attackState,
        _resolveStatusEffect(move?.statusEffectId, move?.statusEffect),
        npc.name,
      ),
      enemyHp: nextEnemyHp,
    );
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
    var activeCombat = state.combat;
    if (activeCombat == null) {
      return state;
    }
    final npc = _repository.npc(activeCombat.npcId);
    final combat = npc.combat;
    final npcState = state.npcStates[activeCombat.npcId];
    if (combat == null || npcState == null || npcState.isDefeated) {
      return state.copyWith(combat: null);
    }
    state = state.copyWith(
      combat: activeCombat.copyWith(enemyHp: enemyHp ?? activeCombat.enemyHp),
    );
    state = _tickEnemyStatusEffects(state, npc, npcState, combat);
    activeCombat = state.combat;
    if (activeCombat == null) {
      return state;
    }

    final nextRound = activeCombat.round + 1;
    final specialMove = combat.specialMove;
    final usesSpecialMove =
        specialMove != null &&
        specialMove.interval > 0 &&
        nextRound % specialMove.interval == 0;
    final attackBonus = usesSpecialMove ? specialMove.damageBonus : 0;
    final stats = _equipmentSystem.statsFor(state);
    final enemyAttackPenalty = _statusAttackPenalty(
      activeCombat.enemyStatusEffects,
    );
    final playerDefensePenalty = _statusDefensePenalty(
      state.playerStatusEffects,
    );
    final enemyDamage = (combat.attack +
            attackBonus -
            enemyAttackPenalty -
            (stats.defense - playerDefensePenalty) -
            _damageReduction(state) -
            defenseBonus)
        .clamp(0, 999);
    final nextPlayerHp = (state.player.hp - enemyDamage).clamp(0, stats.maxHp);
    final nextEnemyHp = activeCombat.enemyHp;
    final attackMessage =
        usesSpecialMove
            ? '【${specialMove.name}】${specialMove.message} '
                '你受到$enemyDamage点伤害。'
            : enemyDamage == 0
            ? '你挡下了${npc.name}的攻势，没有受到伤害。'
            : '${npc.name}反击，你受到$enemyDamage点伤害。';
    var nextState = state.copyWith(
      player: state.player.copyWith(hp: nextPlayerHp),
      npcStates: {
        ...state.npcStates,
        npc.id: npcState.copyWith(currentHp: nextEnemyHp),
      },
      combat: activeCombat.copyWith(enemyHp: nextEnemyHp, round: nextRound),
      log: state.logWith(attackMessage),
    );
    if (usesSpecialMove) {
      nextState = _applyStatusEffectToPlayer(
        nextState,
        _resolveStatusEffect(
          specialMove.statusEffectId,
          specialMove.statusEffect,
        ),
        npc.name,
      );
    }

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
      playerStatusEffects: const [],
      combat: null,
      log: state.logWith('你不敌$enemyName，昏迷后被人送回饮风客栈。'),
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
    final preparation = _preparePlayerTurn(state);
    state = preparation.state;
    if (!preparation.canAct || state.combat == null) {
      return state;
    }

    final npc = _repository.npc(state.combat!.npcId);
    final combat = npc.combat;
    if (combat != null) {
      final attributes = state.player.attributes;
      final escapeAbility =
          attributes.courage + attributes.composure + attributes.karma;
      final escapeDifficulty = combat.attack * 6 + activeCombat.round * 2;
      if (escapeAbility < escapeDifficulty) {
        return _performEnemyTurn(
          _withLog(state, '你试图避开${npc.name}，却被对方封住了退路。'),
        );
      }
    }
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
      for (final usage in const [
        SkillUsage.parry,
        SkillUsage.dodge,
        SkillUsage.force,
      ]) ...[
        if (_repository.basicSkillFor(usage) case final basic?) basic.id,
        if (state.enabledSkillIds[usage] case final mapped?) mapped,
      ],
    }.where(state.skillProgress.containsKey);
    return skills.fold(0, (total, skillId) {
      final level = state.skillProgress[skillId]?.level ?? 0;
      return total + _repository.skill(skillId).damageReductionAtLevel(level);
    });
  }

  GameState _applyStatusEffectToEnemy(
    GameState state,
    StatusEffectDefinition? effect,
    String enemyName,
  ) {
    final combat = state.combat;
    if (combat == null || effect == null) {
      return state;
    }
    final status = _statusFromDefinition(effect);
    return state.copyWith(
      combat: combat.copyWith(
        enemyStatusEffects: _replaceStatus(combat.enemyStatusEffects, status),
      ),
      log: state.logWith(
        effect.applicationMessage?.replaceAll('{target}', enemyName) ??
            '$enemyName受到${effect.name}影响。',
      ),
    );
  }

  GameState _applyStatusEffectToPlayer(
    GameState state,
    StatusEffectDefinition? effect,
    String enemyName,
  ) {
    if (state.combat == null || effect == null) {
      return state;
    }
    return _playerConditionSystem.applyDefinition(
      state,
      effect,
      source: enemyName,
    );
  }

  GameState _tickEnemyStatusEffects(
    GameState state,
    NpcDefinition npc,
    NpcRuntimeState npcState,
    CombatDefinition combatDefinition,
  ) {
    final combat = state.combat;
    if (combat == null || combat.enemyStatusEffects.isEmpty) {
      return state;
    }
    final tick = _tickStatuses(combat.enemyStatusEffects, npc.name);
    final nextEnemyHp = (combat.enemyHp - tick.damage + tick.hpRecovery).clamp(
      0,
      combatDefinition.maxHp,
    );
    final tickedState = state.copyWith(
      combat: combat.copyWith(
        enemyHp: nextEnemyHp,
        enemyStatusEffects: tick.effects,
      ),
      log: _recentLog([...state.log, ...tick.messages]),
    );
    if (nextEnemyHp <= 0) {
      return _defeatNpc(tickedState, npc.id, npcState, combatDefinition);
    }
    return tickedState;
  }

  GameState _tickPlayerStatusEffects(GameState state) {
    final combat = state.combat;
    if (combat == null || state.playerStatusEffects.isEmpty) {
      return state;
    }
    final tickedState = _playerConditionSystem.advance(state).state;
    if (tickedState.player.hp > 0) {
      return tickedState;
    }
    final enemyName = _repository.npc(combat.npcId).name;
    return _recoverFromDefeat(tickedState, enemyName);
  }

  _PlayerTurnPreparation _preparePlayerTurn(GameState state) {
    final blockingEffect =
        state.playerStatusEffects
            .where((effect) => effect.blocksAction)
            .firstOrNull;
    final tickedState = _tickPlayerStatusEffects(state);
    if (blockingEffect == null || tickedState.combat == null) {
      return _PlayerTurnPreparation(state: tickedState, canAct: true);
    }
    final blockedState = _withLog(
      tickedState,
      '你受${blockingEffect.name}影响，未能及时出手。',
    );
    return _PlayerTurnPreparation(
      state: _performEnemyTurn(blockedState),
      canAct: false,
    );
  }

  _StatusTickResult _tickStatuses(
    List<StatusEffectState> effects,
    String targetName,
  ) {
    var damage = 0;
    var spiritDamage = 0;
    var innerPowerDamage = 0;
    var hpRecovery = 0;
    final nextEffects = <StatusEffectState>[];
    final messages = <String>[];
    for (final effect in effects) {
      damage += effect.damagePerRound;
      spiritDamage += effect.spiritDamagePerRound;
      innerPowerDamage += effect.innerPowerDamagePerRound;
      hpRecovery += effect.hpRecoveryPerRound;
      final changesResources =
          effect.damagePerRound > 0 ||
          effect.spiritDamagePerRound > 0 ||
          effect.innerPowerDamagePerRound > 0 ||
          effect.hpRecoveryPerRound > 0;
      if ((changesResources || effect.blocksAction) &&
          effect.tickMessage != null) {
        messages.add(
          effect.tickMessage!
              .replaceAll('{target}', targetName)
              .replaceAll('{status}', effect.name)
              .replaceAll('{damage}', effect.damagePerRound.toString())
              .replaceAll(
                '{spiritDamage}',
                effect.spiritDamagePerRound.toString(),
              )
              .replaceAll(
                '{innerPowerDamage}',
                effect.innerPowerDamagePerRound.toString(),
              )
              .replaceAll('{healing}', effect.hpRecoveryPerRound.toString()),
        );
      } else if (effect.damagePerRound > 0) {
        messages.add(
          '$targetName受到${effect.name}影响，损失${effect.damagePerRound}点气血。',
        );
      }
      final nextEffect = effect.tick();
      if (nextEffect.remainingRounds > 0) {
        nextEffects.add(nextEffect);
      } else if (effect.expireMessage != null) {
        messages.add(
          effect.expireMessage!
              .replaceAll('{target}', targetName)
              .replaceAll('{status}', effect.name),
        );
      }
    }
    return _StatusTickResult(
      effects: nextEffects,
      damage: damage,
      spiritDamage: spiritDamage,
      innerPowerDamage: innerPowerDamage,
      hpRecovery: hpRecovery,
      messages: messages,
    );
  }

  StatusEffectState _statusFromDefinition(StatusEffectDefinition effect) {
    return StatusEffectState(
      id: effect.id,
      name: effect.name,
      remainingRounds: effect.duration,
      damagePerRound: effect.damagePerRound,
      spiritDamagePerRound: effect.spiritDamagePerRound,
      innerPowerDamagePerRound: effect.innerPowerDamagePerRound,
      hpRecoveryPerRound: effect.hpRecoveryPerRound,
      attackPenalty: effect.attackPenalty,
      defensePenalty: effect.defensePenalty,
      blocksAction: effect.blocksAction,
      tickMessage: effect.tickMessage,
      expireMessage: effect.expireMessage,
    );
  }

  StatusEffectDefinition? _resolveStatusEffect(
    String? statusEffectId,
    StatusEffectDefinition? inlineEffect,
  ) {
    return inlineEffect ?? _repository.statusEffectOrNull(statusEffectId);
  }

  List<StatusEffectState> _replaceStatus(
    List<StatusEffectState> effects,
    StatusEffectState status,
  ) {
    return [
      for (final effect in effects)
        if (effect.id != status.id) effect,
      status,
    ];
  }

  int _statusAttackPenalty(List<StatusEffectState> effects) {
    return effects.fold(0, (total, effect) => total + effect.attackPenalty);
  }

  int _statusDefensePenalty(List<StatusEffectState> effects) {
    return effects.fold(0, (total, effect) => total + effect.defensePenalty);
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

  List<String> _recentLog(List<String> log) {
    if (log.length <= 20) {
      return log;
    }
    return log.sublist(log.length - 20);
  }
}

class _StatusTickResult {
  const _StatusTickResult({
    required this.effects,
    required this.damage,
    required this.spiritDamage,
    required this.innerPowerDamage,
    required this.hpRecovery,
    required this.messages,
  });

  final List<StatusEffectState> effects;
  final int damage;
  final int spiritDamage;
  final int innerPowerDamage;
  final int hpRecovery;
  final List<String> messages;
}

class _PlayerTurnPreparation {
  const _PlayerTurnPreparation({required this.state, required this.canAct});

  final GameState state;
  final bool canAct;
}
