import '../models/game_state.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'equipment_system.dart';
import 'skill_mapping_system.dart';
import 'skill_progression_system.dart';

class InnerPowerSystem {
  const InnerPowerSystem(
    this._repository,
    this._equipmentSystem,
    this._skillMappingSystem,
    this._skillProgressionSystem,
  );

  static const meditationSpiritCost = 12;
  static const recoveryInnerPowerCost = 20;
  static const healingInnerPowerCost = 50;

  final GameDefinitionRepository _repository;
  final EquipmentSystem _equipmentSystem;
  final SkillMappingSystem _skillMappingSystem;
  final SkillProgressionSystem _skillProgressionSystem;

  int cultivationLimit(GameState state) {
    final basicLevel = _basicForceLevel(state);
    final specialLevel = _enabledForceLevel(state);
    return (basicLevel + specialLevel ~/ 5) * 10;
  }

  GameState meditate(GameState state) {
    if (state.combat != null) {
      return _withLog(state, '战斗中强行练功，极易走火入魔。');
    }
    if (!_repository.room(state.currentRoomId).allowsCultivation) {
      return _withLog(state, '这里人声杂乱，不适合静坐行功。');
    }
    final forceSkillId = state.enabledSkillIds[SkillUsage.force];
    if (forceSkillId == null) {
      return _withLog(state, '你必须先启用一门内功心法。');
    }
    if (_basicForceLevel(state) == 0) {
      return _withLog(state, '你对基本内功仍一窍不通。');
    }
    if (state.player.spirit < meditationSpiritCost) {
      return _withLog(state, '你精神不济，无法凝神引导内息。');
    }

    final limit = cultivationLimit(state);
    final currentMaximum = state.player.maxInnerPower;
    final currentInnerPower = state.player.innerPower;
    if (limit <= currentMaximum && currentInnerPower >= currentMaximum * 2) {
      return _withLog(state, '内息遍布全身，却触不到更高境界，看来内功修为遇到了瓶颈。');
    }

    final attributes = state.player.attributes;
    final basicLevel = _basicForceLevel(state);
    final specialLevel = _enabledForceLevel(state);
    final maximumGain =
        ((attributes.constitution + basicLevel + specialLevel ~/ 2) ~/ 10)
            .clamp(1, 5);
    final innerPowerGain =
        ((attributes.constitution + basicLevel + specialLevel) ~/ 5).clamp(
          2,
          10,
        );
    final nextMaximum =
        limit > currentMaximum
            ? (currentMaximum + maximumGain).clamp(currentMaximum, limit)
            : currentMaximum;
    final nextInnerPower = (currentInnerPower + innerPowerGain).clamp(
      0,
      nextMaximum * 2,
    );
    final improvedMaximum = nextMaximum > currentMaximum;
    final message =
        improvedMaximum
            ? '你坐下运气行功，内息流遍经脉，内力上限提升到$nextMaximum。'
            : '你坐下运气行功，真气逐渐充盈，内力增加$innerPowerGain。';
    return state.copyWith(
      player: state.player.copyWith(
        spirit: state.player.spirit - meditationSpiritCost,
        innerPower: nextInnerPower,
        maxInnerPower: nextMaximum,
      ),
      log: state.logWith(message),
    );
  }

  GameState recover(GameState state) {
    if (state.combat != null) {
      return _withLog(state, '激战之中无法从容调匀气息。');
    }
    if (state.enabledSkillIds[SkillUsage.force] == null) {
      return _withLog(state, '你必须先启用一门内功心法。');
    }
    if (state.player.innerPower < recoveryInnerPowerCost) {
      return _withLog(state, '你的内力不足，无法调息。');
    }
    final stats = _equipmentSystem.statsFor(state);
    if (state.player.hp >= stats.maxHp) {
      return _withLog(state, '你的气血已经恢复到上限。');
    }
    final recoveredHp =
        _skillMappingSystem.effectiveLevel(state, SkillUsage.force) ~/ 3 + 10;
    return state.copyWith(
      player: state.player.copyWith(
        hp: (state.player.hp + recoveredHp).clamp(0, stats.maxHp),
        innerPower: state.player.innerPower - recoveryInnerPowerCost,
      ),
      log: state.logWith('你深深吸了几口气，将内力化开，气色看起来好多了。'),
    );
  }

  GameState heal(GameState state) {
    if (state.combat != null) {
      return _withLog(state, '战斗中运功疗伤，无异于自寻死路。');
    }
    final forceSkillId = state.enabledSkillIds[SkillUsage.force];
    if (forceSkillId != 'fonxan_force') {
      return _withLog(state, '你当前运用的内功没有疗伤法门。');
    }
    if (state.player.innerPower - state.player.maxInnerPower <
        healingInnerPowerCost) {
      return _withLog(state, '你的真气积蓄不足，尚不能运功疗伤。');
    }
    final stats = _equipmentSystem.statsFor(state);
    if (state.player.hp >= stats.maxHp) {
      return _withLog(state, '你并未受伤，不必耗费真气。');
    }
    final forceLevel = _skillMappingSystem.effectiveLevel(
      state,
      SkillUsage.force,
    );
    final healedState = state.copyWith(
      player: state.player.copyWith(
        hp: (state.player.hp + 20 + forceLevel ~/ 2).clamp(0, stats.maxHp),
        innerPower: state.player.innerPower - healingInnerPowerCost,
      ),
      log: state.logWith('你全身放松，运转封山派内功吐出一口瘀气，伤势顿时轻了许多。'),
    );
    return _skillProgressionSystem.gainExperience(
      healedState,
      skillId: 'fonxan_force',
      experience: 5,
    );
  }

  int _basicForceLevel(GameState state) {
    final skill = _repository.basicSkillFor(SkillUsage.force);
    return skill == null ? 0 : state.skillProgress[skill.id]?.level ?? 0;
  }

  int _enabledForceLevel(GameState state) {
    final skillId = state.enabledSkillIds[SkillUsage.force];
    return skillId == null ? 0 : state.skillProgress[skillId]?.level ?? 0;
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
