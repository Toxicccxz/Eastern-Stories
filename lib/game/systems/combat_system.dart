import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';
import 'progression_system.dart';

class CombatSystem {
  const CombatSystem(this._repository, this._progressionSystem);

  final GameDefinitionRepository _repository;
  final ProgressionSystem _progressionSystem;

  GameState startCombat(GameState state, String npcId) {
    if (state.combat != null) {
      return _withLog(state, '你已经在战斗中。');
    }

    final room = _repository.room(state.currentRoomId);
    if (!room.npcIds.contains(npcId)) {
      return _withLog(state, '这里没有这个目标。');
    }

    final npc = _repository.npc(npcId);
    final combat = npc.combat;
    if (combat == null) {
      return _withLog(state, '${npc.name}并无敌意。');
    }

    return state.copyWith(
      combat: CombatState(npcId: npcId, enemyHp: combat.maxHp),
      log: state.logWith('${npc.name}逼近过来，战斗开始。'),
    );
  }

  GameState attack(GameState state) {
    final activeCombat = state.combat;
    if (activeCombat == null) {
      return _withLog(state, '现在没有敌人。');
    }

    final npc = _repository.npc(activeCombat.npcId);
    final combat = npc.combat;
    if (combat == null) {
      return state.copyWith(combat: null);
    }

    final weaponId = state.equippedWeaponId;
    final weaponPower =
        weaponId == null ? 0 : _repository.item(weaponId).attackPower;
    final playerDamage = (8 + weaponPower - combat.defense).clamp(1, 999);
    final nextEnemyHp = activeCombat.enemyHp - playerDamage;

    if (nextEnemyHp <= 0) {
      return _progressionSystem.awardRewards(
        state.copyWith(combat: null),
        silver: combat.rewardSilver,
        experience: combat.rewardExperience,
        logPrefix: '你击退了${npc.name}',
      );
    }

    final enemyDamage = (combat.attack - 2 - _damageReduction(state)).clamp(
      1,
      999,
    );
    final nextPlayerHp = (state.player.hp - enemyDamage).clamp(
      1,
      state.player.maxHp,
    );
    final wasDefeated = nextPlayerHp == 1;
    final log = [
      ...state.logWith('你向${npc.name}出手，造成$playerDamage点伤害。'),
      '${npc.name}反击，你受到$enemyDamage点伤害。',
    ];

    return state.copyWith(
      player: state.player.copyWith(hp: nextPlayerHp),
      combat: wasDefeated ? null : activeCombat.copyWith(enemyHp: nextEnemyHp),
      log: wasDefeated ? [...log, '你勉强脱离战斗，气血只剩一线。'] : log,
    );
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

  int _damageReduction(GameState state) {
    return state.learnedSkillIds
        .map((skillId) => _repository.skill(skillId).damageReduction)
        .fold(0, (total, reduction) => total + reduction);
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
