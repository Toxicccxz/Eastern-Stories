import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/direction.dart';
import 'package:eastern_stories/game/models/equipment_slot.dart';
import 'package:eastern_stories/game/models/innate_attributes.dart';
import 'package:eastern_stories/game/models/skill_progress.dart';
import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:eastern_stories/game/systems/skill_mapping_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDefinitionRepository repository;

  setUpAll(() async {
    repository = await GameDefinitionRepository.loadDemo();
  });

  test('equipping and removing body armor updates derived defense', () {
    final controller = _controllerAtLiuHome(repository);

    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.pickUp('plain_cloth'));
    controller.dispatch(const GameAction.equipItem('plain_cloth'));

    expect(controller.state.equippedItemIds[EquipmentSlot.body], 'plain_cloth');
    expect(controller.characterStats().defense, 3);
    expect(controller.characterStats().defenseBonus, 1);

    controller.dispatch(const GameAction.unequipItem(EquipmentSlot.body));

    expect(
      controller.state.equippedItemIds,
      isNot(contains(EquipmentSlot.body)),
    );
    expect(controller.characterStats().defense, 2);
  });

  test('dropping equipped armor clears its equipment slot', () {
    final controller = _controllerAtLiuHome(repository);

    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.pickUp('plain_cloth'));
    controller.dispatch(const GameAction.equipItem('plain_cloth'));
    controller.dispatch(const GameAction.dropItem('plain_cloth'));

    expect(
      controller.state.equippedItemIds,
      isNot(contains(EquipmentSlot.body)),
    );
    expect(controller.state.inventoryItemIds, isNot(contains('plain_cloth')));
    expect(
      repository.room('small_storage').visibleItemIds(controller.state),
      contains('plain_cloth'),
    );
  });

  test('selling equipped armor clears its slot and derived bonus', () {
    final controller = _controllerAtLiuHome(repository);

    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.pickUp('plain_cloth'));
    controller.dispatch(const GameAction.equipItem('plain_cloth'));
    controller.dispatch(const GameAction.move(Direction.south));
    controller.dispatch(const GameAction.move(Direction.east));
    controller.dispatch(const GameAction.move(Direction.north));
    controller.dispatch(const GameAction.sellItem('meloner', 'plain_cloth'));

    expect(
      controller.state.equippedItemIds,
      isNot(contains(EquipmentSlot.body)),
    );
    expect(controller.characterStats().defense, 2);
    expect(controller.state.player.silver, 21);
  });

  test('Juechen equipment applies original attribute and skill modifiers', () {
    final initialState = repository.createInitialState().copyWith(
      inventoryItemIds: const ['green_jingang_staff', 'green_purple_gold_hat'],
      skillProgress: const {
        'spells': SkillProgress(level: 10, experience: 0),
        'basic_dodge': SkillProgress(level: 10, experience: 0),
      },
    );
    final controller = GameController(
      repository: repository,
      initialState: initialState,
    );

    controller.dispatch(const GameAction.equipItem('green_jingang_staff'));
    controller.dispatch(const GameAction.equipItem('green_purple_gold_hat'));

    expect(
      controller.characterStats().attributeBonusFor(
        InnateAttribute.intelligence,
      ),
      3,
    );
    final mapping = SkillMappingSystem(repository);
    expect(mapping.skillLevel(controller.state, 'spells'), 25);
    expect(mapping.skillLevel(controller.state, 'basic_dodge'), 5);
  });
}

GameController _controllerAtLiuHome(GameDefinitionRepository repository) {
  final initialState = repository.createInitialState();
  return GameController(
    repository: repository,
    initialState: initialState.copyWith(
      currentRoomId: 'liu_home',
      visitedRoomIds: {...initialState.visitedRoomIds, 'liu_home'},
      player: initialState.player.copyWith(silver: 20),
      inventoryItemIds: const [],
      equippedItemIds: const {},
    ),
  );
}
