import '../models/game_state.dart';
import '../models/corpse_state.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'equipment_system.dart';
import 'player_condition_system.dart';

class SpellSystem {
  const SpellSystem(
    this._repository,
    this._equipmentSystem,
    this._playerConditionSystem,
  );

  static const meditationSpiritCost = 30;
  static const cultivationEnergyCost = 30;

  final GameDefinitionRepository _repository;
  final EquipmentSystem _equipmentSystem;
  final PlayerConditionSystem _playerConditionSystem;

  GameState useWorldMove(GameState state, String skillId, String moveId) {
    if (state.combat != null) {
      return _withLog(state, '战斗中的法术应当临敌施展。');
    }
    final skill = _repository.skill(skillId);
    final progress = state.skillProgress[skillId];
    if (progress == null) {
      return _withLog(state, '你还没有领会这门武功。');
    }
    if (!skill.isBasic && !state.enabledSkillIds.containsValue(skillId)) {
      return _withLog(state, '你尚未启用${skill.name}。');
    }
    final move = skill.moves.where((move) => move.id == moveId).firstOrNull;
    if (move == null || !move.usableOutsideCombat) {
      return _withLog(state, '${skill.name}中没有可在此时施展的这个法术。');
    }
    if (progress.level < move.minimumSkillLevel) {
      return _withLog(state, '${skill.name}需要达到 Lv.${move.minimumSkillLevel}。');
    }
    final effect =
        move.statusEffect ??
        _repository.statusEffectOrNull(move.statusEffectId);
    if (effect == null || move.effectType != SkillEffectType.selfStatus) {
      return _withLog(state, '${move.name}没有产生任何效果。');
    }
    if (state.playerStatusEffects.any((status) => status.id == effect.id)) {
      return _withLog(
        state,
        move.activeFailureMessage ?? '${effect.name}仍在生效。',
      );
    }
    if (state.player.mana < move.manaCost) {
      return _withLog(state, '法力不足，无法施展${move.name}。');
    }
    if (state.player.spirit < move.spiritCost) {
      return _withLog(state, '精神无法集中，无法施展${move.name}。');
    }
    final spentState = state.copyWith(
      player: state.player.copyWith(
        mana: state.player.mana - move.manaCost,
        spirit: state.player.spirit - move.spiritCost,
      ),
    );
    return _playerConditionSystem.applyDefinition(
      spentState,
      effect,
      durationOverride: _durationFor(state, move),
    );
  }

  int _durationFor(GameState state, CombatMoveDefinition move) {
    final skillId = move.durationSkillId;
    if (skillId == null) {
      return move.statusEffect?.duration ??
          _repository.statusEffectOrNull(move.statusEffectId)?.duration ??
          1;
    }
    final skillLevel = state.skillProgress[skillId]?.level ?? 0;
    return (skillLevel * move.durationMultiplier + move.durationBonus).clamp(
      1,
      9999,
    );
  }

  GameState animateCorpse(
    GameState state,
    String skillId,
    String moveId,
    String corpseId,
  ) {
    if (state.combat != null) {
      return _withLog(state, '你正忙着战斗，哪有空闲驱动尸体。');
    }
    final skill = _repository.skill(skillId);
    final progress = state.skillProgress[skillId];
    if (progress == null) {
      return _withLog(state, '你还没有领会这门武功。');
    }
    if (!skill.isBasic && !state.enabledSkillIds.containsValue(skillId)) {
      return _withLog(state, '你尚未启用${skill.name}。');
    }
    final move = skill.moves.where((move) => move.id == moveId).firstOrNull;
    if (move == null || move.effectType != SkillEffectType.animateCorpse) {
      return _withLog(state, '${skill.name}中没有驱动尸体的法术。');
    }
    if (progress.level < move.minimumSkillLevel) {
      return _withLog(state, '${skill.name}需要达到 Lv.${move.minimumSkillLevel}。');
    }
    final corpse = state.corpses[corpseId];
    if (corpse == null || corpse.roomId != state.currentRoomId) {
      return _withLog(state, '这里没有这具尸体。');
    }
    if (!corpse.canAnimateAt(state.worldTurn)) {
      return _withLog(state, '这具尸体只剩枯骨，无法再以法术驱动。');
    }
    if (state.undeadCompanion != null) {
      return _withLog(state, '你已经驱动着一具僵尸。');
    }
    if (state.player.mana < move.manaCost) {
      return _withLog(state, '法力不足，无法施展${move.name}。');
    }
    if (state.player.spirit < move.spiritCost) {
      return _withLog(state, '精神无法集中，无法施展${move.name}。');
    }

    final corpses = {...state.corpses}..remove(corpseId);
    final companionName = '${corpse.victimName}的僵尸';
    return state.copyWith(
      player: state.player.copyWith(
        mana: state.player.mana - move.manaCost,
        spirit: state.player.spirit - move.spiritCost,
      ),
      corpses: corpses,
      undeadCompanion: UndeadCompanionState(
        name: companionName,
        attack: 15,
        hp: 400,
        maxHp: 400,
        defense: 6,
        remainingTurns: _durationFor(state, move),
      ),
      log: state.logWith('${corpse.nameAt(state.worldTurn)}忽然动了几下，慢慢地直起身来。'),
    );
  }

