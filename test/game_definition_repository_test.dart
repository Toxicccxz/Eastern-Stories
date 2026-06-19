import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo world loads from JSON with valid references', () async {
    final repository = await GameDefinitionRepository.loadDemo();
    final rooms = repository.rooms.toList();

    expect(repository.startingRoomId, 'liu_home');
    expect(repository.areas, hasLength(2));
    expect(rooms, hasLength(13));
    expect(repository.quests, hasLength(1));

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
      for (final action in room.actions) {
        expect(
          () => repository.room(action.resultRoomId),
          returnsNormally,
          reason:
              '${room.id} action ${action.id} references unknown room '
              '${action.resultRoomId}',
        );
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
      for (final option in npc.dialogueOptions) {
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
    }

    for (final item in repository.items) {
      final skillId = item.studySkillId;
      if (skillId != null) {
        expect(
          () => repository.skill(skillId),
          returnsNormally,
          reason: '${item.id} references unknown skill $skillId',
        );
      }
    }

    for (final quest in repository.quests) {
      for (final itemId in quest.rewardItemIds) {
        expect(
          () => repository.item(itemId),
          returnsNormally,
          reason: '${quest.id} rewards unknown item $itemId',
        );
      }
    }
  });
}
