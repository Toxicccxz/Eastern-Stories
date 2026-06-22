import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/innate_attributes.dart';
import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/models/quest_definition.dart';
import 'package:eastern_stories/game/models/skill_definition.dart';
import 'package:eastern_stories/game/models/skill_progress.dart';
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

  test('repeatable family duties award contribution and unlock promotion', () {
    final initialState = repository.createInitialState().copyWith(
      currentRoomId: 'chunfeng_schoolhall',
      visitedRoomIds: {'chunfeng_schoolhall'},
      questStatuses: const {'fengshan_first_trial': QuestStatus.completed},
      skillProgress: const {
        'literate': SkillProgress(level: 10, experience: 0),
        'basic_sword': SkillProgress(level: 5, experience: 0),
        'fonxan_force': SkillProgress(level: 3, experience: 0),
      },
      apprenticeship: const ApprenticeshipState(
        familyId: 'fengshan_sword',
        masterNpcId: 'liu_chunfeng',
        generation: 14,
        title: '弟子',
        contribution: 10,
        rankId: 'disciple',
      ),
    );
    final controller = GameController(
      repository: repository,
      initialState: initialState,
    );

    _completeSparringDuty(controller);
    expect(controller.state.apprenticeship?.contribution, 15);
    expect(controller.state.apprenticeship?.completedTaskCount, 1);

    controller.dispatch(
      const GameAction.requestFamilyPromotion('liu_chunfeng'),
    );
    expect(controller.state.apprenticeship?.rankId, 'disciple');
    expect(controller.state.log.last, contains('贡献不足'));

    _completeSparringDuty(controller);
    expect(controller.state.apprenticeship?.contribution, 20);
    expect(controller.state.apprenticeship?.completedTaskCount, 2);

    controller.dispatch(
      const GameAction.requestFamilyPromotion('liu_chunfeng'),
    );
    expect(controller.state.apprenticeship?.rankId, 'inner_disciple');
    expect(controller.state.apprenticeship?.title, '入室弟子');
  });

  test('family promotion still requires the listed martial skills', () {
    final controller = GameController(
      repository: repository,
      initialState: repository.createInitialState().copyWith(
        currentRoomId: 'chunfeng_schoolhall',
        apprenticeship: const ApprenticeshipState(
          familyId: 'fengshan_sword',
          masterNpcId: 'liu_chunfeng',
          generation: 14,
          title: '弟子',
          contribution: 20,
          rankId: 'disciple',
          completedTaskCount: 2,
        ),
      ),
    );

    controller.dispatch(
      const GameAction.requestFamilyPromotion('liu_chunfeng'),
    );

    expect(controller.state.apprenticeship?.rankId, 'disciple');
    expect(controller.state.log.last, contains('基本剑法'));
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

void _completeSparringDuty(GameController controller) {
  _moveStateTo(controller, 'chunfeng_schoolhall');
  controller.dispatch(
    const GameAction.acceptFamilyTask('liu_chunfeng', 'fengshan_sparring_duty'),
  );
  expect(controller.state.apprenticeship?.activeTask, isNotNull);

  _moveStateTo(controller, 'chunfeng_training_ground');
  controller.dispatch(const GameAction.startCombat('fengshan_duty_trainee'));
  for (var turn = 0; turn < 12 && controller.state.combat != null; turn += 1) {
    controller.dispatch(const GameAction.attack());
  }
  expect(
    controller.state.apprenticeship?.activeTask?.isObjectiveComplete,
    isTrue,
  );

  _moveStateTo(controller, 'chunfeng_schoolhall');
  controller.dispatch(const GameAction.turnInFamilyTask('liu_chunfeng'));
  expect(controller.state.apprenticeship?.activeTask, isNull);
}
