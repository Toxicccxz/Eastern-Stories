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
      includeAdvancementRequirements: false,
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
    bool includeAdvancementRequirements = true,
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
      final level = skillLevel(state, requirement.key);
      if (level < requirement.value) {
        final requiredSkill = _repository.skill(requirement.key);
        return '${requiredSkill.name}需要达到 Lv.${requirement.value}。';
      }
    }
    if (includeAdvancementRequirements) {
      final currentLevel = state.skillProgress[skill.id]?.level ?? 0;
      for (final requiredSkillId in skill.requiredHigherSkillIds) {
        if (skillLevel(state, requiredSkillId) <= currentLevel) {
          final requiredSkill = _repository.skill(requiredSkillId);
          return '你的${requiredSkill.name}修为不够，无法领悟更高深的${skill.name}。';
        }
      }
      final combinedRequirement = skill.combinedAttributeRequirement;
      if (combinedRequirement != null) {
        var attributeValue = state.player.attributes.valueFor(
          combinedRequirement.attribute,
        );
        var maxInnerPower = state.player.maxInnerPower;
        for (final itemId in state.equippedItemIds.values) {
          final item = _repository.item(itemId);
          attributeValue +=
              item.attributeBonuses[combinedRequirement.attribute] ?? 0;
          maxInnerPower += item.maxInnerPowerBonus;
        }
        final total =
            attributeValue +
            maxInnerPower ~/ combinedRequirement.maxInnerPowerDivisor;
        if (total < combinedRequirement.minimum) {
          return '你的${combinedRequirement.attribute.label}还不够，也许该练一练内力来增强力量。';
        }
      }
    }
    return null;
  }

  int skillLevel(GameState state, String skillId) {
    var level = state.skillProgress[skillId]?.level ?? 0;
    for (final itemId in state.equippedItemIds.values) {
      level += _repository.item(itemId).skillBonuses[skillId] ?? 0;
    }
    return level.clamp(0, 1 << 30);
  }

  int effectiveLevel(GameState state, SkillUsage usage) {
    final basicSkill = _repository.basicSkillFor(usage);
    final basicLevel =
        basicSkill == null ? 0 : skillLevel(state, basicSkill.id);
    final specialId = state.enabledSkillIds[usage];
    final specialLevel = specialId == null ? 0 : skillLevel(state, specialId);
    return basicLevel ~/ 2 + specialLevel;
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