  GameState meditate(GameState state) {
    if (state.combat != null) {
      return _withLog(state, '战斗中冥思，无异于自寻死路。');
    }
    if (state.player.spirit < meditationSpiritCost) {
      return _withLog(state, '你现在精神太差，无法进入冥思。');
    }
    final maxHp = _equipmentSystem.statsFor(state).maxHp;
    if (state.player.hp * 100 < maxHp * 70) {
      return _withLog(state, '你现在身体状况太差，无法集中精神。');
    }

    final spellsSkillId =
        _repository.basicSkillFor(SkillUsage.spells)?.id ?? 'spells';
    final spellsLevel = state.skillProgress[spellsSkillId]?.level ?? 0;
    final manaGain =
        meditationSpiritCost *
        (spellsLevel + state.player.attributes.spirituality) ~/
        300;
    final spentState = state.copyWith(
      player: state.player.copyWith(
        spirit: state.player.spirit - meditationSpiritCost,
      ),
    );
    if (manaGain < 1) {
      return _withLog(spentState, '你盘膝静坐良久，睁眼时却只觉得脑中一片空白。');
    }

    final accumulatedMana = state.player.mana + manaGain;
    if (accumulatedMana <= state.player.maxMana * 2) {
      return spentState.copyWith(
        player: spentState.player.copyWith(mana: accumulatedMana),
        log: spentState.logWith('你盘膝冥思，将游离的精神凝聚为$manaGain点法力。'),
      );
    }

    final cultivationLimit = spellsLevel * 10;
    if (state.player.maxMana >= cultivationLimit) {
      return spentState.copyWith(
        player: spentState.player.copyWith(mana: state.player.maxMana),
        log: spentState.logWith('法力涌动的瞬间，你忽觉脑中一片混乱，法力修为已遇到瓶颈。'),
      );
    }

    final nextMaximum = state.player.maxMana + 1;
    return spentState.copyWith(
      player: spentState.player.copyWith(
        mana: nextMaximum,
        maxMana: nextMaximum,
      ),
      log: spentState.logWith('你将积蓄的法力收归灵台，法力上限提升到了$nextMaximum。'),
    );
  }

  GameState cultivateAtman(GameState state) {
    if (state.combat != null) {
      return _withLog(state, '战斗也是修行，但不能与灵力修炼同时进行。');
    }
    if (state.player.energy < cultivationEnergyCost) {
      return _withLog(state, '你现在精力不足，无法修炼灵力。');
    }
    final maxHp = _equipmentSystem.statsFor(state).maxHp;
    if (state.player.hp * 100 < maxHp * 70) {
      return _withLog(state, '你现在身体状况太差，无法集中精神。');
    }
    if (state.player.spirit * 100 < state.player.maxSpirit * 70) {
      return _withLog(state, '你现在精神状况太差，无法控制自己的心灵。');
    }

    final magicSkillId =
        _repository.basicSkillFor(SkillUsage.magic)?.id ?? 'magic';
    final magicLevel = state.skillProgress[magicSkillId]?.level ?? 0;
    final atmanGain =
        cultivationEnergyCost *
        (magicLevel + state.player.attributes.spirituality) ~/
        300;
    final spentState = state.copyWith(
      player: state.player.copyWith(
        energy: state.player.energy - cultivationEnergyCost,
      ),
    );
    if (atmanGain < 1) {
      return _withLog(spentState, '你闭目打坐良久，却一不小心睡着了。');
    }

    final accumulatedAtman = state.player.atman + atmanGain;
    if (accumulatedAtman <= state.player.maxAtman * 2) {
      return spentState.copyWith(
        player: spentState.player.copyWith(atman: accumulatedAtman),
        log: spentState.logWith('你炼精化气，将自身精力转化为$atmanGain点灵力。'),
      );
    }

    final cultivationLimit = magicLevel * 10;
    if (state.player.maxAtman >= cultivationLimit) {
      return spentState.copyWith(
        player: spentState.player.copyWith(atman: state.player.maxAtman),
        log: spentState.logWith('你忽觉一阵天旋地转，灵力修行已经遇到了瓶颈。'),
      );
    }

    final nextMaximum = state.player.maxAtman + 1;
    return spentState.copyWith(
      player: spentState.player.copyWith(
        atman: nextMaximum,
        maxAtman: nextMaximum,
      ),
      log: spentState.logWith('你炼神还虚，道行有所精进，灵力上限提升到了$nextMaximum。'),
    );
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
