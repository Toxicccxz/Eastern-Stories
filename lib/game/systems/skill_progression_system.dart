import '../models/game_state.dart';
import '../models/skill_progress.dart';
import '../repositories/game_definition_repository.dart';

class SkillProgressionSystem {
  const SkillProgressionSystem(this._repository);

  final GameDefinitionRepository _repository;

  GameState study(
    GameState state, {
    required String skillId,
    required String itemName,
    required int experience,
    required int studyLevelLimit,
  }) {
    final skill = _repository.skill(skillId);
    final progress = state.skillProgress[skillId];
    if (progress == null) {
      return state.copyWith(
        skillProgress: {
          ...state.skillProgress,
          skillId: const SkillProgress(level: 1, experience: 0),
        },
        log: state.logWith('你研读$itemName，领会了${skill.name}。'),
      );
    }
    final effectiveLimit = studyLevelLimit.clamp(1, skill.maxLevel);
    if (progress.level >= effectiveLimit) {
      return state.copyWith(
        log: state.logWith('$itemName中的内容已无法继续提升${skill.name}。'),
      );
    }
    final nextState = gainExperience(
      state,
      skillId: skillId,
      experience: experience,
      levelLimit: effectiveLimit,
    );
    if (nextState.skillProgress[skillId]?.level != progress.level) {
      return nextState;
    }
    return nextState.copyWith(
      log: nextState.logWith('你研读$itemName，${skill.name}熟练度增加$experience。'),
    );
  }

  GameState gainExperience(
    GameState state, {
    required String skillId,
    required int experience,
    int? levelLimit,
  }) {
    final skill = _repository.skill(skillId);
    final current = state.skillProgress[skillId];
    if (current == null || experience <= 0) {
      return state;
    }
    final maximumLevel = (levelLimit ?? skill.maxLevel).clamp(
      1,
      skill.maxLevel,
    );
    if (current.level >= maximumLevel) {
      return state;
    }

    var level = current.level;
    var accumulated = current.experience + experience;
    while (level < maximumLevel && accumulated >= level * 100) {
      accumulated -= level * 100;
      level += 1;
    }
    if (level >= maximumLevel) {
      accumulated = 0;
    }

    final nextState = state.copyWith(
      skillProgress: {
        ...state.skillProgress,
        skillId: SkillProgress(level: level, experience: accumulated),
      },
    );
    if (level == current.level) {
      return nextState;
    }
    return nextState.copyWith(
      log: nextState.logWith('${skill.name}提升到了 Lv.$level。'),
    );
  }
}
