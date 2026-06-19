import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import '../models/npc_definition.dart';
import '../models/quest_definition.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import '../systems/combat_system.dart';
import '../systems/inventory_system.dart';
import '../systems/movement_system.dart';
import '../systems/progression_system.dart';
import '../systems/quest_system.dart';
import '../systems/world_system.dart';
import 'game_action.dart';

class GameController extends ChangeNotifier {
  GameController({
    required GameDefinitionRepository repository,
    GameState? initialState,
  }) : _repository = repository,
       _state =
           initialState == null
               ? repository.createInitialState()
               : repository.hydrateState(initialState) {
    final progressionSystem = ProgressionSystem(repository);
    _movementSystem = MovementSystem(repository);
    _inventorySystem = InventorySystem(repository);
    _questSystem = QuestSystem(repository, progressionSystem);
    _combatSystem = CombatSystem(repository, progressionSystem);
    _worldSystem = WorldSystem(repository);
  }

  final GameDefinitionRepository _repository;
  late final MovementSystem _movementSystem;
  late final InventorySystem _inventorySystem;
  late final QuestSystem _questSystem;
  late final CombatSystem _combatSystem;
  late final WorldSystem _worldSystem;
  GameState _state;

  GameDefinitionRepository get repository => _repository;

  GameState get state => _state;

  void replaceState(GameState state) {
    _state = state;
    notifyListeners();
  }

  void reset() {
    _state = _repository.createInitialState();
    notifyListeners();
  }

  void dispatch(GameAction action) {
    _state = switch (action) {
      MoveAction(:final direction) => _worldSystem.advanceAfterTravel(
        _state,
        _movementSystem.move(_state, direction),
      ),
      LookAction() => _movementSystem.look(_state),
      PerformRoomAction(:final actionId) => _worldSystem.advanceAfterTravel(
        _state,
        _movementSystem.performRoomAction(_state, actionId),
      ),
      TalkAction(:final npcId) => _questSystem.talk(_state, npcId),
      SelectDialogueAction(:final npcId, :final optionId) => _questSystem
          .selectDialogue(_state, npcId, optionId),
      PickUpAction(:final itemId) => _inventorySystem.pickUp(_state, itemId),
      EquipItemAction(:final itemId) => _inventorySystem.equipItem(
        _state,
        itemId,
      ),
      StudyItemAction(:final itemId) => _inventorySystem.studyItem(
        _state,
        itemId,
      ),
      UseItemAction(:final itemId) => _inventorySystem.useItem(_state, itemId),
      DropItemAction(:final itemId) => _inventorySystem.dropItem(
        _state,
        itemId,
      ),
      StartCombatAction(:final npcId) => _combatSystem.startCombat(
        _state,
        npcId,
      ),
      AttackAction() => _combatSystem.attack(_state),
      FleeCombatAction() => _combatSystem.fleeCombat(_state),
    };
    notifyListeners();
  }

  List<QuestView> questViews() {
    return _questSystem.questViews(_state);
  }

  List<DialogueOption> dialogueOptionsFor(String npcId) {
    return _questSystem.dialogueOptionsFor(_state, npcId);
  }

  List<SkillDefinition> learnedSkills() {
    return _inventorySystem.learnedSkills(_state);
  }

  void completeQuestLegacy(String questId) {
    _state = _questSystem.completeQuestLegacy(_state, questId);
    notifyListeners();
  }
}
