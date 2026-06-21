import '../models/game_state.dart';
import '../models/npc_definition.dart';
import '../models/skill_progress.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'skill_mapping_system.dart';
import 'skill_progression_system.dart';

class CultivationSystem {
  const CultivationSystem(
    this._repository,
    this._skillProgressionSystem,
    this._skillMappingSystem,
  );

  final GameDefinitionRepository _repository;
  final SkillProgressionSystem _skillProgressionSystem;
  final SkillMappingSystem _skillMappingSystem;

  GameState learnFromNpc(GameState state, String npcId, String skillId) {
    if (state.combat != null) {
      return _withLog(state, '临阵磨枪已经来不及了。');
    }
    final npcState = state.npcStates[npcId];
    if (npcState == null ||
        npcState.roomId != state.currentRoomId ||
        npcState.isDefeated ||
        npcState.isRemoved) {
      return _withLog(state, '传授武学的人不在这里。');
    }
    final teacher = _repository.npc(npcId);
    final teaching = _teaching(teacher, skillId);
    if (teaching == null) {
      return _withLog(state, '${teacher.name}并不传授这门技艺。');
    }
    final accessFailure = _teachingAccessFailure(state, teacher, teaching);
    if (accessFailure != null) {
      return _withLog(state, accessFailure);
    }
    final skill = _repository.skill(skillId);
    final current = state.skillProgress[skillId];
    final teachingLimit = (teaching.maxLevel - state.player.betrayalCount * 5)
        .clamp(1, teaching.maxLevel);
    if ((current?.level ?? 0) >= teachingLimit) {
      return _withLog(state, '你在${skill.name}上的造诣已经不输${teacher.name}。');
    }
    final requirement = _skillMappingSystem.learningRequirement(state, skill);
    if (requirement != null) {
      return _withLog(state, requirement);
    }
    if (state.player.potential <= 0) {
      return _withLog(state, '你的潜能已经发挥到极限，暂时无法继续请教。');
    }
    final apprenticeship = state.apprenticeship;
    if (teaching.contributionCost > 0 &&
        (apprenticeship == null ||
            apprenticeship.contribution < teaching.contributionCost)) {
      return _withLog(state, '你的师门贡献不足，${teacher.name}不肯继续传授。');
    }
    final spiritCost = _learningSpiritCost(state, teacher);
    if (state.player.spirit < spiritCost) {
      return _withLog(state, '你精神不济，无法领会${teacher.name}的讲解。');
    }
    if (current != null &&
        current.level * current.level * current.level ~/ 10 >
            state.player.combatExperience) {
      return _withLog(state, '你缺少实战体会，暂时无法领会更深的${skill.name}。');
    }

    var nextState = state.copyWith(
      player: state.player.copyWith(
        spirit: state.player.spirit - spiritCost,
        potential: state.player.potential - 1,
      ),
      log: state.logWith('你向${teacher.name}请教${skill.name}，似乎有所领悟。'),
      apprenticeship:
          apprenticeship == null || teaching.contributionCost == 0
              ? apprenticeship
              : apprenticeship.copyWith(
                contribution:
                    apprenticeship.contribution - teaching.contributionCost,
              ),
    );
    if (current == null) {
      return nextState.copyWith(
        skillProgress: {
          ...nextState.skillProgress,
          skillId: const SkillProgress(level: 1, experience: 0),
        },
      );
    }
    return _skillProgressionSystem.gainExperience(
      nextState,
      skillId: skillId,
      experience: 20 + state.player.intelligence,
      levelLimit: teachingLimit,
    );
  }

