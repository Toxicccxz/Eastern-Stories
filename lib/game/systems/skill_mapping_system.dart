import '../models/game_state.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';

class SkillMappingSystem {
  const SkillMappingSystem(this._repository);

  final GameDefinitionRepository _repository;

  GameState enable(GameState state, String skillId, SkillUsage usage) {
    final skill = _repository.skill(skillId);
    if (skill.isBasic) {
      return _withLog(state, '${skill.name}是${usage.label}的根基，不需要启用。');
    }
    if (!state.skillProgress.containsKey(skillId)) {
      return _withLog(state, '你还没有学会${skill.name}。');
    }
    if (!skill.supports(usage)) {
      return _withLog(state, '${skill.name}不能用作${usage.label}。');
    }

    final basicSkill = _repository.basicSkillFor(usage);
    if (basicSkill == null || !state.skillProgress.containsKey(basicSkill.id)) {
      return _withLog(state, '你连${usage.label}的基础都没有学会。');
    }

    final unmetRequirement = learningRequirement(
      state,
      skill,
      requireFamily: false,
    );
    if (unmetRequirement != null) {
      return _withLog(state, unmetRequirement);
    }

    return state.copyWith(
      enabledSkillIds: {...state.enabledSkillIds, usage: skillId},
      log: state.logWith('你将${skill.name}启用为${usage.label}。'),
    );
  }

  GameState disable(GameState state, SkillUsage usage) {
    if (!state.enabledSkillIds.containsKey(usage)) {
      return _withLog(state, '你没有启用特殊${usage.label}。');
    }
    final enabledSkills = {...state.enabledSkillIds}..remove(usage);
    return state.copyWith(
      enabledSkillIds: enabledSkills,
      log: state.logWith('你停用了当前${usage.label}。'),
    );
  }

  String? learningRequirement(
    GameState state,
    SkillDefinition skill, {
    bool requireFamily = true,
  }) {
    final requiredFamilyId = skill.requiredFamilyId;
    if (requireFamily &&
        requiredFamilyId != null &&
        state.apprenticeship?.familyId != requiredFamilyId) {
      final family = _repository.family(requiredFamilyId);
      return '${skill.name}只传授给${family.name}门下。';
    }
    final requiredSlot = skill.requiredEquipmentSlot;
    if (requiredSlot != null &&
        !state.equippedItemIds.containsKey(requiredSlot)) {
      return '研习${skill.name}需要先装备${requiredSlot.label}。';
    }
    if (state.player.maxInnerPower < skill.minimumMaxInnerPower) {
      return '你的内力修为不足，无法运用${skill.name}。';
    }
    for (final requirement in skill.requiredSkillLevels.entries) {
      final level = state.skillProgress[requirement.key]?.level ?? 0;
      if (level < requirement.value) {
        final requiredSkill = _repository.skill(requirement.key);
        return '${requiredSkill.name}需要达到 Lv.${requirement.value}。';
      }
    }
    return null;
  }

  int effectiveLevel(GameState state, SkillUsage usage) {
    final basicSkill = _repository.basicSkillFor(usage);
    final basicLevel =
        basicSkill == null ? 0 : state.skillProgress[basicSkill.id]?.level ?? 0;
    final specialId = state.enabledSkillIds[usage];
    final specialLevel =
        specialId == null ? 0 : state.skillProgress[specialId]?.level ?? 0;
    return basicLevel ~/ 2 + specialLevel;
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
