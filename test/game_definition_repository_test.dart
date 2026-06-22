import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:eastern_stories/game/models/family_definition.dart';
import 'package:eastern_stories/game/models/world_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo world loads from JSON with valid references', () async {
    final repository = await GameDefinitionRepository.loadDemo();
    final rooms = repository.rooms.toList();

    expect(repository.startingRoomId, 'liu_home');
    expect(repository.areas, hasLength(5));
    expect(rooms, hasLength(36));
    expect(repository.quests, hasLength(3));
    expect(repository.skills, hasLength(13));
    expect(repository.families, hasLength(2));

    for (final area in repository.areas) {
      expect(
        repository.roomsInArea(area.id),
        isNotEmpty,
        reason: '${area.id} has no rooms',
      );
    }

    for (final room in rooms) {
      expect(
        () => repository.area(room.areaId),
        returnsNormally,
        reason: '${room.id} references unknown area ${room.areaId}',
      );
      for (final targetRoomId in room.exits.values) {
        expect(
          () => repository.room(targetRoomId),
          returnsNormally,
          reason: '${room.id} has an invalid exit to $targetRoomId',
        );
      }
      for (final condition in room.exitConditions.values) {
        _expectValidCondition(repository, condition);
      }
      for (final action in room.actions) {
        expect(
          () => repository.room(action.resultRoomId),
          returnsNormally,
          reason:
              '${room.id} action ${action.id} references unknown room '
              '${action.resultRoomId}',
        );
        final condition = action.conditions;
        if (condition != null) {
          _expectValidCondition(repository, condition);
        }
      }
      for (final npcId in room.npcIds) {
        expect(
          () => repository.npc(npcId),
          returnsNormally,
          reason: '${room.id} references unknown npc $npcId',
        );
      }
      for (final itemId in room.itemIds) {
        expect(
          () => repository.item(itemId),
          returnsNormally,
          reason: '${room.id} references unknown item $itemId',
        );
      }
    }

    for (final npc in repository.npcs) {
      final npcCondition = npc.conditions;
      if (npcCondition != null) {
        _expectValidCondition(repository, npcCondition);
      }
      for (final greeting in npc.greetingVariants) {
        _expectValidCondition(repository, greeting.conditions);
      }
      final combat = npc.combat;
      if (combat != null) {
        final specialMove = combat.specialMove;
        if (specialMove != null) {
          expect(
            specialMove.interval,
            greaterThan(0),
            reason: '${npc.id} has an invalid special move interval',
          );
        }
        for (final itemId in combat.dropItemIds) {
          expect(
            () => repository.item(itemId),
            returnsNormally,
            reason: '${npc.id} drops unknown item $itemId',
          );
        }
      }
      final shop = npc.shop;
      if (shop != null) {
        for (final product in shop.products) {
          final item = repository.item(product.itemId);
          expect(
            item.buyPrice,
            greaterThan(0),
            reason: '${npc.id} sells ${item.id} without a buy price',
          );
          expect(
            product.initialStock,
            greaterThanOrEqualTo(-1),
            reason: '${npc.id} has invalid stock for ${item.id}',
          );
        }
      }
      for (final option in npc.dialogueOptions) {
        final optionCondition = option.conditions;
        if (optionCondition != null) {
          _expectValidCondition(repository, optionCondition);
        }
        final destinationRoomId = option.movesNpcToRoomId;
        if (destinationRoomId != null) {
          expect(
            () => repository.room(destinationRoomId),
            returnsNormally,
            reason:
                '${npc.id} dialogue ${option.id} references unknown room '
                '$destinationRoomId',
          );
        }
        for (final removedNpcId in option.despawnNpcIds) {
          expect(
            () => repository.npc(removedNpcId),
            returnsNormally,
            reason:
                '${npc.id} dialogue ${option.id} removes unknown NPC '
                '$removedNpcId',
          );
        }
        final questIds =
            [
              option.requiredQuestId,
              option.startsQuestId,
              option.completesQuestId,
            ].whereType<String>();
        for (final questId in questIds) {
          expect(
            () => repository.quest(questId),
            returnsNormally,
            reason:
                '${npc.id} dialogue ${option.id} references unknown quest '
                '$questId',
          );
        }
      }
      for (final option in npc.giveItemOptions) {
        expect(
          () => repository.item(option.itemId),
          returnsNormally,
          reason: '${npc.id} accepts unknown item ${option.itemId}',
        );
        for (final itemId in option.givesItemIds) {
          expect(
            () => repository.item(itemId),
            returnsNormally,
            reason: '${npc.id} gives unknown item $itemId',
          );
        }
        final condition = option.conditions;
        if (condition != null) {
          _expectValidCondition(repository, condition);
        }
        final questId = option.completesQuestId;
        if (questId != null) {
          expect(() => repository.quest(questId), returnsNormally);
        }
      }
      for (final teaching in npc.teachingSkills) {
        final skill = repository.skill(teaching.skillId);
        expect(teaching.maxLevel, inInclusiveRange(1, skill.maxLevel));
        expect(teaching.contributionCost, greaterThanOrEqualTo(0));
      }
      final familyId = npc.familyId;
      if (familyId != null) {
        expect(() => repository.family(familyId), returnsNormally);
        expect(npc.familyGeneration, greaterThan(0));
      }
      if (npc.canAcceptApprentices) {
        expect(familyId, isNotNull);
        expect(npc.familyGeneration, isNotNull);
      }
    }

    for (final item in repository.items) {
      final itemCondition = item.conditions;
      if (itemCondition != null) {
        _expectValidCondition(repository, itemCondition);
      }
      final skillId = item.studySkillId;
      if (skillId != null) {
        expect(
          () => repository.skill(skillId),
          returnsNormally,
          reason: '${item.id} references unknown skill $skillId',
        );
        final skill = repository.skill(skillId);
        expect(item.studyMaxSkillLevel, greaterThan(0));
        expect(item.studyMaxSkillLevel, lessThanOrEqualTo(skill.maxLevel));
        if (item.studyMaxSkillLevel > 1) {
          expect(item.studyExperience, greaterThan(0));
        }
        expect(item.studySpiritCost, greaterThan(0));
        expect(item.studyDifficulty, greaterThan(0));
        expect(item.studyRequiredCombatExperience, greaterThanOrEqualTo(0));
      }
    }

    for (final quest in repository.quests) {
      final rewardFamilyId = quest.rewardFamilyId;
      if (rewardFamilyId != null) {
        expect(() => repository.family(rewardFamilyId), returnsNormally);
        expect(quest.rewardFamilyContribution, greaterThan(0));
      }
      for (final step in quest.steps) {
        final npcId = step.requiredDefeatedNpcId;
        if (npcId != null) {
          expect(
            () => repository.npc(npcId),
            returnsNormally,
            reason: '${quest.id} step references unknown NPC $npcId',
          );
        }
      }
      for (final npcId in quest.requiredDefeatedNpcIds) {
        expect(
          () => repository.npc(npcId),
          returnsNormally,
          reason: '${quest.id} requires unknown defeated NPC $npcId',
        );
      }
      for (final itemId in quest.rewardItemIds) {
        expect(
          () => repository.item(itemId),
          returnsNormally,
          reason: '${quest.id} rewards unknown item $itemId',
        );
      }
    }

    for (final skill in repository.skills) {
      expect(skill.usages, isNotEmpty, reason: '${skill.id} has no usage');
      if (skill.isBasic) {
        for (final usage in skill.usages) {
          expect(
            repository.basicSkillFor(usage)?.id,
            skill.id,
            reason: '${usage.name} must have one basic skill',
          );
        }
      }
      for (final requirement in skill.requiredSkillLevels.entries) {
        expect(
          () => repository.skill(requirement.key),
          returnsNormally,
          reason: '${skill.id} requires unknown skill ${requirement.key}',
        );
        expect(requirement.value, greaterThan(0));
      }
      for (final move in skill.moves) {
        expect(move.id, isNotEmpty);
        expect(move.minimumSkillLevel, inInclusiveRange(1, skill.maxLevel));
      }
      final familyId = skill.requiredFamilyId;
      if (familyId != null) {
        expect(() => repository.family(familyId), returnsNormally);
      }
    }

    for (final family in repository.families) {
      final rankIds = <String>{};
      for (final rank in family.ranks) {
        expect(rankIds.add(rank.id), isTrue);
        expect(rank.minimumContribution, greaterThanOrEqualTo(0));
        expect(rank.minimumCompletedTasks, greaterThanOrEqualTo(0));
        for (final requirement in rank.requiredSkillLevels.entries) {
          expect(() => repository.skill(requirement.key), returnsNormally);
          expect(requirement.value, greaterThan(0));
        }
      }
      for (final task in family.tasks) {
        expect(() => repository.npc(task.issuerNpcId), returnsNormally);
        switch (task.type) {
          case FamilyTaskType.defeatNpc:
            expect(() => repository.npc(task.targetId), returnsNormally);
            expect(repository.npc(task.targetId).combat, isNotNull);
          case FamilyTaskType.visitRoom:
            expect(() => repository.room(task.targetId), returnsNormally);
        }
        expect(task.rewardExperience, greaterThanOrEqualTo(0));
        expect(task.rewardPotential, greaterThanOrEqualTo(0));
        expect(task.rewardContribution, greaterThan(0));
        final condition = task.conditions;
        if (condition != null) {
          _expectValidCondition(repository, condition);
        }
      }
    }
  });
}

void _expectValidCondition(
  GameDefinitionRepository repository,
  WorldCondition condition,
) {
  for (final questId in condition.requiredQuestStatuses.keys) {
    expect(() => repository.quest(questId), returnsNormally);
  }
  for (final npcId in {
    ...condition.requiredDefeatedNpcIds,
    ...condition.forbiddenDefeatedNpcIds,
  }) {
    expect(() => repository.npc(npcId), returnsNormally);
  }
  final familyId = condition.requiredFamilyId;
  if (familyId != null) {
    expect(() => repository.family(familyId), returnsNormally);
  }
  final familyTaskId = condition.requiredFamilyTaskId;
  if (familyTaskId != null) {
    expect(
      repository.families
          .expand((family) => family.tasks)
          .any((task) => task.id == familyTaskId),
      isTrue,
      reason: 'condition references unknown family task $familyTaskId',
    );
  }
}
