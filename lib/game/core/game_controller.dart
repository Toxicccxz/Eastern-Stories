import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import '../models/npc_definition.dart';
import '../models/quest_definition.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import '../systems/combat_system.dart';
import '../systems/equipment_system.dart';
import '../systems/inventory_system.dart';
import '../systems/movement_system.dart';
import '../systems/progression_system.dart';
import '../systems/quest_system.dart';
import '../systems/skill_progression_system.dart';
import '../systems/skill_mapping_system.dart';
import '../systems/trade_system.dart';
import '../systems/world_system.dart';
import '../systems/cultivation_system.dart';
import '../systems/apprenticeship_system.dart';
import '../systems/inner_power_system.dart';
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
    _equipmentSystem = EquipmentSystem(repository);
    _skillMappingSystem = SkillMappingSystem(repository);
    final skillProgressionSystem = SkillProgressionSystem(
      repository,
      _skillMappingSystem,
    );
    _cultivationSystem = CultivationSystem(
      repository,
      skillProgressionSystem,
      _skillMappingSystem,
    );
    _innerPowerSystem = InnerPowerSystem(
      repository,
      _equipmentSystem,
      _skillMappingSystem,
      skillProgressionSystem,
    );
    _apprenticeshipSystem = ApprenticeshipSystem(repository);
    final progressionSystem = ProgressionSystem(repository, _equipmentSystem);
    _movementSystem = MovementSystem(repository);
    _inventorySystem = InventorySystem(
      repository,
      _equipmentSystem,
      _cultivationSystem,
    );
    _questSystem = QuestSystem(repository, progressionSystem);
    _combatSystem = CombatSystem(
      repository,
      progressionSystem,
      _equipmentSystem,
      skillProgressionSystem,
      _skillMappingSystem,
    );
    _worldSystem = WorldSystem(repository);
    _tradeSystem = TradeSystem(repository, _equipmentSystem);
  }

  final GameDefinitionRepository _repository;
  late final MovementSystem _movementSystem;
  late final EquipmentSystem _equipmentSystem;
  late final InventorySystem _inventorySystem;
  late final QuestSystem _questSystem;
  late final CombatSystem _combatSystem;
  late final WorldSystem _worldSystem;
  late final TradeSystem _tradeSystem;
  late final SkillMappingSystem _skillMappingSystem;
  late final CultivationSystem _cultivationSystem;
  late final ApprenticeshipSystem _apprenticeshipSystem;
  late final InnerPowerSystem _innerPowerSystem;
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
      GiveItemAction(:final npcId, :final itemId) => _questSystem.giveItem(
        _state,
        npcId,
        itemId,
      ),
      PickUpAction(:final itemId) => _inventorySystem.pickUp(_state, itemId),
      EquipItemAction(:final itemId) => _equipmentSystem.equipItem(
        _state,
        itemId,
      ),
      UnequipItemAction(:final slot) => _equipmentSystem.unequipItem(
        _state,
        slot,
      ),
      StudyItemAction(:final itemId) => _inventorySystem.studyItem(
        _state,
        itemId,
      ),
      LearnFromNpcAction(:final npcId, :final skillId) => _cultivationSystem
          .learnFromNpc(_state, npcId, skillId),
      PracticeSkillAction(:final usage) => _cultivationSystem.practice(
        _state,
        usage,
      ),
      ApprenticeToAction(:final npcId) => _apprenticeshipSystem.apprenticeTo(
        _state,
        npcId,
      ),
      LeaveFamilyAction() => _apprenticeshipSystem.leaveFamily(_state),
      UseItemAction(:final itemId) => _inventorySystem.useItem(_state, itemId),
      DropItemAction(:final itemId) => _inventorySystem.dropItem(
        _state,
        itemId,
      ),
      BuyItemAction(:final npcId, :final itemId) => _tradeSystem.buyItem(
        _state,
        npcId,
        itemId,
      ),
      SellItemAction(:final npcId, :final itemId) => _tradeSystem.sellItem(
        _state,
        npcId,
        itemId,
      ),
      StartCombatAction(:final npcId) => _combatSystem.startCombat(
        _state,
        npcId,
      ),
      AttackAction() => _combatSystem.attack(_state),
      EnableSkillAction(:final skillId, :final usage) => _skillMappingSystem
          .enable(_state, skillId, usage),
      DisableSkillAction(:final usage) => _skillMappingSystem.disable(
        _state,
        usage,
      ),
      UseCombatMoveAction(:final skillId, :final moveId) => _combatSystem
          .useMove(_state, skillId, moveId),
      FleeCombatAction() => _combatSystem.fleeCombat(_state),
      MeditateAction() => _innerPowerSystem.meditate(_state),
      RecoverWithInnerPowerAction() => _innerPowerSystem.recover(_state),
      HealWithInnerPowerAction() => _innerPowerSystem.heal(_state),
    };
    notifyListeners();
  }

  List<QuestView> questViews() {
    return _questSystem.questViews(_state);
  }

  List<DialogueOption> dialogueOptionsFor(String npcId) {
    return _questSystem.dialogueOptionsFor(_state, npcId);
  }

  List<GiveItemOption> giveItemOptionsFor(String npcId) {
    return _questSystem.giveItemOptionsFor(_state, npcId);
  }

  List<TeachingSkillDefinition> teachingSkillsFor(String npcId) {
    return _repository.npc(npcId).teachingSkills;
  }

  List<SkillDefinition> learnedSkills() {
    return _inventorySystem.learnedSkills(_state);
  }

  List<CombatMoveOption> activeCombatMoves() {
    return [
      for (final skill in learnedSkills())
        if (skill.isBasic || _state.enabledSkillIds.containsValue(skill.id))
          for (final move in skill.moves)
            CombatMoveOption(skill: skill, move: move),
    ];
  }

  CharacterStats characterStats() {
    return _equipmentSystem.statsFor(_state);
  }

  int innerPowerCultivationLimit() {
    return _innerPowerSystem.cultivationLimit(_state);
  }

  void completeQuestLegacy(String questId) {
    _state = _questSystem.completeQuestLegacy(_state, questId);
    notifyListeners();
  }
}