  GameState practice(GameState state, SkillUsage usage) {
    if (state.combat != null) {
      return _withLog(state, '你正在战斗，无法静心练习。');
    }
    final skillId = state.enabledSkillIds[usage];
    if (skillId == null) {
      return _withLog(state, '你需要先启用一门特殊${usage.label}。');
    }
    final skill = _repository.skill(skillId);
    if (!skill.canPractice) {
      return _withLog(state, '${skill.name}只能通过请教师长或实际运用来精进。');
    }
    final progress = state.skillProgress[skillId];
    final basicSkill = _repository.basicSkillFor(usage);
    final basicProgress =
        basicSkill == null ? null : state.skillProgress[basicSkill.id];
    if (progress == null || basicProgress == null) {
      return _withLog(state, '你对这方面的基本功仍是一窍不通。');
    }
    if (progress.level >= basicProgress.level) {
      return _withLog(state, '${skill.name}已无法超越${basicSkill!.name}，应先巩固基本功。');
    }
    if (state.player.hp <= skill.practiceHpCost ||
        state.player.innerPower < skill.practiceInnerPowerCost) {
      return _withLog(state, '你的气血或内力不足，无法继续练习${skill.name}。');
    }
    final requirement = _skillMappingSystem.learningRequirement(
      state,
      skill,
      requireFamily: false,
    );
    if (requirement != null) {
      return _withLog(state, requirement);
    }

    final prepared = state.copyWith(
      player: state.player.copyWith(
        hp: state.player.hp - skill.practiceHpCost,
        innerPower: state.player.innerPower - skill.practiceInnerPowerCost,
      ),
      log: state.logWith('你按所学将${skill.name}演练了一遍。'),
    );
    return _skillProgressionSystem.gainExperience(
      prepared,
      skillId: skillId,
      experience: basicProgress.level ~/ 5 + 10,
      levelLimit: basicProgress.level,
    );
  }

  GameState studyItem(GameState state, String itemId) {
    if (state.combat != null) {
      return _withLog(state, '你无法在战斗中专心研读。');
    }
    if (!state.inventoryItemIds.contains(itemId)) {
      return _withLog(state, '你还没有这个东西。');
    }
    final item = _repository.item(itemId);
    final skillId = item.studySkillId;
    if (skillId == null) {
      return _withLog(state, '${item.name}无法研读。');
    }
    final literacyLevel = state.skillProgress['literate']?.level ?? 0;
    if (literacyLevel == 0) {
      return _withLog(state, '你还不识字，无法读懂${item.name}。');
    }
    if (state.player.combatExperience < item.studyRequiredCombatExperience) {
      return _withLog(state, '你的实战经验不足，读了也无法领会。');
    }
    final skill = _repository.skill(skillId);
    final requirement = _skillMappingSystem.learningRequirement(state, skill);
    if (requirement != null) {
      return _withLog(state, requirement);
    }
    final progress = state.skillProgress[skillId];
    final levelLimit = item.studyMaxSkillLevel.clamp(1, skill.maxLevel);
    if (progress != null && progress.level >= levelLimit) {
      return _withLog(state, '${item.name}中的内容对你而言已经太浅了。');
    }
    final spiritCost = _studySpiritCost(
      state,
      item.studySpiritCost,
      item.studyDifficulty,
    );
    if (state.player.spirit < spiritCost) {
      return _withLog(state, '你过于疲倦，无法专心研读${item.name}。');
    }
    final prepared = state.copyWith(
      player: state.player.copyWith(spirit: state.player.spirit - spiritCost),
    );
    return _skillProgressionSystem.study(
      prepared,
      skillId: skillId,
      itemName: item.name,
      experience: item.studyExperience + literacyLevel ~/ 5,
      studyLevelLimit: levelLimit,
    );
  }

  TeachingSkillDefinition? _teaching(NpcDefinition npc, String skillId) {
    for (final teaching in npc.teachingSkills) {
      if (teaching.skillId == skillId) {
        return teaching;
      }
    }
    return null;
  }

  String? _teachingAccessFailure(
    GameState state,
    NpcDefinition teacher,
    TeachingSkillDefinition teaching,
  ) {
    final apprenticeship = state.apprenticeship;
    return switch (teaching.access) {
      TeachingAccess.public => null,
      TeachingAccess.family when apprenticeship?.familyId == teacher.familyId =>
        null,
      TeachingAccess.direct when apprenticeship?.masterNpcId == teacher.id =>
        null,
      TeachingAccess.family => '${teacher.name}只指点同门弟子。',
      TeachingAccess.direct => '${teacher.name}只向自己的弟子传授这门武学。',
    };
  }

  int _learningSpiritCost(GameState state, NpcDefinition teacher) {
    return (150 ~/ teacher.intelligence + 150 ~/ state.player.intelligence)
        .clamp(1, state.player.maxSpirit);
  }

  int _studySpiritCost(GameState state, int baseCost, int difficulty) {
    final adjusted =
        baseCost + baseCost * (difficulty - state.player.intelligence) ~/ 20;
    return adjusted.clamp(1, state.player.maxSpirit);
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
