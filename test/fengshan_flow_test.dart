import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/direction.dart';
import 'package:eastern_stories/game/models/innate_attributes.dart';
import 'package:eastern_stories/game/models/equipment_slot.dart';
import 'package:eastern_stories/game/models/family_definition.dart';
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

  test('advanced Fengshan teaching is locked behind inner disciple rank', () {
    final readyState = repository.createInitialState().copyWith(
      currentRoomId: 'chunfeng_schoolhall',
      inventoryItemIds: const ['fengshan_bamboo_sword'],
      equippedItemIds: const {EquipmentSlot.weapon: 'fengshan_bamboo_sword'},
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
        contribution: 20,
        rankId: 'disciple',
        completedTaskCount: 2,
      ),
      player: repository.createInitialState().player.copyWith(
        maxInnerPower: 60,
        innerPower: 60,
        potential: 10,
      ),
    );
    final controller = GameController(
      repository: repository,
      initialState: readyState,
    );

    controller.dispatch(
      const GameAction.learnFromNpc('liu_chunfeng', 'fonxan_sword'),
    );
    expect(controller.state.learnedSkillIds, isNot(contains('fonxan_sword')));
    expect(controller.state.log.last, contains('入室弟子'));

    controller.dispatch(
      const GameAction.requestFamilyPromotion('liu_chunfeng'),
    );
    controller.dispatch(
      const GameAction.learnFromNpc('liu_chunfeng', 'fonxan_sword'),
    );

    expect(controller.state.apprenticeship?.rankId, 'inner_disciple');
    expect(controller.state.learnedSkillIds, contains('fonxan_sword'));
    expect(controller.state.apprenticeship?.contribution, 19);
  });

  test(
    'family teachers can teach same-family disciples without being master',
    () {
      final controller = GameController(repository: repository);
      _moveStateTo(controller, 'chunfeng_training_ground');

      controller.dispatch(
        const GameAction.learnFromNpc('li_huoshi', 'liuh_ken'),
      );
      expect(controller.state.learnedSkillIds, isNot(contains('liuh_ken')));
      expect(controller.state.log.last, contains('同门弟子'));

      controller.replaceState(
        controller.state.copyWith(
          apprenticeship: const ApprenticeshipState(
            familyId: 'fengshan_sword',
            masterNpcId: 'liu_chunfeng',
            generation: 14,
            title: '弟子',
            contribution: 0,
            rankId: 'disciple',
          ),
          skillProgress: const {
            'literate': SkillProgress(level: 10, experience: 0),
            'basic_unarmed': SkillProgress(level: 1, experience: 0),
          },
        ),
      );
      controller.dispatch(
        const GameAction.learnFromNpc('li_huoshi', 'liuh_ken'),
      );

      expect(controller.state.learnedSkillIds, contains('liuh_ken'));
    },
  );

  test('inner Fengshan rooms unlock after inner disciple promotion', () {
    final controller = GameController(
      repository: repository,
      initialState: repository.createInitialState().copyWith(
        currentRoomId: 'chunfeng_schoolhall',
        apprenticeship: const ApprenticeshipState(
          familyId: 'fengshan_sword',
          masterNpcId: 'liu_chunfeng',
          generation: 14,
          title: '弟子',
          contribution: 0,
          rankId: 'disciple',
        ),
      ),
    );

    var exits = repository
        .room('chunfeng_schoolhall')
        .availableExits(controller.state);
    expect(exits[Direction.east], isNull);

    controller.replaceState(
      controller.state.copyWith(
        apprenticeship: const ApprenticeshipState(
          familyId: 'fengshan_sword',
          masterNpcId: 'liu_chunfeng',
          generation: 14,
          title: '入室弟子',
          contribution: 20,
          rankId: 'inner_disciple',
          completedTaskCount: 2,
        ),
      ),
    );
    exits = repository
        .room('chunfeng_schoolhall')
        .availableExits(controller.state);
    expect(exits[Direction.east], 'chunfeng_inner_yard');

    controller.dispatch(const GameAction.move(Direction.east));
    expect(controller.state.currentRoomId, 'chunfeng_inner_yard');
  });

  test('family talk task completes after visiting target npc', () {
    final controller = GameController(
      repository: repository,
      initialState: _fengshanDiscipleState(repository),
    );

    controller.dispatch(
      const GameAction.acceptFamilyTask('liu_chunfeng', 'fengshan_gate_rules'),
    );
    expect(controller.activeFamilyTask()?.type, FamilyTaskType.talkToNpc);

    _moveStateTo(controller, 'chunfeng_school_gate');
    controller.dispatch(const GameAction.talk('liu_anlu'));

    expect(
      controller.state.apprenticeship?.activeTask?.isObjectiveComplete,
      isTrue,
    );

    _moveStateTo(controller, 'chunfeng_schoolhall');
    controller.dispatch(const GameAction.turnInFamilyTask('liu_chunfeng'));
    expect(controller.state.apprenticeship?.contribution, 13);
  });

  test('family patrol task tracks each visited room', () {
    final controller = GameController(
      repository: repository,
      initialState: _fengshanInnerDiscipleState(repository),
    );

    controller.dispatch(
      const GameAction.acceptFamilyTask(
        'liu_chunfeng',
        'fengshan_inner_patrol',
      ),
    );
    expect(controller.activeFamilyTask()?.type, FamilyTaskType.patrolRooms);

    controller.dispatch(const GameAction.move(Direction.east));
    expect(
      controller.state.apprenticeship?.activeTask?.completedTargetIds,
      contains('chunfeng_inner_yard'),
    );
    expect(
      controller.state.apprenticeship?.activeTask?.isObjectiveComplete,
      isFalse,
    );

    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.move(Direction.east));

    final progress = controller.state.apprenticeship?.activeTask;
    expect(progress?.isObjectiveComplete, isTrue);
    expect(progress?.completedTargetIds, contains('chunfeng_study'));
    expect(progress?.completedTargetIds, contains('chunfeng_guest_room'));
    expect(progress?.completedTargetIds, contains('chunfeng_inner_hall'));
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

GameState _fengshanDiscipleState(GameDefinitionRepository repository) {
  return repository.createInitialState().copyWith(
    currentRoomId: 'chunfeng_schoolhall',
    questStatuses: const {'fengshan_first_trial': QuestStatus.completed},
    apprenticeship: const ApprenticeshipState(
      familyId: 'fengshan_sword',
      masterNpcId: 'liu_chunfeng',
      generation: 14,
      title: '弟子',
      contribution: 10,
      rankId: 'disciple',
    ),
  );
}

GameState _fengshanInnerDiscipleState(GameDefinitionRepository repository) {
  return _fengshanDiscipleState(repository).copyWith(
    skillProgress: const {
      'literate': SkillProgress(level: 10, experience: 0),
      'basic_sword': SkillProgress(level: 5, experience: 0),
      'fonxan_force': SkillProgress(level: 3, experience: 0),
    },
    apprenticeship: const ApprenticeshipState(
      familyId: 'fengshan_sword',
      masterNpcId: 'liu_chunfeng',
      generation: 14,
      title: '入室弟子',
      contribution: 20,
      rankId: 'inner_disciple',
      completedTaskCount: 2,
    ),
  );
}
