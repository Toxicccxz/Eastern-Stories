import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/innate_attributes.dart';
import 'package:eastern_stories/game/models/quest_definition.dart';
import 'package:eastern_stories/game/models/skill_definition.dart';
import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDefinitionRepository repository;

  setUpAll(() async {
    repository = await GameDefinitionRepository.loadDemo();
  });

  test(
    'fighter identity, apprenticeship, and first trial form a full loop',
    () {
      final attributes = const InnateAttributes.standard().copyWith(
        strength: 25,
        courage: 25,
        composure: 25,
      );
      final controller = GameController(
        repository: repository,
        initialState: repository.createInitialState(attributes: attributes),
      );

      _moveStateTo(controller, 'waterfog_guildhall');
      controller.dispatch(
        const GameAction.performRoomAction('join_fighter_guild'),
      );
      expect(controller.state.questFlags, contains('fighter_guild_member'));

      _moveStateTo(controller, 'chunfeng_schoolhall');
      controller.dispatch(const GameAction.apprenticeTo('liu_chunfeng'));
      expect(controller.state.apprenticeship?.familyId, 'fengshan_sword');
      expect(controller.state.apprenticeship?.generation, 14);

      controller.dispatch(
        const GameAction.learnFromNpc('liu_chunfeng', 'basic_force'),
      );
      controller.dispatch(
        const GameAction.learnFromNpc('liu_chunfeng', 'fonxan_force'),
      );
      expect(controller.state.learnedSkillIds, contains('fonxan_force'));
      controller.dispatch(
        const GameAction.enableSkill('fonxan_force', SkillUsage.force),
      );
      controller.dispatch(const GameAction.practiceSkill(SkillUsage.force));
      expect(controller.state.log.last, contains('只能通过请教师长'));

      controller.dispatch(
        const GameAction.selectDialogue('liu_chunfeng', 'start_fengshan_trial'),
      );
      expect(
        controller.state.questStatuses['fengshan_first_trial'],
        QuestStatus.active,
      );

      _moveStateTo(controller, 'chunfeng_training_ground');
      expect(
        repository
            .visibleNpcsInRoom(controller.state, 'chunfeng_training_ground')
            .map((npc) => npc.id),
        contains('fengshan_trainee'),
      );
      controller.dispatch(const GameAction.startCombat('fengshan_trainee'));
      for (
        var turn = 0;
        turn < 10 && controller.state.combat != null;
        turn += 1
      ) {
        controller.dispatch(const GameAction.attack());
      }
      expect(
        controller.state.npcStates['fengshan_trainee']?.isDefeated,
        isTrue,
      );

      _moveStateTo(controller, 'chunfeng_schoolhall');
      controller.dispatch(
        const GameAction.selectDialogue(
          'liu_chunfeng',
          'finish_fengshan_trial',
        ),
      );
      expect(
        controller.state.questStatuses['fengshan_first_trial'],
        QuestStatus.completed,
      );
      expect(
        controller.state.inventoryItemIds,
        contains('fengshan_bamboo_sword'),
      );
      expect(controller.state.apprenticeship?.contribution, 10);
    },
  );

  test('Liu Chunfeng explains fighter and aptitude requirements', () {
    final controller = GameController(repository: repository);
    _moveStateTo(controller, 'chunfeng_schoolhall');

    controller.dispatch(const GameAction.apprenticeTo('liu_chunfeng'));
    expect(controller.state.log.last, contains('武者同盟'));

    controller.replaceState(
      controller.state.copyWith(
        questFlags: {...controller.state.questFlags, 'fighter_guild_member'},
      ),
    );
    controller.dispatch(const GameAction.apprenticeTo('liu_chunfeng'));
    expect(controller.state.log.last, contains('胆识不足'));
    expect(controller.state.apprenticeship, isNull);
  });
}

void _moveStateTo(GameController controller, String roomId) {
  controller.replaceState(
    controller.state.copyWith(
      currentRoomId: roomId,
      visitedRoomIds: {...controller.state.visitedRoomIds, roomId},
    ),
  );
}
